/*
* Rokas Palionis IFF-5/8, L2a
*
*/

#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include <thread>
#include <mutex>
#include <iterator>

using namespace std;

static const unsigned int thread_amount = 10;
static const unsigned int array_limit = 10;
static const unsigned int array_element_limit = 3;

mutex mu;
mutex isFull;

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
	bool RemoveElement(VStruct V);
	void GetResults(VStruct B[], int *b_element_identifier);
};

void ThreadsMonitor::AddElement(PStruct P) {
	// add sync
	lock_guard<mutex> guard(mu);

	unique_lock<mutex> locker(isFull);
	int index = -1;

	//searchin spot for insertion
	for (int i = 0; i <= binner_element_identifier; i++)
		if (P.name == BInner[i].sorting_field)
			index = i;
	if (index > -1) {
		BInner[index].amount++;
	}
	else {
		if (binner_element_identifier < array_limit) {
			index = 0; // back to default (array)

			//insertion index
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

	return;
}

bool ThreadsMonitor::RemoveElement(VStruct V) {

	//initiating thread sync
	lock_guard<mutex> guard(mu);

	for (int i = 0; i <= binner_element_identifier; i++) {
		if (V.sorting_field == BInner[i].sorting_field) {

			if (BInner[i].amount - V.amount > 0) {
				BInner[i].amount -= V.amount;
			}
			else if (BInner[i].amount - V.amount == 0) {

				for (int j = i; j <= binner_element_identifier - 1; j++) {
					BInner[j].sorting_field = BInner[j + 1].sorting_field;
					BInner[j].amount = BInner[j + 1].amount;
				}
				binner_element_identifier--;
			}
			else {
				
				return true;
			}
			return false;
		}
	}
	return true;
}


void ThreadsMonitor::GetResults(VStruct B[], int *b_element_identifier) {

	//Kopijuojami Monitoriaus bendras masyvas á iðoriná masyvà
	for (int i = 0; i < array_limit; i++) {
		B[i].sorting_field = BInner[i].sorting_field;
		B[i].amount = BInner[i].amount;
	}
	//Kopijuojama Monitoriaus bendro masyvo B indeksas
	*b_element_identifier = binner_element_identifier;

	return;
}

void ReadData(PStruct P[], VStruct V[], int & p_amount, int & v_amount, ifstream & readStream);
void WriteData(PStruct P[], VStruct V[], int & p_amount, int & v_amount, ofstream & writeStream, int element);
void ExecuteFirstThreadFunction(PStruct P[], int p_amount, ThreadsMonitor *monitor, int thread_identifier);
void ExecuteSecondThreadFunction(VStruct V[], int v_amount, ThreadsMonitor *monitor, int thread_identifier);
void WriteThreads(VStruct B[], int b_element_identifier);


int main() {

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

	VStruct B[array_limit];
	int b_element_identifier = 0;

	//Paðalina visus duomenis
	string filename = "PalionisRokas_L2a.dat_1.txt";
	//Nepaðalina jokiø duomenø
	string filename = "PalionisRokas_L2a.dat_2.txt";
	//Paðalina dalá duomenø
	string filename = "PalionisRokas_L2a.dat_3.txt";

	//read data
	ifstream readStream(filename);
	ReadData(P1, V1, p1_amount, v1_amount, readStream);
	ReadData(P2, V2, p2_amount, v2_amount, readStream);
	ReadData(P3, V3, p3_amount, v3_amount, readStream);
	ReadData(P4, V4, p4_amount, v4_amount, readStream);
	ReadData(P5, V5, p5_amount, v5_amount, readStream);
	readStream.close();

	//write data to file
	ofstream writeStream("PalionisRokas_L2a.rez.txt");
	WriteData(P1, V1, p1_amount, v1_amount, writeStream, 1);
	WriteData(P2, V2, p2_amount, v2_amount, writeStream, 2);
	WriteData(P3, V3, p3_amount, v3_amount, writeStream, 3);
	WriteData(P4, V4, p3_amount, v4_amount, writeStream, 4);
	WriteData(P5, V5, p3_amount, v5_amount, writeStream, 5);
	writeStream.close();

	ThreadsMonitor monitor;

	thread threadP1(ExecuteFirstThreadFunction, P1, p1_amount, &monitor, 1);
	thread threadP2(ExecuteFirstThreadFunction, P2, p2_amount, &monitor, 2);
	thread threadP3(ExecuteFirstThreadFunction, P3, p3_amount, &monitor, 3);
	thread threadP4(ExecuteFirstThreadFunction, P4, p4_amount, &monitor, 4);
	thread threadP5(ExecuteFirstThreadFunction, P5, p5_amount, &monitor, 5);
	thread threadV1(ExecuteSecondThreadFunction, V1, v1_amount, &monitor, 11);
	thread threadV2(ExecuteSecondThreadFunction, V2, v2_amount, &monitor, 12);
	thread threadV3(ExecuteSecondThreadFunction, V3, v3_amount, &monitor, 13);
	thread threadV4(ExecuteSecondThreadFunction, V4, v4_amount, &monitor, 14);
	thread threadV5(ExecuteSecondThreadFunction, V5, v5_amount, &monitor, 15);
	threadP1.join();
	threadP2.join();
	threadP3.join();
	threadP4.join();
	threadP5.join();
	threadV1.join();
	threadV2.join();
	threadV3.join();
	threadV4.join();
	threadV5.join();

	//get data from Monitor
	monitor.GetResults(B, &b_element_identifier);
	WriteThreads(B, b_element_identifier);

	cout << "Program exits!" << endl;

	return 0;
}

void ReadData(PStruct P[], VStruct V[], int & p_amount, int & v_amount, ifstream & readStream) {

	int elements_amount; // amount of element in section

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
	writeStream << setw(3) << "Nr." << " " << setw(14) << left << "Surname" << " " << setw(7) << "Wins" << " " << setw(5) << "Points" << endl;

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
	
	cout << "\tLaunched from the first thread with id: " << thread_identifier << endl;

	for (int i = 0; i < p_amount; i++) {
		(*monitor).AddElement(P[i]);
	}

	return;
}

void ExecuteSecondThreadFunction(VStruct V[], int v_amount, ThreadsMonitor *monitor, int thread_identifier) {

	cout << "\tLaunched from the second thread with id: " << thread_identifier << endl;

	for (int i = 0; i < v_amount; i++) {
		bool notDeleted = true;
		while (notDeleted) {
			notDeleted = (*monitor).RemoveElement(V[i]);
		}
	}

	return;
}

void WriteThreads(VStruct B[], int b_element_identifier) {

	ofstream writeStream("PalionisRokas_L2a.rez.txt", fstream::app);
	writeStream << setw(3) << "Nr." << " " << setw(14) << left << "Rikiavimo_laukas" << " " << setw(7) << "Kiekis" << endl;

	for (int i = 0; B[i].sorting_field != "" && B[i].amount >= 0 && i < b_element_identifier; i++) {
		writeStream << setw(2) << right << i + 1 << ") " << setw(20) << left << B[i].sorting_field << " " << setw(2) << right << B[i].amount << endl;
	}

	writeStream.close();

	return;
}