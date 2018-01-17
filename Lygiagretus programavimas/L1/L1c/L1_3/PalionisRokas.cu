/*
* Rokas Palionis IFF-5/8
*
* 1. Kokia tvarka startuoja procesai? Galimi atsakymo variantai: tokia, kokia u�ra�yti, atsitiktine, atvirk��ia.
* 		Atsakymas: atsitiktine.
* 2. Kokia tvarka vykdomi procesai? Galimi atsakymo variantai: tokia, kokia startuoja, atsitiktine, atvirk��ia.
* 		Atsakymas: atsitiktine.
* 3. Kiek iteracij� i� eil�s padaro vienas procesas? Galimi atsakymo variantai: vienos dal�, vien� pilnai, visas,
* atsitiktin� skai�i�.
* 		Atsakymas: visas.
* 4. Kokia tvarka to paties duomen� masyvo elementai sura�omi � rezultat� masyv�? Galimi atsakymo variantai:
* tokia, kokia sura�yti duomen� masyve, atsitiktine, atvirk��ia.
* 		Atsakymas: atsitiktine.
* 5. Kurioje programoje trumpiausias vienos gijos kodas?
*		Atsakymas: C++ & OpenMP
* 6. Kokiu kompiuteriu vykd�te savo programas? Nurodykite branduoli� skai�i� ir da�nius, OA apimt�, OS, NVIDIA plok�t�s tip�.*		Atsakymas: i5-7300HQ 4 (8 HT) 2.6Ghz (3.6Ghz Turbo Boost), 8GB DDR3, Windows 10 Education 64-Bit, GTX 1050 2GB GDDR5.
*/

#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

using namespace std;

//Masyvo element� dydis
const unsigned int array_size = 20;
//Gij� skai�ius
int thread_amount = 0;

//Bendra strukt�ra P
struct ThreadStruct {
	int thread_number;
	char name[20];
	int wins;
	double points;
};

/*
* Nuskaito duomenis i� duomen� failo � masyvus.
*
* @param S - char tipo masyvas
* @param I - int tipo masyvas
* @param D - double tipo masyvas
*/
void ReadData(char S[array_size][array_size], int I[], double D[]);
/*
* I�veda duomenis i� masyv� � rezultat� fail�.
*
* @param S - char tipo masyvas
* @param I - int tipo masyvas
* @param D - double tipo masyvas
*/
void WriteData(char S[array_size][array_size], int I[], double D[]);
/*
* I�veda duomenis i� bendro gij� masyvo � rezultat� fail�.
*
* @param P - ThreadStruct tipo masyvas
* @param thread_identifier - P masyvo element� identifikatorius
* @return - void
*/
void WriteThreads(ThreadStruct P[], int thread_identifier);
/*
* Vykdomas element� paruo�imas darbui su CUDA. Taip pat �ia paleid�iama pati CUDA.
*
* @param S - char tipo masyvas
* @param I - int tipo masyvas
* @param D - double tipo masyvas
* @param P - ThreadStruct tipo masyvas
* @param thread_identifier - P masyvo element� identifikatorius
* @return - cudaError_t
*/
cudaError_t writeWithCuda(char S[array_size][array_size], int I[], double D[], ThreadStruct P[], int *thread_identifier);
/*
* Vykdo CUDA funkcij�, kuri kiekvienai skirtingai gijai paskiria skirting� veiksm�.
*
* @param S - char tipo masyvas
* @param I - int tipo masyvas
* @param D - double tipo masyvas
* @param P - ThreadStruct tipo masyvas
* @param dev_id - P masyvo element� identifikatorius
* @return - void
*/
__global__ void writeKernel(char S[array_size * array_size], int I[], double D[], ThreadStruct P[], int *dev_id);
/*
* Kiekviena gija �ra�o savo elementus � bendr� masyv� P.
*
* @param S - char tipo masyvas
* @param I - int tipo masyvas
* @param D - double tipo masyvas
* @param P - ThreadStruct tipo masyvas
* @param dev_id - P masyvo element� identifikatorius
* @param thread_number - vykdomos gijos identifikatorius
* @return - void
*/
__device__ void writeDevice(char S[array_size * array_size], int I[], double D[], ThreadStruct P[], int element_id, int thread_number);

int main() {

	//Nustato lokalizacij�, kad tinkamai b�t� nuskaitomi lietuvi�ki ra�menys
	setlocale(LC_ALL, "");

	//Duomen� masyvai: S - string, I - int, D - double
	char S[array_size][array_size];
	int I[array_size];
	double D[array_size];

	//Bendras masyvas sudarytas i� strukt�ros ThreadStruct ir reik�m�m sud�ti papildomas masyvo identifikatorius
	ThreadStruct P[array_size];
	int thread_identifier = 0;

	//Vykdomos funkcijos: nuskaityti duomenis � masyvus, tada tuos duomenis i�vesti � duomen� fail�
	ReadData(S, I, D);
	WriteData(S, I, D);

	//Paleid�iama CUDA
	cudaError_t cudaStatus = writeWithCuda(S, I, D, P, &thread_identifier);
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

	//�ra�omi bendro masyvo duomenys (po CUDA vykdymo) � rezultat� fail�
	//WriteThreads(P, thread_identifier);
	WriteThreads(P, thread_identifier);

	cout << "Programa baig� darb�!" << endl;

    return 0;
}



void ReadData(char S[array_size][array_size], int I[], double D[]) {

	ifstream  readStream("PalionisRokas_L1c.dat.txt");

	//Kol yra tinkamai �vest� objekt� ir nepasiekia limito (20), juos �ra�o � masyv�
	for (int i = 0; !readStream.eof() && i < array_size; i++) {
		readStream >> S[i] >> I[i] >> D[i];
		thread_amount++;
	}

	readStream.close();

	return;
}

void WriteData(char S[array_size][array_size], int I[], double D[]) {

	ofstream writeStream("PalionisRokas_L1c.rez.txt");

	//I�vedamos stulpeli� antra�t�s
	writeStream << setw(3) << "Nr." << " " << setw(14) << left << "Pavard�" << " " << setw(7) << "Pergal�s" << " " << setw(5) << "Ta�kai" << endl;

	//Kol yra tinkamai �vest� objekt� ir nepasiekia limito (20), juos �ra�o � fail� pagal stulpelius
	for (int i = 0; S[i] != "" && I[i] >= 0 && D[i] >= 0 && i < array_size; i++) {
		writeStream << setw(2) << right << i + 1 << ") " << setw(array_size) << left << S[i] << " " << setw(2) << right << I[i] << "  " << setw(5) << right << fixed << setprecision(2) << D[i] << endl;
	}

	//I�vedama papildoma tu��ia eilut�
	writeStream << endl;

	writeStream.close();

	return;
}

void WriteThreads(ThreadStruct P[], int thread_identifier) {

	ofstream writeStream("PalionisRokas_L1c.rez.txt", fstream::app);

	//I�vedamos stulpeli� antra�t�s
	writeStream << setw(3) << "Nr." << " " << setw(4) << "Gija" << " " << setw(14) << left << "Pavard�" << " " << setw(7) << "Pergal�s" << " " << setw(5) << "Ta�kai" << endl;

	//Kol yra tinkam� reik�mi� P masyve, juos �ra�o � fail� pagal stulpelius
	for (int i = 0; P[i].thread_number >= 0 && P[i].name != "" && P[i].wins >= 0 && P[i].points >= 0 && i < thread_identifier; i++) {
		writeStream << setw(2) << right << i + 1 << ")   " << setw(2) << right << P[i].thread_number << " " << setw(array_size) << left << P[i].name << " " << setw(2) << right << P[i].wins << "  " << setw(5) << right << fixed << setprecision(2) << P[i].points << endl;
	}

	writeStream.close();

	return;
}

cudaError_t writeWithCuda(char S[array_size][array_size], int I[], double D[], ThreadStruct P[], int *thread_identifier) {

	char *dev_a;
	int *dev_b = 0;
	double *dev_c = 0;
	ThreadStruct *dev_d;

	int *dev_id = 0;
	cudaError_t cudaStatus;

	// Choose which GPU to run on, change this on a multi-GPU system.
	cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
		goto Error;
	}

	// Allocate GPU buffers for four arrays (three input, one output).
	cudaStatus = cudaMalloc((void**)&dev_d, array_size * sizeof(ThreadStruct));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_a, array_size * array_size * sizeof(char));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_b, array_size * sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_c, array_size * sizeof(double));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	// Allocate GPU buffers for one variable (array P identifier).
	cudaStatus = cudaMalloc((void**)&dev_id, sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	// Copy input vectors from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(dev_a, S, array_size * array_size * sizeof(char), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpy(dev_b, I, array_size * sizeof(int), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpy(dev_c, D, array_size * sizeof(double), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	// Launch a kernel on the GPU with one thread for each element.
	writeKernel<<<1, thread_amount>>>(dev_a, dev_b, dev_c, dev_d, dev_id);

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
	cudaStatus = cudaMemcpy(P, dev_d, array_size * sizeof(ThreadStruct), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(thread_identifier, dev_id, sizeof(int), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

Error:
	cudaFree(dev_d);
	cudaFree(dev_a);
	cudaFree(dev_b);
	cudaFree(dev_c);
	cudaFree(dev_id);

	return cudaStatus;
}

__global__ void writeKernel(char S[array_size * array_size], int I[], double D[], ThreadStruct P[], int *dev_id) {

	//CUDA gijos numeris
	int thread_number = threadIdx.x;
	//Elemento masyve P identifikatorius
	int element_id = atomicAdd(dev_id, 1);
	//Kiekviena gija �ra�in�ja savo duomenis
	writeDevice(S, I, D, P, element_id, thread_number);

	return;
}

__device__ void writeDevice(char S[array_size * array_size], int I[], double D[], ThreadStruct P[], int element_id, int thread_number) {

	//�ra�omi duomenys � bendr� masyv�
	P[element_id].thread_number = thread_number;
	int start_identifier = thread_number * array_size;
	for (int i = 0; i < array_size; i++) {
		P[element_id].name[i] = S[start_identifier++];
	}
	P[element_id].wins = I[thread_number];
	P[element_id].points = D[thread_number];

	return;
}