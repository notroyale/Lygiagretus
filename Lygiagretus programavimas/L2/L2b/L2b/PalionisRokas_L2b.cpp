/*
* Rokas Palionis IFF-5/8
*
*/

#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include <omp.h>

using namespace std;

static const unsigned int thread_amount = 10;
static const unsigned int array_limit = 10;
static const unsigned int array_element_limit = 5;

int elements_that_filled_array = 0;

struct PStruct {
	string name;
	int wins;
	double points;
};

struct VStruct {
	string sorting_field;
	int amount;
};

class ThreadsMonitor {

private:
	VStruct BInner[array_limit];
	int binner_element_identifier = 0;
	
public:
	ThreadsMonitor() { ; }

	void AddElement(PStruct P);
	void RemoveElement(VStruct V);
	void GetResults(VStruct B[], int *b_element_identifier);
};

// pagal gijos indexa pridedam i B masyva
void ThreadsMonitor::AddElement(PStruct P) {

	#pragma omp critical
	{
		int index = -1; // masyvo vietos indexas
		for (int i = 0; i <= binner_element_identifier; i++)
			if (P.name == BInner[i].sorting_field)
				index = i;

		if (index > -1) {
			BInner[index].amount++;
		}
		else {
			if (binner_element_identifier < array_limit) {
				index = 0;

				for (int i = 0; i <= binner_element_identifier; i++) {
					if (P.name > BInner[i].sorting_field) {
						index = i;
					}
					else {
						index = i;
						break;
					}
				}

				for (int i = binner_element_identifier; i >= index; i--) {
					BInner[i + 1].sorting_field = BInner[i].sorting_field;
					BInner[i + 1].amount = BInner[i].amount;
				}
				BInner[index].sorting_field = P.name;
				BInner[index].amount = 1;
				binner_element_identifier++;
			}
		}

		cout << "\t\tAddElement thread added: " << P.name << "!" << endl;
	}

}
//identifies thread and removes it
void ThreadsMonitor::RemoveElement(VStruct V) {

	#pragma omp critical
	{
		bool elementFound = false;

		for (int i = 0; i <= binner_element_identifier; i++) {
			
			if (V.sorting_field == BInner[i].sorting_field) {
				cout << "\t\tRemoveElement thread found: " << V.sorting_field << "!" << endl;

				if (BInner[i].amount - V.amount > 0) {
					BInner[i].amount -= V.amount;

					elementFound = true;

					cout << "\t\tRemoveElement thread modiffied: " << V.sorting_field << "!" << endl;

					break;
				}
				else {
					//push elements
					for (int j = i; j <= binner_element_identifier - 1; j++) {
						BInner[j].sorting_field = BInner[j + 1].sorting_field;
						BInner[j].amount = BInner[j + 1].amount;
					}
					binner_element_identifier--;

					elementFound = true;

					cout << "\t\tRemoveElement thread removed: " << V.sorting_field << "!" << endl;

					break;
				}
			}
		}

		if (!elementFound) {
			//if not found, search again
			cout << "\t\tRemoveElement thread didn't find: " << V.sorting_field << "!" << endl;
		}
	}

}

void ThreadsMonitor::GetResults(VStruct B[], int *b_element_identifier) {
	
	for (int i = 0; i < array_limit; i++) {
		B[i].sorting_field = BInner[i].sorting_field;
		B[i].amount = BInner[i].amount;
	}
	
	*b_element_identifier = binner_element_identifier;

}

void ReadData(PStruct P[], VStruct V[], int & p_amount, int & v_amount, ifstream & readStream);
void WriteData(PStruct P[], VStruct V[], int & p_amount, int & v_amount, ofstream & writeStream, int element);
void ExecuteFirstThreadFunction(PStruct P[], int p_amount, ThreadsMonitor *monitor, int thread_identifier);
void ExecuteSecondThreadFunction(VStruct V[], int v_amount, ThreadsMonitor *monitor, int thread_identifier);
void WriteThreads(VStruct B[], int b_element_identifier);

int main() {

	setlocale(LC_ALL, "");

	PStruct P1[array_element_limit];
	PStruct P2[array_element_limit];
	PStruct P3[array_element_limit];
	PStruct P4[array_element_limit];
	PStruct P5[array_element_limit];
	int p1_amount = 0;
	int p2_amount = 0;
	int p3_amount = 0;
	int p4_amount = 0;
	int p5_amount = 0;

	VStruct V1[array_element_limit];
	VStruct V2[array_element_limit];
	VStruct V3[array_element_limit];
	VStruct V4[array_element_limit];
	VStruct V5[array_element_limit];
	int v1_amount = 0;
	int v2_amount = 0;
	int v3_amount = 0;
	int v4_amount = 0;
	int v5_amount = 0;

	
	int b_element_identifier = 0;

	
	string filename = "ZakareviciusM_L2b.dat_3.txt";

	ifstream readStream(filename);
	ReadData(P1, V1, p1_amount, v1_amount, readStream);
	ReadData(P2, V2, p2_amount, v2_amount, readStream);
	ReadData(P3, V3, p3_amount, v3_amount, readStream);
	ReadData(P4, V4, p4_amount, v4_amount, readStream);
	ReadData(P5, V5, p5_amount, v5_amount, readStream);
	readStream.close();

	ofstream writeStream("ZakareviciusM_L2b.rez.txt");
	WriteData(P1, V1, p1_amount, v1_amount, writeStream, 1);
	WriteData(P2, V2, p2_amount, v2_amount, writeStream, 2);
	WriteData(P3, V3, p3_amount, v3_amount, writeStream, 3);
	WriteData(P4, V4, p3_amount, v4_amount, writeStream, 4);
	WriteData(P5, V5, p3_amount, v5_amount, writeStream, 5);
	writeStream.close();

	ThreadsMonitor monitor;
	int thread_identifier = 0;

	int p_amount = p1_amount + p2_amount + p3_amount + p4_amount + p5_amount;
	int v_amount = v1_amount + v2_amount + v3_amount + v4_amount + v5_amount;

	omp_set_num_threads(p_amount + v_amount);

	#pragma omp parallel shared(monitor, elements_that_filled_array) private(thread_identifier)
	{
		thread_identifier = omp_get_thread_num();

		switch (thread_identifier) {
			case 0: 
				ExecuteFirstThreadFunction(P1, p1_amount, &monitor, 1);
				break;
			case 1:
				ExecuteFirstThreadFunction(P2, p2_amount, &monitor, 2);
				break;
			case 2:
				ExecuteFirstThreadFunction(P3, p3_amount, &monitor, 3);
				break;
			case 3:
				ExecuteFirstThreadFunction(P4, p4_amount, &monitor, 4);
				break;
			case 4:
				ExecuteFirstThreadFunction(P5, p5_amount, &monitor, 5);
				break;
			case 5:
				ExecuteSecondThreadFunction(V1, v1_amount, &monitor, 11);
				break;
			case 6:
				ExecuteSecondThreadFunction(V2, v2_amount, &monitor, 12);
				break;
			case 7:
				ExecuteSecondThreadFunction(V3, v3_amount, &monitor, 13);
				break;
			case 8:
				ExecuteSecondThreadFunction(V4, v4_amount, &monitor, 14);
				break;
			case 9:
				ExecuteSecondThreadFunction(V5, v5_amount, &monitor, 15);
				break;
		}
	}

	monitor.GetResults(B, &b_element_identifier);
	WriteThreads(B, b_element_identifier);

	cout << "\nPrograma baigë darbà!" << endl;

	return 0;
}

void ReadData(PStruct P[], VStruct V[], int & p_amount, int & v_amount, ifstream & readStream) {

	//in sections
	int elements_amount;

	// writing to array until reaches its limit

	readStream >> skipws >> elements_amount;
	if (elements_amount > 0) {
		for (int i = 0; readStream.good() && i < array_element_limit && i < elements_amount; i++) {
			readStream >> P[i].name >> P[i].wins >> P[i].points;
			p_amount++;
		}
	}

	readStream >> skipws >> elements_amount;
	if (elements_amount > 0) {
		for (int i = 0; readStream.good() && i < array_element_limit && i < elements_amount; i++) {
			readStream >> V[i].sorting_field >> V[i].amount;
			v_amount++;
		}
	}

	return;
}

void WriteData(PStruct P[], VStruct V[], int & p_amount, int & v_amount, ofstream & writeStream, int element) {

	writeStream << element << " ---------------------------------\n";
	writeStream << setw(3) << "Nr." << " " << setw(14) << left << "Pavardë" << " " << setw(7) << "Pergalës" << " " << setw(5) << "Taðkai" << endl;

	for (int i = 0; P[i].name != "" && P[i].wins >= 0 && P[i].points >= 0 && i < p_amount; i++) {
		writeStream << setw(2) << right << i + 1 << ") " << setw(20) << left << P[i].name << " " << setw(2) << right << P[i].wins << "  " << setw(5) << right << fixed << setprecision(2) << P[i].points << endl;
	}

	writeStream << endl;
	writeStream << setw(3) << "Nr." << " " << setw(14) << left << "Rikiavimo_laukas" << " " << setw(7) << "Kiekis" << endl;

	for (int i = 0; V[i].sorting_field != "" && V[i].amount >= 0 && i < v_amount; i++) {
		writeStream << setw(2) << right << i + 1 << ") " << setw(20) << left << V[i].sorting_field << " " << setw(2) << right << V[i].amount << endl;
	}

	writeStream << element << " ---------------------------------\n";
	writeStream << endl;

	return;
}

void ExecuteFirstThreadFunction(PStruct P[], int p_amount, ThreadsMonitor *monitor, int thread_identifier) {
	
	#pragma omp critical
	{
		cout << "AddElement thread with id: " << thread_identifier << " has succesfully started!" << endl;
	}

		//writing every element until the end
		for (int i = 0; i < p_amount; i++) {
			//inserting element
			(*monitor).AddElement(P[i]);
		}

		elements_that_filled_array++;

	#pragma omp critical
	{
		cout << "\AddElement thread with id: " << thread_identifier << " has succesfully finished!" << endl;
	}

}

void ExecuteSecondThreadFunction(VStruct V[], int v_amount, ThreadsMonitor *monitor, int thread_identifier) {

	#pragma omp critical
	{
		cout << "\tRemoveElement thread with id: " << thread_identifier << " has succesfully started!" << endl;
	}

	//if not removed, tries to remove again
	while (elements_that_filled_array < 5) {
		for (int i = 0; i < v_amount; i++) {
			(*monitor).RemoveElement(V[i]);
		}
	}

	#pragma omp critical
	{
		cout << "\tRemoveElement thread with id: " << thread_identifier << " has succesfully finished!" << endl;
	}

}

void WriteThreads(VStruct B[], int b_element_identifier) {

	ofstream writeStream("ZakareviciusM_L2b.rez.txt", fstream::app);
	writeStream << setw(3) << "Nr." << " " << setw(14) << left << "Rikiavimo_laukas" << " " << setw(7) << "Kiekis" << endl;

	for (int i = 0; B[i].sorting_field != "" && B[i].amount >= 0 && i < b_element_identifier; i++) {
		writeStream << setw(2) << right << i + 1 << ") " << setw(20) << left << B[i].sorting_field << " " << setw(2) << right << B[i].amount << endl;
	}

	writeStream.close();

	return;
}