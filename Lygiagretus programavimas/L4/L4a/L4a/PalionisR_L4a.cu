/*
* Mantvydas Zakarevi�ius IFF-4/2 L4a
*
*/

#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

using namespace std;

//Masyvo element� dydis
const unsigned int array_size = 30;
//Gij� skai�ius
int thread_amount = 12;

//Skaitymo failas
string readFileName = "ZakareviciusM_L4a.dat.txt";
//Spausdinimo failas
string writeFileName = "ZakareviciusM_L4a.rez.txt";

//Bendra strukt�ra P
struct ThreadStruct {
	//int thread_number;
	char name[20 * 5];
	int wins;
	double points;
};

/*
* Nuskaito duomenis i� duomen� failo � masyvus.
*
* @param P - ThreadStruct tipo masyvas
* @param thread_identifier - P masyvo element� identifikatorius
* @param readStream - skaitymo srautas
* @return - void
*/
void ReadData(ThreadStruct P[array_size], int & p_amount, ifstream & readStream);
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
/*
* Vykdomas element� paruo�imas darbui su CUDA. Taip pat �ia paleid�iama pati CUDA.
*
* @param P1 - ThreadStruct tipo masyvas
* @param p1_amount - P1 masyvo element� identifikatorius
* @param P2 - ThreadStruct tipo masyvas
* @param p2_amount - P2 masyvo element� identifikatorius
* @param P3 - ThreadStruct tipo masyvas
* @param p3_amount - P3 masyvo element� identifikatorius
* @param P4 - ThreadStruct tipo masyvas
* @param p4_amount - P4 masyvo element� identifikatorius
* @param P5 - ThreadStruct tipo masyvas
* @param p5_amount - P5 masyvo element� identifikatorius
* @param P - ThreadStruct tipo masyvas
* @param p_amount - P masyvo element� identifikatorius
* @return - cudaError_t
*/
cudaError_t writeWithCuda(ThreadStruct P1[], int p1_amount, ThreadStruct P2[], int p2_amount, ThreadStruct P3[], int p3_amount, ThreadStruct P4[], int p4_amount, ThreadStruct P5[], int p5_amount, ThreadStruct P[], int *p_amount);
/*
* Vykdo CUDA funkcij�, kuri kiekvienai skirtingai gijai paskiria skirting� veiksm�.
*
* @param P1 - ThreadStruct tipo masyvas
* @param p1_amount - P1 masyvo element� identifikatorius
* @param P2 - ThreadStruct tipo masyvas
* @param p2_amount - P2 masyvo element� identifikatorius
* @param P3 - ThreadStruct tipo masyvas
* @param p3_amount - P3 masyvo element� identifikatorius
* @param P4 - ThreadStruct tipo masyvas
* @param p4_amount - P4 masyvo element� identifikatorius
* @param P5 - ThreadStruct tipo masyvas
* @param p5_amount - P5 masyvo element� identifikatorius
* @param P - ThreadStruct tipo masyvas
* @param p_amount - P masyvo element� identifikatorius
* @return - void
*/
__global__ void writeKernel(ThreadStruct P1[], int p1_amount, ThreadStruct P2[], int p2_amount, ThreadStruct P3[], int p3_amount, ThreadStruct P4[], int p4_amount, ThreadStruct P5[], int p5_amount, ThreadStruct P[], int *p_amount);
/*
* Kiekviena gija �ra�o savo elementus � bendr� masyv� P.
*
* @param P1 - ThreadStruct tipo masyvas
* @param p1_amount - P1 masyvo element� identifikatorius
* @param P2 - ThreadStruct tipo masyvas
* @param p2_amount - P2 masyvo element� identifikatorius
* @param P3 - ThreadStruct tipo masyvas
* @param p3_amount - P3 masyvo element� identifikatorius
* @param P4 - ThreadStruct tipo masyvas
* @param p4_amount - P4 masyvo element� identifikatorius
* @param P5 - ThreadStruct tipo masyvas
* @param p5_amount - P5 masyvo element� identifikatorius
* @param P - ThreadStruct tipo masyvas
* @param p_amount - P masyvo element� identifikatorius
* @param thread_number - vykdomos gijos identifikatorius
* @return - void
*/
__device__ void writeDevice(ThreadStruct P1[], int p1_amount, ThreadStruct P2[], int p2_amount, ThreadStruct P3[], int p3_amount, ThreadStruct P4[], int p4_amount, ThreadStruct P5[], int p5_amount, ThreadStruct P[], int *p_amount, int thread_number);
/*
* strcpy funkcija veikianti ant CUDA gij� (C kalbos).
*
* @param dest - � kur� char masyv� kopijuojama 
* @param src - i� kurio char masyvo kopijuojama 
* @return - char*
*/
__device__ char * my_strcpy(char *dest, const char *src);
/*
* strcat funkcija veikianti ant CUDA gij� (C kalbos).
*
* @param dest - � kur� char masyv� kopijuojama
* @param src - i� kurio char masyvo kopijuojama
* @return - char*
*/
__device__ char * my_strcat(char *dest, const char *src);

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
	ReadData(P1, p1_amount, readStream);
	ReadData(P2, p2_amount, readStream);
	ReadData(P3, p3_amount, readStream);
	ReadData(P4, p4_amount, readStream);
	ReadData(P5, p5_amount, readStream);
	readStream.close();

	//Paleid�iama CUDA (vykdomos gijos)
	cudaError_t cudaStatus = writeWithCuda(P1, p1_amount, P2, p2_amount, P3, p3_amount, P4, p4_amount, P5, p5_amount, P, &p_amount);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "writeWithCuda failed!");
		return 1;
	}
	// cudaDeviceReset must be called before exiting in order for profiling and
	// tracing tools such as Nsight and Visual Profiler to show complete traces.
	cudaStatus = cudaDeviceReset();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceReset failed!");
		return 1;
	}

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



void ReadData(ThreadStruct P[array_size], int & p_amount, ifstream & readStream) {

	//Element� kiekvienoje sekcijoje skai�ius
	int elements_amount;

	readStream >> skipws >> elements_amount;
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

cudaError_t writeWithCuda(ThreadStruct P1[], int p1_amount, ThreadStruct P2[], int p2_amount, ThreadStruct P3[], int p3_amount, ThreadStruct P4[], int p4_amount, ThreadStruct P5[], int p5_amount, ThreadStruct P[], int *p_amount) {

	ThreadStruct *dev_P1;
	ThreadStruct *dev_P2;
	ThreadStruct *dev_P3;
	ThreadStruct *dev_P4;
	ThreadStruct *dev_P5;
	ThreadStruct *dev_P;

	int *dev_p1_amount = 0;
	int *dev_p2_amount = 0;
	int *dev_p3_amount = 0;
	int *dev_p4_amount = 0;
	int *dev_p5_amount = 0;
	int *dev_p_amount = 0;

	cudaError_t cudaStatus;

	// Choose which GPU to run on, change this on a multi-GPU system.
	cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
		goto Error;
	}

	// Allocate GPU buffers for four arrays (three input, one output).
	cudaStatus = cudaMalloc((void**)&dev_P1, array_size * sizeof(ThreadStruct));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_P2, array_size * sizeof(ThreadStruct));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_P3, array_size * sizeof(ThreadStruct));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_P4, array_size * sizeof(ThreadStruct));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_P5, array_size * sizeof(ThreadStruct));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_P, array_size * sizeof(ThreadStruct));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	// Allocate GPU buffers for arrays identifiers
	cudaStatus = cudaMalloc((void**)&dev_p1_amount, sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_p2_amount, sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_p3_amount, sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_p4_amount, sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_p5_amount, sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_p_amount, sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	// Copy input vectors from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(dev_P1, P1, array_size * sizeof(ThreadStruct), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpy(dev_P2, P2, array_size * sizeof(ThreadStruct), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpy(dev_P3, P3, array_size * sizeof(ThreadStruct), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpy(dev_P4, P4, array_size * sizeof(ThreadStruct), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpy(dev_P5, P5, array_size * sizeof(ThreadStruct), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	// Assigns arrays amounts to CUDA memory variables
	*dev_p1_amount = p1_amount;
	*dev_p2_amount = p2_amount;
	*dev_p3_amount = p3_amount;
	*dev_p4_amount = p4_amount;
	*dev_p5_amount = p5_amount;

	// Launch a kernel on the GPU with one thread for each element.
	writeKernel<<<1, thread_amount>>>(dev_P1, *dev_p1_amount, dev_P2, *dev_p2_amount, dev_P3, *dev_p3_amount, dev_P4, *dev_p4_amount, dev_P5, *dev_p5_amount, dev_P, dev_p_amount);

	// Check for any errors launching the kernel
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "writeernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
		goto Error;
	}

	// cudaDeviceSynchronize waits for the kernel to finish, and returns
	// any errors encountered during the launch.
	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
		goto Error;
	}

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(P, dev_P, array_size * sizeof(ThreadStruct), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(p_amount, dev_p_amount, sizeof(int), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

Error:
	cudaFree(dev_P);
	cudaFree(dev_P1);
	cudaFree(dev_P2);
	cudaFree(dev_P3);
	cudaFree(dev_P4);
	cudaFree(dev_P5);
	cudaFree(dev_p_amount);
	cudaFree(dev_p1_amount);
	cudaFree(dev_p2_amount);
	cudaFree(dev_p3_amount);
	cudaFree(dev_p4_amount);
	cudaFree(dev_p5_amount);

	return cudaStatus;
}

__global__ void writeKernel(ThreadStruct P1[], int p1_amount, ThreadStruct P2[], int p2_amount, ThreadStruct P3[], int p3_amount, ThreadStruct P4[], int p4_amount, ThreadStruct P5[], int p5_amount, ThreadStruct P[], int *p_amount) {

	//CUDA gijos numeris
	int thread_number = threadIdx.x;

	//Padidina element� kiek�
	atomicAdd(p_amount, 1);

	//Kiekviena gija �ra�in�ja savo duomenis
	writeDevice(P1, p1_amount, P2, p2_amount, P3, p3_amount, P4, p4_amount, P5, p5_amount, P, p_amount, thread_number);

	return;
}

__device__ void writeDevice(ThreadStruct P1[], int p1_amount, ThreadStruct P2[], int p2_amount, ThreadStruct P3[], int p3_amount, ThreadStruct P4[], int p4_amount, ThreadStruct P5[], int p5_amount, ThreadStruct P[], int *p_amount, int thread_number) {

	//printf("Thread id: %d!\n", thread_number);

	//�ra�omi duomenys � bendr� masyv�
	my_strcat(P[thread_number].name, P1[thread_number].name);
	my_strcat(P[thread_number].name, P2[thread_number].name);
	my_strcat(P[thread_number].name, P3[thread_number].name);
	my_strcat(P[thread_number].name, P4[thread_number].name);
	my_strcat(P[thread_number].name, P5[thread_number].name);
	P[thread_number].wins += P1[thread_number].wins + P2[thread_number].wins + P3[thread_number].wins + P4[thread_number].wins + P5[thread_number].wins;
	P[thread_number].points += P1[thread_number].points + P2[thread_number].points + P3[thread_number].points + P4[thread_number].points + P5[thread_number].points;

	return;
}

__device__ char * my_strcpy(char *dest, const char *src) {
	int i = 0;
	do {
		dest[i] = src[i];
	} while (src[i++] != 0);
	return dest;
}

__device__ char * my_strcat(char *dest, const char *src) {
	int i = 0;
	while (dest[i] != 0) i++;
	my_strcpy(dest + i, src);
	return dest;
}