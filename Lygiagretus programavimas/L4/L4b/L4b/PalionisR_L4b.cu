/*
* Rokas Palionis IFF-5/8 L4b
*
*/

#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <thrust\host_vector.h>
#include <thrust\device_vector.h>

using namespace std;

//Masyvo element� dydis
const unsigned int array_size = 30;

//Skaitymo failas
string readFileName = "PalionisR_L4b.dat.txt";
//Spausdinimo failas
string writeFileName = "PalionisR_L4b.rez.txt";

//Bendra strukt�ra P
struct ThreadStruct {
	char name[20 * 5] = { 0 };
	int wins;
	double points;
};

/*
* Nuskaito duomenis i� duomen� failo � masyvus.
*
* @param P - ThreadStruct tipo masyvas
* @param thread_identifier - P masyvo element� identifikatorius
* @param readStream - skaitymo srautas
* @param elements_amount - element� kiekvienoje grup�je skai�ius
* @return - void
*/
void ReadData(ThreadStruct P[array_size], int & p_amount, ifstream & readStream, int elements_amount);
/*
* I�veda duomenis i� masyv� � rezultat� fail�.
*
* @param P - ThreadStruct tipo masyvas
* @param thread_identifier - P masyvo element� identifikatorius
* @param writeStream - spausdinimo srautas
* @return - void
*/
void WriteData(ThreadStruct P[array_size], int p_amount, ofstream & writeStream, int element);
/*
* I�veda duomenis i� bendro gij� masyvo � rezultat� fail�.
*
* @param P - ThreadStruct tipo masyvas
* @param thread_identifier - P masyvo element� identifikatorius
* @param writeStream - spausdinimo srautas
* @return - void
*/
void WriteThreads(ThreadStruct P[], int p_amount, ofstream & writeStream);

void CopyArrayToVector(thrust::host_vector<ThreadStruct> CPU_P, ThreadStruct P[]);
void CopyVectorToArray(ThreadStruct P[], thrust::host_vector<ThreadStruct> CPU_P, int p_amount);

void ExecuteThrust(ThreadStruct P1[], int p1_amount, ThreadStruct P2[], int p2_amount, ThreadStruct P3[], int p3_amount, ThreadStruct P4[], int p4_amount, ThreadStruct P5[], int p5_amount, ThreadStruct P[], int p_amount);

void CopyArrayToTypeString(string P_STRING[], ThreadStruct P[]);
void CopyArrayToTypeInt(int P_INT[], ThreadStruct P[]);
void CopyArrayToTypeDouble(double P_DOUBLE[], ThreadStruct P[]);

void ExecuteStringAdd(string P_STRING[], ThreadStruct P1[], ThreadStruct P2[], ThreadStruct P3[], ThreadStruct P4[], ThreadStruct P5[]);
void ExecuteIntAdd(int P_INT[], ThreadStruct P1[], ThreadStruct P2[], ThreadStruct P3[], ThreadStruct P4[], ThreadStruct P5[]);
void ExecuteDoubleAdd(double P_DOUBLE[], ThreadStruct P1[], ThreadStruct P2[], ThreadStruct P3[], ThreadStruct P4[], ThreadStruct P5[]);

void CopyTypeDataToArray(string P_STRING[], int P_INT[], double P_DOUBLE[], ThreadStruct P[]);

int main() {

	//Nustato lokalizacij�, kad tinkamai b�t� nuskaitomi lietuvi�ki ra�menys
	setlocale(LC_ALL, "");

	//Sukuriami masyvai
	ThreadStruct P1[array_size];
	ThreadStruct P2[array_size];
	ThreadStruct P3[array_size];
	ThreadStruct P4[array_size];
	ThreadStruct P5[array_size];
	//Sukuriami masyv� kiekio identifikatoriai
	int p1_amount = 0;
	int p2_amount = 0;
	int p3_amount = 0;
	int p4_amount = 0;
	int p5_amount = 0;

	//Bendras masyvas sudarytas i� strukt�ros ThreadStruct ir reik�m�m sud�ti papildomas masyvo identifikatorius
	ThreadStruct P[array_size];
	int p_amount = 0;

	//Skaitomi duomenys � masyvus
	ifstream readStream(readFileName);
	//Element� kiekvienoje sekcijoje skai�ius
	int elements_amount;
	readStream >> skipws >> elements_amount;
	ReadData(P1, p1_amount, readStream, elements_amount);
	ReadData(P2, p2_amount, readStream, elements_amount);
	ReadData(P3, p3_amount, readStream, elements_amount);
	ReadData(P4, p4_amount, readStream, elements_amount);
	ReadData(P5, p5_amount, readStream, elements_amount);
	readStream.close();

	//P bendro masyvo element� kiekis lygus kiekvienos grup�s element� skai�iui
	p_amount = elements_amount;

	//Vykdomos thrust funkcijos
	ExecuteThrust(P1, p1_amount, P2, p2_amount, P3, p3_amount, P4, p4_amount, P5, p5_amount, P, p_amount);

	//Spausdinami pradiniai duomenys
	ofstream writeStream(writeFileName);
	WriteData(P1, p1_amount, writeStream, 1);
	WriteData(P2, p2_amount, writeStream, 2);
	WriteData(P3, p3_amount, writeStream, 3);
	WriteData(P4, p4_amount, writeStream, 4);
	WriteData(P5, p5_amount, writeStream, 5);
	writeStream.close();

	//Spausdinamas bendras masyvas
	writeStream.open(writeFileName, fstream::app);
	WriteThreads(P, p_amount, writeStream);
	writeStream.close();

	cout << "Programa baig� darb�!" << endl;

    return 0;
}



void ReadData(ThreadStruct P[array_size], int & p_amount, ifstream & readStream, int elements_amount) {

	if (elements_amount > 0) {
		//Kol yra tinkamai �vest� objekt� ir nepasiekia limito (array_element_limit), juos �ra�o � masyv�
		for (int i = 0; readStream.good() && i < array_size && i < elements_amount; i++) {
			readStream >> P[i].name >> P[i].wins >> P[i].points;
			p_amount++;
		}
	}

	return;
}

void WriteData(ThreadStruct P[array_size], int p_amount, ofstream & writeStream, int element) {

	//I�vedamos stulpeli� antra�t�s
	writeStream << element << " ---------------------------------\n";
	writeStream << setw(3) << "Nr." << " " << setw(14) << left << "Pavard�" << " " << setw(7) << "Pergal�s" << " " << setw(5) << "Ta�kai" << endl;

	//Kol yra tinkamai �vest� objekt� ir nepasiekia limito (array_limit), juos �ra�o � fail� pagal stulpelius
	for (int i = 0; P[i].name != "" && P[i].wins >= 0 && P[i].points >= 0 && i < p_amount; i++) {
		writeStream << setw(2) << right << i + 1 << ") " << setw(20) << left << P[i].name << " " << setw(2) << right << P[i].wins << "  " << setw(5) << right << fixed << setprecision(2) << P[i].points << endl;
	}

	//I�vedama papildoma tu��ia eilut�
	writeStream << endl;

	return;
}

void WriteThreads(ThreadStruct P[], int p_amount, ofstream & writeStream) {

	//I�vedamos stulpeli� antra�t�s
	writeStream << " ----------------------------------\n";
	writeStream << setw(3) << "Nr." << " " << setw(60) << left << "Pavard�" << " " << setw(7) << "Pergal�s" << " " << setw(5) << "Ta�kai" << endl;

	//Kol yra tinkamai �vest� objekt� ir nepasiekia limito (array_limit), juos �ra�o � fail� pagal stulpelius
	for (int i = 0; P[i].name != "" && P[i].wins >= 0 && P[i].points >= 0 && i < p_amount; i++) {
		writeStream << setw(2) << right << i + 1 << ") " << setw(60+6) << left << P[i].name << " " << setw(2) << right << P[i].wins << "  " << setw(5) << right << fixed << setprecision(2) << P[i].points << endl;
	}

	//I�vedama papildoma tu��ia eilut�
	writeStream << endl;

	return;
}

void ExecuteThrust(ThreadStruct P1[], int p1_amount, ThreadStruct P2[], int p2_amount, ThreadStruct P3[], int p3_amount, ThreadStruct P4[], int p4_amount, ThreadStruct P5[], int p5_amount, ThreadStruct P[], int p_amount) {

	//Sukuriamas masyvas kiekvienam duomen� tipui atskirai
	string P_STRING[array_size];
	int P_INT[array_size] = { 0 };
	double P_DOUBLE[array_size] = { 0 };

	//Vykdomos sud�jimo funkcijos
	ExecuteStringAdd(P_STRING, P1, P2, P3, P4, P5);
	ExecuteIntAdd(P_INT, P1, P2, P3, P4, P5);
	ExecuteDoubleAdd(P_DOUBLE, P1, P2, P3, P4, P5);

	//Kopijuojamos reik�m�s i� tip� masyv� � bendr� strukt�r� P
	CopyTypeDataToArray(P_STRING, P_INT, P_DOUBLE, P);

}

void CopyArrayToTypeString(string P_STRING[], ThreadStruct P[]) {

	for (int i = 0; i < array_size; i++) {
		P_STRING[i] = P[i].name;
	}

}

void CopyArrayToTypeInt(int P_INT[], ThreadStruct P[]) {

	for (int i = 0; i < array_size; i++) {
		P_INT[i] = P[i].wins;
	}

}

void CopyArrayToTypeDouble(double P_DOUBLE[], ThreadStruct P[]) {

	for (int i = 0; i < array_size; i++) {
		P_DOUBLE[i] = P[i].points;
	}

}

void ExecuteStringAdd(string P_STRING[], ThreadStruct P1[], ThreadStruct P2[], ThreadStruct P3[], ThreadStruct P4[], ThreadStruct P5[]) {

	string P1_STRING[array_size];
	string P2_STRING[array_size];
	string P3_STRING[array_size];
	string P4_STRING[array_size];
	string P5_STRING[array_size];

	CopyArrayToTypeString(P1_STRING, P1);
	CopyArrayToTypeString(P2_STRING, P2);
	CopyArrayToTypeString(P3_STRING, P3);
	CopyArrayToTypeString(P4_STRING, P4);
	CopyArrayToTypeString(P5_STRING, P5);

	thrust::plus<string> operationToExecute;
	thrust::transform(P_STRING, P_STRING + array_size, P1_STRING, P_STRING, operationToExecute);
	thrust::transform(P_STRING, P_STRING + array_size, P2_STRING, P_STRING, operationToExecute);
	thrust::transform(P_STRING, P_STRING + array_size, P3_STRING, P_STRING, operationToExecute);
	thrust::transform(P_STRING, P_STRING + array_size, P4_STRING, P_STRING, operationToExecute);
	thrust::transform(P_STRING, P_STRING + array_size, P5_STRING, P_STRING, operationToExecute);

	//for (int i = 0; i < array_size; i++) {
	//	cout << P_STRING[i] << endl;
	//}

}

void ExecuteIntAdd(int P_INT[], ThreadStruct P1[], ThreadStruct P2[], ThreadStruct P3[], ThreadStruct P4[], ThreadStruct P5[]) {

	int P1_INT[array_size] = { 0 };
	int P2_INT[array_size] = { 0 };
	int P3_INT[array_size] = { 0 };
	int P4_INT[array_size] = { 0 };
	int P5_INT[array_size] = { 0 };

	CopyArrayToTypeInt(P1_INT, P1);
	CopyArrayToTypeInt(P2_INT, P2);
	CopyArrayToTypeInt(P3_INT, P3);
	CopyArrayToTypeInt(P4_INT, P4);
	CopyArrayToTypeInt(P5_INT, P5);

	thrust::plus<int> operationToExecute;
	thrust::transform(P_INT, P_INT + array_size, P1_INT, P_INT, operationToExecute);
	thrust::transform(P_INT, P_INT + array_size, P2_INT, P_INT, operationToExecute);
	thrust::transform(P_INT, P_INT + array_size, P3_INT, P_INT, operationToExecute);
	thrust::transform(P_INT, P_INT + array_size, P4_INT, P_INT, operationToExecute);
	thrust::transform(P_INT, P_INT + array_size, P5_INT, P_INT, operationToExecute);

}

void ExecuteDoubleAdd(double P_DOUBLE[], ThreadStruct P1[], ThreadStruct P2[], ThreadStruct P3[], ThreadStruct P4[], ThreadStruct P5[]) {

	double P1_DOUBLE[array_size] = { 0 };
	double P2_DOUBLE[array_size] = { 0 };
	double P3_DOUBLE[array_size] = { 0 };
	double P4_DOUBLE[array_size] = { 0 };
	double P5_DOUBLE[array_size] = { 0 };

	CopyArrayToTypeDouble(P1_DOUBLE, P1);
	CopyArrayToTypeDouble(P2_DOUBLE, P2);
	CopyArrayToTypeDouble(P3_DOUBLE, P3);
	CopyArrayToTypeDouble(P4_DOUBLE, P4);
	CopyArrayToTypeDouble(P5_DOUBLE, P5);

	thrust::plus<double> operationToExecute;
	thrust::transform(P_DOUBLE, P_DOUBLE + array_size, P1_DOUBLE, P_DOUBLE, operationToExecute);
	thrust::transform(P_DOUBLE, P_DOUBLE + array_size, P2_DOUBLE, P_DOUBLE, operationToExecute);
	thrust::transform(P_DOUBLE, P_DOUBLE + array_size, P3_DOUBLE, P_DOUBLE, operationToExecute);
	thrust::transform(P_DOUBLE, P_DOUBLE + array_size, P4_DOUBLE, P_DOUBLE, operationToExecute);
	thrust::transform(P_DOUBLE, P_DOUBLE + array_size, P5_DOUBLE, P_DOUBLE, operationToExecute);

}

void CopyTypeDataToArray(string P_STRING[], int P_INT[], double P_DOUBLE[], ThreadStruct P[]) {

	for (int i = 0; i < array_size; i++) {
		for(int j = 0; j < P_STRING[i].length(); j++)
			P[i].name[j] = P_STRING[i][j];
		P[i].wins = P_INT[i];
		P[i].points = P_DOUBLE[i];
	}

}

void CopyArrayToVector(thrust::host_vector<ThreadStruct> CPU_P, ThreadStruct P[]) {

	//Kopijuoja i� masyvo � vektori� visas reik�mes
	for (int i = 0; i < CPU_P.size(); i++) {
		//my_strcat(CPU_P[i].name, P[i].name);
		CPU_P[i].wins = P[i].wins;
		CPU_P[i].points = P[i].points;
	}

	//for (int i = 0; i < CPU_P.size(); i++) {
	//	cout << CPU_P[i].name << endl;
	//	cout << CPU_P[i].wins << endl;
	//	cout << CPU_P[i].points << endl;
	//}

}

void CopyVectorToArray(ThreadStruct P[], thrust::host_vector<ThreadStruct> CPU_P, int p_amount) {

	//Kopijuoja i� masyvo � vektori� visas reik�mes
	for (int i = 0; i < p_amount; i++) {
		//my_strcat(P[i].name, CPU_P[i].name);
		P[i].wins = CPU_P[i].wins;
		P[i].points = CPU_P[i].points;
	}

	//for (int i = 0; i < p_amount; i++) {
	//	cout << P[i].name << endl;
	//	cout << P[i].wins << endl;
	//	cout << P[i].points << endl;
	//}

}