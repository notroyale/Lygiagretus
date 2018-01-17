/*
* Rokas Palionis IFF-5/8
*
* 1. Kokia tvarka startuoja procesai? Galimi atsakymo variantai: tokia, kokia uþraðyti, atsitiktine, atvirkðèia.
* 		Atsakymas: atsitiktine.
* 2. Kokia tvarka vykdomi procesai? Galimi atsakymo variantai: tokia, kokia startuoja, atsitiktine, atvirkðèia.
* 		Atsakymas: atsitiktine.
* 3. Kiek iteracijø ið eilës padaro vienas procesas? Galimi atsakymo variantai: vienos dalá, vienà pilnai, visas,
* atsitiktiná skaièiø.
* 		Atsakymas: visas.
* 4. Kokia tvarka to paties duomenø masyvo elementai suraðomi á rezultatø masyvà? Galimi atsakymo variantai:
* tokia, kokia suraðyti duomenø masyve, atsitiktine, atvirkðèia.
* 		Atsakymas: atsitiktine.
* 5. Kurioje programoje trumpiausias vienos gijos kodas?
*		Atsakymas: C++ & OpenMP
* 6. Kokiu kompiuteriu vykdëte savo programas? Nurodykite branduoliø skaièiø ir daþnius, OA apimtá, OS, NVIDIA plokðtës tipà.*		Atsakymas: i5-7300HQ 4 (8 HT) 2.6Ghz (3.6Ghz Turbo Boost), 8GB DDR3, Windows 10 Education 64-Bit, GTX 1050 2GB GDDR5.
*/

#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

using namespace std;

//Masyvo elementø dydis
const unsigned int array_size = 20;
//Gijø skaièius
int thread_amount = 0;

//Bendra struktûra P
struct ThreadStruct {
	int thread_number;
	char name[20];
	int wins;
	double points;
};

/*
* Nuskaito duomenis ið duomenø failo á masyvus.
*
* @param S - char tipo masyvas
* @param I - int tipo masyvas
* @param D - double tipo masyvas
*/
void ReadData(char S[array_size][array_size], int I[], double D[]);
/*
* Iðveda duomenis ið masyvø á rezultatø failà.
*
* @param S - char tipo masyvas
* @param I - int tipo masyvas
* @param D - double tipo masyvas
*/
void WriteData(char S[array_size][array_size], int I[], double D[]);
/*
* Iðveda duomenis ið bendro gijø masyvo á rezultatø failà.
*
* @param P - ThreadStruct tipo masyvas
* @param thread_identifier - P masyvo elementø identifikatorius
* @return - void
*/
void WriteThreads(ThreadStruct P[], int thread_identifier);
/*
* Vykdomas elementø paruoðimas darbui su CUDA. Taip pat èia paleidþiama pati CUDA.
*
* @param S - char tipo masyvas
* @param I - int tipo masyvas
* @param D - double tipo masyvas
* @param P - ThreadStruct tipo masyvas
* @param thread_identifier - P masyvo elementø identifikatorius
* @return - cudaError_t
*/
cudaError_t writeWithCuda(char S[array_size][array_size], int I[], double D[], ThreadStruct P[], int *thread_identifier);
/*
* Vykdo CUDA funkcijà, kuri kiekvienai skirtingai gijai paskiria skirtingà veiksmà.
*
* @param S - char tipo masyvas
* @param I - int tipo masyvas
* @param D - double tipo masyvas
* @param P - ThreadStruct tipo masyvas
* @param dev_id - P masyvo elementø identifikatorius
* @return - void
*/
__global__ void writeKernel(char S[array_size * array_size], int I[], double D[], ThreadStruct P[], int *dev_id);
/*
* Kiekviena gija áraðo savo elementus á bendrà masyvà P.
*
* @param S - char tipo masyvas
* @param I - int tipo masyvas
* @param D - double tipo masyvas
* @param P - ThreadStruct tipo masyvas
* @param dev_id - P masyvo elementø identifikatorius
* @param thread_number - vykdomos gijos identifikatorius
* @return - void
*/
__device__ void writeDevice(char S[array_size * array_size], int I[], double D[], ThreadStruct P[], int element_id, int thread_number);

int main() {

	//Nustato lokalizacijà, kad tinkamai bûtø nuskaitomi lietuviðki raðmenys
	setlocale(LC_ALL, "");

	//Duomenø masyvai: S - string, I - int, D - double
	char S[array_size][array_size];
	int I[array_size];
	double D[array_size];

	//Bendras masyvas sudarytas ið struktûros ThreadStruct ir reikðmëm sudëti papildomas masyvo identifikatorius
	ThreadStruct P[array_size];
	int thread_identifier = 0;

	//Vykdomos funkcijos: nuskaityti duomenis á masyvus, tada tuos duomenis iðvesti á duomenø failà
	ReadData(S, I, D);
	WriteData(S, I, D);

	//Paleidþiama CUDA
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

	//Áraðomi bendro masyvo duomenys (po CUDA vykdymo) á rezultatø failà
	//WriteThreads(P, thread_identifier);
	WriteThreads(P, thread_identifier);

	cout << "Programa baigë darbà!" << endl;

    return 0;
}



void ReadData(char S[array_size][array_size], int I[], double D[]) {

	ifstream  readStream("PalionisRokas_L1c.dat.txt");

	//Kol yra tinkamai ávestø objektø ir nepasiekia limito (20), juos áraðo á masyvà
	for (int i = 0; !readStream.eof() && i < array_size; i++) {
		readStream >> S[i] >> I[i] >> D[i];
		thread_amount++;
	}

	readStream.close();

	return;
}

void WriteData(char S[array_size][array_size], int I[], double D[]) {

	ofstream writeStream("PalionisRokas_L1c.rez.txt");

	//Iðvedamos stulpeliø antraðtës
	writeStream << setw(3) << "Nr." << " " << setw(14) << left << "Pavardë" << " " << setw(7) << "Pergalës" << " " << setw(5) << "Taðkai" << endl;

	//Kol yra tinkamai ávestø objektø ir nepasiekia limito (20), juos áraðo á failà pagal stulpelius
	for (int i = 0; S[i] != "" && I[i] >= 0 && D[i] >= 0 && i < array_size; i++) {
		writeStream << setw(2) << right << i + 1 << ") " << setw(array_size) << left << S[i] << " " << setw(2) << right << I[i] << "  " << setw(5) << right << fixed << setprecision(2) << D[i] << endl;
	}

	//Iðvedama papildoma tuðèia eilutë
	writeStream << endl;

	writeStream.close();

	return;
}

void WriteThreads(ThreadStruct P[], int thread_identifier) {

	ofstream writeStream("PalionisRokas_L1c.rez.txt", fstream::app);

	//Iðvedamos stulpeliø antraðtës
	writeStream << setw(3) << "Nr." << " " << setw(4) << "Gija" << " " << setw(14) << left << "Pavardë" << " " << setw(7) << "Pergalës" << " " << setw(5) << "Taðkai" << endl;

	//Kol yra tinkamø reikðmiø P masyve, juos áraðo á failà pagal stulpelius
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
	//Kiekviena gija áraðinëja savo duomenis
	writeDevice(S, I, D, P, element_id, thread_number);

	return;
}

__device__ void writeDevice(char S[array_size * array_size], int I[], double D[], ThreadStruct P[], int element_id, int thread_number) {

	//Áraðomi duomenys á bendrà masyvà
	P[element_id].thread_number = thread_number;
	int start_identifier = thread_number * array_size;
	for (int i = 0; i < array_size; i++) {
		P[element_id].name[i] = S[start_identifier++];
	}
	P[element_id].wins = I[thread_number];
	P[element_id].points = D[thread_number];

	return;
}