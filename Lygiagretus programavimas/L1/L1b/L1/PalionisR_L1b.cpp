/*
* Rokas Palionis IFF-5/8
*
* 1. Kokia tvarka startuoja procesai? Galimi atsakymo variantai: tokia, kokia uzrasyti, atsitiktine, atvirkscia.
* 		Atsakymas: atsitiktine.
* 2. Kokia tvarka vykdomi procesai? Galimi atsakymo variantai: tokia, kokia startuoja, atsitiktine, atvirkscia.
* 		Atsakymas: atsitiktine.
* 3. Kiek iteraciju is eilës padaro vienas procesas? Galimi atsakymo variantai: vienos dali, viena pilnai, visas,
* atsitiktini skaiciu.
* 		Atsakymas: atsitiktini skaiciu.
* 4. Kokia tvarka to paties duomenø masyvo elementai surasomi i rezultato masyva? Galimi atsakymo variantai:
* tokia, kokia surasyti duomenu masyve, atsitiktine, atvirkscia.
* 		Atsakymas: atsitiktine.
*
*/

#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include <omp.h>

using namespace std;

//Giju skaicius
int thread_amount = 0;

//Bendra struktura P
struct ThreadStruct {
	int thread_number;
	string name;
	int wins;
	double points;
};


void ReadData(string S[], int I[], double D[]);

void WriteData(string S[], int I[], double D[]);

// Vykdo gijas
void ExecuteThreads(string S[], int I[], double D[], ThreadStruct P[], int & thread_identifier);

void WriteThreads(ThreadStruct P[], int thread_identifier);

int main() {

	setlocale(LC_ALL, "");

	//Duomenu masyvai: S - string, I - int, D - double
	string S[20];
	int I[20];
	double D[20];

	//Bendras masyvas sudarytas ið struktûros ThreadStruct ir reikðmëm sudëti papildomas masyvo identifikatorius
	ThreadStruct P[20];
	int thread_identifier = 0;

	//Vykdomos funkcijos: nuskaityti duomenis á masyvus, tada tuos duomenis iðvesti á duomenø failà
	ReadData(S, I, D);
	WriteData(S, I, D);

	//Vykdomos funkcijos: vykdyti gijas, tada jø veiksmø rezultatà iðspausdinti á failà
	ExecuteThreads(S, I, D, P, thread_identifier);
	WriteThreads(P, thread_identifier);

	cout << "Programa baige darba!" << endl;

	return 0;
}

void ReadData(string S[], int I[], double D[]) {

	ifstream  readStream("ZakareviciusM_L1b.dat.txt");

	//Kol yra tinkamai ávestø objektø ir nepasiekia limito (20), juos áraðo á masyvà
	for (int i = 0; !readStream.eof() && i < 20; i++) {
		readStream >> S[i] >> I[i] >> D[i];
		thread_amount++;
	}

	readStream.close();

	return;
}

void WriteData(string S[], int I[], double D[]) {

	ofstream writeStream("ZakareviciusM_L1b.rez.txt");

	//Iðvedamos stulpeliø antraðtës
	writeStream << setw(3) << "Nr." << " " << setw(14) << left << "Pavardë" << " " << setw(7) << "Pergalës" << " " << setw(5) << "Taðkai" << endl;

	//Kol yra tinkamai ávestø objektø ir nepasiekia limito (20), juos áraðo á failà pagal stulpelius
	for (int i = 0; S[i] != "" && I[i] >= 0 && D[i] >= 0 && i < 20; i++) {
		writeStream << setw(2) << right << i + 1 << ") " << setw(20) << left << S[i] << " " << setw(2) << right << I[i] << "  " << setw(5) << right << fixed << setprecision(2) << D[i] << endl;
	}

	//Iðvedama papildoma tuðèia eilutë
	writeStream << endl;

	writeStream.close();

	return;
}

void ExecuteThreads(string S[], int I[], double D[], ThreadStruct P[], int & thread_identifier) {

	//Gijos identifikacinis numeris
	int thread_number = 0;

	omp_set_num_threads(thread_amount);

	int thread_internal_identifier = thread_identifier;

	//Lygiagretus kodas
	#pragma omp parallel private(thread_number, thread_internal_identifier)
	{
		thread_internal_identifier = thread_identifier++;

		thread_number = omp_get_thread_num();

		P[thread_internal_identifier].thread_number = thread_number;
		P[thread_internal_identifier].name = S[thread_number];
		P[thread_internal_identifier].wins = I[thread_number];
		P[thread_internal_identifier].points = D[thread_number];
	}

	return;
}

void WriteThreads(ThreadStruct P[], int thread_identifier) {

	ofstream writeStream("ZakareviciusM_L1b.rez.txt", fstream::app);

	writeStream << setw(3) << "Nr." << " " << setw(4) << "Gija" << " " << setw(14) << left << "Pavardë" << " " << setw(7) << "Pergalës" << " " << setw(5) << "Taðkai" << endl;

	
	for (int i = 0; P[i].thread_number >= 0 && P[i].name != "" && P[i].wins >= 0 && P[i].points >= 0 && i < thread_identifier; i++) {
		writeStream << setw(2) << right << i + 1 << ")   " << setw(2) << right << P[i].thread_number << " " << setw(20) << left << P[i].name << " " << setw(2) << right << P[i].wins << "  " << setw(5) << right << fixed << setprecision(2) << P[i].points << endl;
	}

	writeStream.close();

	return;
}