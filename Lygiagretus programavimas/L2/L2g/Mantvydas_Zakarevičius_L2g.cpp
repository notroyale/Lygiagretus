/*
* Mantvydas Zakarevièius IFF-4/2, 23 kompiuteris.
*/

#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>

using namespace std;

mutex mu;
condition_variable cv;

class Monitor {

private:
	int elements[100];

	unsigned int startIndex;
	unsigned int endIndex;

	unsigned int overallChangesMade;
	unsigned int changesMade;
public:
	Monitor() { 
		for(int i = 0; i < 100; i++)
			elements[i] = 0;

		startIndex = 0;
		endIndex = 99;

		overallChangesMade = 0;
		changesMade = 0;
	}

	//MONITORIAUS METODAI
	void ChangeDataStart(int thread_id);
	void ChangeDataEnd(int thread_id);
	void ReadData();
	bool IsDataReadable();
	bool ValidChange();
};

void Monitor::ChangeDataStart(int thread_id) {

	lock_guard<mutex> lock(mu);

	elements[startIndex++] = thread_id;

	overallChangesMade++;
}

void Monitor::ChangeDataEnd(int thread_id) {

	lock_guard<mutex> lock(mu);

	elements[endIndex--] = thread_id;

	overallChangesMade++;
}

void Monitor::ReadData() {

	lock_guard<mutex> lock(mu);

	for(int i = 0; i < 100; i++)
		cout << elements[i] << " ";

	cout << endl;
}

bool Monitor::IsDataReadable() {

	if(changesMade >= 10) {
		changesMade = 0;
		return true;
	}
	else
		return false;
}

bool Monitor::ValidChange() {

	if(overallChangesMade >= 100)
		return false;
	else
		return true;
}

void ExecuteChangeFunction(Monitor *monitor, int thread_id);
void ExecuteReadFunction(Monitor *monitor, int thread_id);

int main() {

	Monitor monitor;

	thread ChangeDataT1(ExecuteChangeFunction, &monitor, 1);
	thread ChangeDataT2(ExecuteChangeFunction, &monitor, 2);

	thread ChangeDataT3(ExecuteChangeFunction, &monitor, 3);
	thread ChangeDataT4(ExecuteChangeFunction, &monitor, 4);

	thread ReadDataT5(ExecuteReadFunction, &monitor, 5);

	ChangeDataT1.join();
	ChangeDataT2.join();

	ChangeDataT3.join();
	ChangeDataT4.join();

	ReadDataT5.join();

	monitor.ReadData();

	return 0;
}

void ExecuteChangeFunction(Monitor *monitor, int thread_id) {

	cout << "Launched from the thread with id: " << thread_id << endl;

	while(true) {
		if((*monitor).ValidChange()) {
			if (thread_id < 3) {
				cout << "\tThread:" << thread_id << " adds elements to the beginning!" << endl;
				(*monitor).ChangeDataStart(thread_id);
			}
			else {
				cout << "\tThread:" << thread_id << " adds elements to the end!" << endl;
				(*monitor).ChangeDataEnd(thread_id);
			}
		}
		else {
			break;
		}
	}
}

void ExecuteReadFunction(Monitor *monitor, int thread_id) {

	//while(!(*monitor).IsDataReadable()) {
		//unique_lock<mutex> thread_lock(mu);
		//cv.wait(thread_lock, [monitor](Monitor * monitor) { (*monitor).IsDataReadable(); });

		//(*monitor).ReadData();
	//}

	/*
	while(true) {
		if((*monitor).IsDataReadable())
			(*monitor).ReadData();
		else
			break;
	}
	*/
}