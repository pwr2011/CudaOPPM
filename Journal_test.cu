#define _CRT_SECURE_NO_WARNINGS

#include "device_launch_parameters.h"
#include "cuda_by_example/common/book.h"
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include<sys/time.h>
#include<cstdlib>
#include<stdio.h>
#include<fstream>
#include<cstring>
#include<utility>

//Merge Sort에서 사용하는 값. 패턴의 길이를 넘어가지 않음
#define MAX_COUNT 50
#define ThreadCount 1'024
using namespace std;

typedef pair<int, int> P;

__constant__ int DevPreCalFac[10];

struct timeval PreStart, PreEnd, SearchStart, SearchEnd, TotalStart, TotalEnd;

int PreCalFac[10] = { 0, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880 }; //0!~9!

void merge(int first, int mid, int last, P* arr) {

	int Idx = first;
	P TempArr[MAX_COUNT];


	int i = first, j = mid + 1;

	while (i <= mid && j <= last) {
		if (arr[i] <= arr[j]) {
			TempArr[Idx] = arr[i];
			Idx++;
			i++;
		}
		else if (arr[i] > arr[j]) {
			TempArr[Idx] = arr[j];
			Idx++;
			j++;
		}
	}

	if (i > mid) {
		for (int m = j; m <= last; m++) {
			TempArr[Idx] = arr[m];
			Idx++;
		}
	}
	else {
		for (int m = i; m <= mid; m++) {
			TempArr[Idx] = arr[m];
			Idx++;
		}
	}

	for (int m = first; m <= last; m++) {
		arr[m] = TempArr[m];
	}
}

void mergeSort(int first, int last, P* TempPattern) {

	if (first < last) {
		int mid = (first + last) / 2;
		mergeSort(first, mid, TempPattern);
		mergeSort(mid + 1, last, TempPattern);
		merge(first, mid, last, TempPattern);
	}
}

int FindMax(int* p, int len) {
	int ret = 0;
	for (int i = 0; i < len; i++) {
		if (p[i] > ret)
			ret = p[i];
	}
	return ret;
}

int CalQgram(int* Pattern, int StartIdx, int PatternLen, int BlockSize) {
	int result = 0;
	int count;

	for (int j = StartIdx; j < StartIdx + BlockSize; j++) {
		count = 0;
		for (int k = StartIdx; k < j; k++) {
			if (Pattern[k] <= Pattern[j])
				count++;
		}
		result += count * PreCalFac[j - StartIdx];
	}
	return result;
}

__device__ int DevCalQgram(int* Text, int StartIdx, int PatternLen, int BlockSize) {
	int result = 0;
	int count;

	for (int j = StartIdx; j < StartIdx + BlockSize; j++) {
		count = 0;
		for (int k = StartIdx; k < j; k++) {
			if (Text[k] <= Text[j])
				count++;
		}
		result += count * DevPreCalFac[j - StartIdx];
	}
	return result;
}

//Len과 PatternLen은 중복되는 정보이나 본 알고리즘에서
//패턴의 길이가 전부다 다른 경우도 고려할 수 있도록 Len 변수는 남겨둠.
//Loc table은 가로 * 세로 => 패턴길이 * 패턴개수인 논리적으로는 2차원이지만 실제로는 1차원인 배열임
void MakeLoc(P* TempPattern, int* Loc, int Len, int PatternCount, int PatternLen, int CurPatternIdx) {
	for (int i = 0; i < Len; i++) {
		int Idx = PatternLen * CurPatternIdx + i;
		Loc[Idx] = TempPattern[i].second;
	}
}

void MakeE(int* Pattern, int* Loc, int* E, int Len, int PatternCount, int CurPatternIdx) {
	for (int i = 0; i < Len - 1; i++) {
		int Idx = Len * CurPatternIdx + i;

		if (Pattern[Loc[Idx]] == Pattern[Loc[Idx + 1]])
			E[Idx] = 1;
		else
			E[Idx] = 0;
	}
}

void FillLoc(int** Pattern, int* Loc, int* E, int PatternCount, int PatternLen) {
	int Len;
	P* TempPattern;

	for (int i = 0; i < PatternCount; i++) {
		Len = PatternLen;
		TempPattern = new P[Len];

		for (int j = 0; j < Len; j++) {
			TempPattern[j].first = Pattern[i][j];
			TempPattern[j].second = j;
		}
		mergeSort(0, Len - 1, TempPattern);

		MakeLoc(TempPattern, Loc, Len, PatternCount, PatternLen, i);

		MakeE(Pattern[i], Loc, E, Len, PatternCount, i);
		delete[] TempPattern;
	}
}

void FillHash(int** Pattern, int BlockSize, int PatternCount, int PatternLen, int* Hash) {
	int range = PatternLen - BlockSize + 1;

	for (int i = 0; i < PatternCount; i++) {
		Hash[i] = CalQgram(Pattern[i], range - 1, PatternLen, BlockSize);
	}
}
__device__ bool CheckOP(int* DevLoc, int* Text, int* E, int StartIdx, int PatternLen, int PatternIdx, int PatternCount) {

	bool ret = true;
	for (int i = 0; i < PatternLen - 1; i++) {
		int Idx = i + PatternLen * PatternIdx;

		if (E[Idx] == 0) {
			if (Text[StartIdx + DevLoc[Idx]] >= Text[StartIdx + DevLoc[Idx + 1]]) {
				ret = false;
				break;
			}
		}

		else {
			if (Text[StartIdx + DevLoc[Idx]] != Text[StartIdx + DevLoc[Idx + 1]]) {
				ret = false;
				break;
			}
		}
	}
	return ret;
}


__global__ void Search(int* DevLoc, int* DevText, int* DevHash, int* DevE, int* DevMatchRes,
	int TextLen, int PatternCount, int PatternLen, int BlockSize, bool* DevMatchDetail) {
	int m = PatternLen;
	int q = BlockSize;

	int Idx = blockIdx.x * blockDim.x + threadIdx.x;
	int TotalThreadCount = blockDim.x * gridDim.x;
	int TextLenPerThread = (TextLen + TotalThreadCount - 1) / TotalThreadCount;
	int StartIdx = Idx * TextLenPerThread;
	int EndIdx = (Idx + 1) * TextLenPerThread;
	int s = StartIdx - (m - q);

	while (StartIdx < EndIdx) {
		if (StartIdx < m - q) {
			StartIdx++;
			continue;
		}
		if (StartIdx > TextLen - q) {
			break;
		}
		int temp = DevCalQgram(DevText, StartIdx, m, q);
		for (int i = 0; i < PatternCount; i++) {
			if (temp == DevHash[i]) {
				if (CheckOP(DevLoc, DevText, DevE, s, PatternLen, i, PatternCount)) {
					DevMatchDetail[TextLen * i + StartIdx] = true;
					//atomicAdd(&DevMatchRes[0], 1);
				}
			}
		}
		StartIdx++;
		s++;
	}
	__syncthreads();
}

extern "C" void InitLocGpu(int* Loc, int PatternCount, int PatternLen)
{
	//HANDLE_ERROR(cudaMemcpyToSymbol(DevLoc, Loc, PatternCount * PatternLen * sizeof(int)));
	HANDLE_ERROR(cudaMemcpyToSymbol(DevPreCalFac, PreCalFac, 10 * sizeof(int)));
}

void FreeVariable(int* DevMatchRes, int* DevHash, int* DevText, int* DevE,
	 int* Loc, int* Hash, int* E, int PatternCount, int* MatchRes, bool* MatchResDetail, bool* DevMatchDetail) {

	delete[] Loc;
	delete[] Hash;
	delete[] E;
	delete[] MatchRes;
	delete[] MatchResDetail;
	cudaFree(DevE);
	cudaFree(DevMatchRes);
	cudaFree(DevHash);
	cudaFree(DevText);
	cudaFree(DevMatchDetail);
}

pair<int, double> Do_Test_JH(int* T, int** P, int TextLen, int PatternLen, int PatternCount) {
	int** Pattern = P;
	int* Loc;
	int* E;
	int* Hash;
	int* Text = T;
	int* MatchRes;
	bool* MatchResDetail;

	//GPU variables
	int* DevMatchRes;
	int* DevHash;
	int* DevText;
	int* DevE;
	int* DevLoc;
	bool* DevMatchDetail;
	double sec, usec;
	double TotalPre = 0;
	double TotalSearch = 0;
	double Total = 0;
	int BlockSize = PatternLen <= 8 ? PatternLen : 9;

	Loc = new int[PatternLen * PatternCount];
	E = new int[PatternLen * PatternCount];
	Hash = new int[PatternCount];
	MatchResDetail = new bool[TextLen * PatternCount];

	gettimeofday(&TotalStart, NULL);

	//Fill the Location table
	gettimeofday(&PreStart, NULL);
	FillLoc(Pattern, Loc, E, PatternCount, PatternLen);

	//Fill the hash table
	FillHash(Pattern, BlockSize, PatternCount, PatternLen, Hash);
	gettimeofday(&PreEnd, NULL);

	//GPU Init !InitLocGpu는 관리자 권한으로 실행해야함!
	InitLocGpu(Loc, PatternCount, PatternLen);

	//GPU init
	HANDLE_ERROR(cudaMalloc((void**)&DevLoc, sizeof(int) * PatternLen * PatternCount));
	HANDLE_ERROR(cudaMalloc((void**)&DevMatchRes, sizeof(int) * 1));
	HANDLE_ERROR(cudaMalloc((void**)&DevHash, sizeof(int) * PatternCount));
	HANDLE_ERROR(cudaMalloc((void**)&DevText, sizeof(int) * TextLen));
	HANDLE_ERROR(cudaMalloc((void**)&DevE, sizeof(int) * PatternCount * PatternLen));
	HANDLE_ERROR(cudaMalloc((void**)&DevMatchDetail, TextLen * PatternCount * sizeof(bool)));

	HANDLE_ERROR(cudaMemcpy(DevLoc, Loc, sizeof(int) * PatternLen * PatternCount, cudaMemcpyHostToDevice));
	HANDLE_ERROR(cudaMemcpy(DevHash, Hash, sizeof(int) * PatternCount, cudaMemcpyHostToDevice));
	HANDLE_ERROR(cudaMemcpy(DevText, Text, sizeof(int) * TextLen, cudaMemcpyHostToDevice));
	HANDLE_ERROR(cudaMemcpy(DevE, E, sizeof(int) * PatternCount * PatternLen, cudaMemcpyHostToDevice));
	HANDLE_ERROR(cudaMemset(DevMatchRes, 0, sizeof(int)));
	HANDLE_ERROR(cudaMemset(DevMatchDetail, 0, TextLen * PatternCount * sizeof(bool)));

	//Kernel !3rd parameter is shared memory size in byte. Take care!
	gettimeofday(&SearchStart, NULL);
	//블럭개수 늘리기
	Search << <((TextLen + 1023) / 1024), 1024 >> > (DevLoc, DevText, DevHash, DevE, DevMatchRes, TextLen, PatternCount, PatternLen, BlockSize, DevMatchDetail);
	cudaDeviceSynchronize();

	gettimeofday(&SearchEnd, NULL);

	MatchRes = new int[2];
	HANDLE_ERROR(cudaMemcpy(MatchResDetail, DevMatchDetail, sizeof(bool) * TextLen * PatternCount, cudaMemcpyDeviceToHost));
	//HANDLE_ERROR(cudaMemcpy(MatchRes, DevMatchRes, sizeof(int), cudaMemcpyDeviceToHost));

	int RetMatchRes = 0;
	gettimeofday(&TotalEnd, NULL);

	sec = TotalEnd.tv_sec - TotalStart.tv_sec;
	usec = TotalEnd.tv_usec - TotalStart.tv_usec;
	Total += (sec * 1000 + usec / 1000.0);

	sec = PreEnd.tv_sec - PreStart.tv_sec;
	usec = PreEnd.tv_usec - PreStart.tv_usec;
	TotalPre += (sec * 1000 + usec / 1000.0);

	sec = SearchEnd.tv_sec - SearchStart.tv_sec;
	usec = SearchEnd.tv_usec - SearchStart.tv_usec;
	TotalSearch += (sec * 1000 + usec / 1000.0);

	for(int i=0;i<PatternCount*TextLen;i++){
		if(MatchResDetail[i] == true){
			RetMatchRes++;
		}
	}
	//Freeing Variable
	FreeVariable(DevMatchRes, DevHash, DevText, DevE, Loc, Hash, E, PatternCount, MatchRes, MatchResDetail, DevMatchDetail);

	return make_pair(RetMatchRes, Total);
}