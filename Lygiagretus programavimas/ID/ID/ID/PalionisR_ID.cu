
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <fstream>
#include <iostream>
#include <string>
#include <time.h>

/**
* Rokas Palionis IFF-5/8 individualus darbas
* 


#define min(a, b) (a < b ? a : b)

/**
* Sujungia duomenis, kiekvienai duomenø daliai
*/
__device__ void gpu_bottomUpMerge(long* source, long* dest, long start, long middle, long end) {
	long i = start;
	long j = middle;
	for (long k = start; k < end; k++) {
		if (i < middle && (j >= end || source[i] < source[j])) {
			dest[k] = source[i];
			i++;
		}
		else {
			dest[k] = source[j];
			j++;
		}
	}
}
/**
* Suskaièiuoja dabartinës gijos id
*/
__device__ unsigned int getIdx(dim3* threads, dim3* blocks) {
	int x;
	return threadIdx.x +
		threadIdx.y * (x = threads->x) +
		threadIdx.z * (x *= threads->y) +
		blockIdx.x  * (x *= threads->z) +
		blockIdx.y  * (x *= blocks->z) +
		blockIdx.z  * (x *= blocks->y);
}
/**
* Pateiktai duomenø daliai vykdo MergeSort rikiavimà
*/
__global__ void gpu_mergesort(long* source, long* dest, long size, long width, long slices, dim3* threads, dim3* blocks) {
	unsigned int idx = getIdx(threads, blocks);
	long start = width*idx*slices,
		middle,
		end;

	for (long slice = 0; slice < slices; slice++) {
		if (start >= size)
			break;

		middle = min(start + (width >> 1), size);
		end = min(start + width, size);
		gpu_bottomUpMerge(source, dest, start, middle, end);
		start += width;
	}
}
/**
* Pradeda vykdyti MergeSort algoritmà: paruoðia atmintá, perkopijuoja duomenis á GPU
* paleidþia gpu_mergesort rikiavimà kiekvienai duomenø porcijai
*/
void mergesort(long* data, long size, dim3 threadsPerBlock, dim3 blocksPerGrid) {

	// Sukuriami du masyvai
	// Vykdymo metu jie yra keièiami vienas su kitu
	long* D_data;
	long* D_swp;
	// kiekis
	dim3* D_threads;
	dim3* D_blocks;

	// paskiriama atmintis masyvams i GPU
	cudaMalloc((void**)&D_data, size * sizeof(long));
	cudaMalloc((void**)&D_swp, size * sizeof(long));

	cudaMemcpy(D_data, data, size * sizeof(long), cudaMemcpyHostToDevice);
	
	cudaMalloc((void**)&D_threads, sizeof(dim3));
	cudaMalloc((void**)&D_blocks, sizeof(dim3));

	// is gpu i cpu
	cudaMemcpy(D_threads, &threadsPerBlock, sizeof(dim3), cudaMemcpyHostToDevice);
	cudaMemcpy(D_blocks, &blocksPerGrid, sizeof(dim3), cudaMemcpyHostToDevice);

	long* A = D_data;
	long* B = D_swp;

	long nThreads = threadsPerBlock.x * threadsPerBlock.y * threadsPerBlock.z *
		blocksPerGrid.x * blocksPerGrid.y * blocksPerGrid.z;

	clock_t startTime, endTime;

	// Vykdomas MergeSort algoritmas
	startTime = clock();

	for (int width = 2; width < (size << 1); width <<= 1) {
		long slices = size / ((nThreads)* width) + 1;

		gpu_mergesort << <blocksPerGrid, threadsPerBlock >> >(A, B, size, width, slices, D_threads, D_blocks);

		// Switch the input / output arrays instead of copying them around
		A = A == D_data ? D_swp : D_data;
		B = B == D_data ? D_swp : D_data;
	}

	cudaDeviceSynchronize();

	endTime = clock();
	std::cout << "\n\tVykdymo laikas (merge sort): " << endTime - startTime << " ms\n";

	// grazinam i cpu
	cudaMemcpy(data, A, size * sizeof(long), cudaMemcpyDeviceToHost);

	cudaFree(A);
	cudaFree(B);
}

void generateData(long array[], long length) {
	
	for (long i = 0; i < length; i++)
		array[i] = rand();
}

void readData(long data[], long size, std::ifstream & readStream) {

	for (long i = 0; readStream.good() && i < size; i++) {
		readStream >> data[i];
	}

	return;
}

void writeData(long data[], long size, std::ofstream & writeStream) {

	for (long i = 0; writeStream.good() && i < size; i++) {
		writeStream << data[i] << std::endl;
	}

	return;
}



int main() {



	dim3 threadsPerBlock;
	dim3 blocksPerGrid;

	threadsPerBlock.x = 1;
	threadsPerBlock.y = 1;
	threadsPerBlock.z = 1;

	blocksPerGrid.x = 1;
	blocksPerGrid.y = 1;
	blocksPerGrid.z = 1;

	long size = 600000;

	long *data = new long[size];

	std::cout << "Áveskite duomenø kieká (n > 0), gijø kieká (k >= 1), blokø kieká (l >= 1): ";
	std::cin >> size >> threadsPerBlock.x >> blocksPerGrid.x;

	if (size < 1) {
		std::cout << "\n\tElementø kiekis turi bûti didesnis uþ 0!\n\nPrograma nesëkmingai baigë darbà!\n";
		return -1;
	}

	std::string readFileName = "data/" + std::to_string(size) + ".data.txt";
	std::string writeFileName = "results/" + std::to_string(size) + ".result.txt";

	std::ifstream readStream(readFileName);

	// Tikrinama ar failas egzistuoja
	if (readStream.good()) {
		readData(data, size, readStream);
		readStream.close();
	}
	else {
		generateData(data, size);

		// generuota masyva spausdina i faila
		std::ofstream writeStreamData(readFileName);
		writeData(data, size, writeStreamData);
		writeStreamData.close();
	}

	mergesort(data, size, threadsPerBlock, blocksPerGrid);

	std::ofstream writeStream(writeFileName);

	writeData(data, size, writeStream);

	writeStream.close();

	std::cout << "\nPrograma sëkmingai baigë darbà!\n";

	return 0;
}