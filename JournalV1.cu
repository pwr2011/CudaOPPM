//!매치 정보는 순위동형이 발생하는 텍스트에서의 위치만 전달한다!

//더 효율적으로 짤수 있지만 병렬화 전의 논문과의 비교를 위해 다른 인자는 통일해야 한다고 생각, 효율화 하지 않음
//검색단계만 병렬적으로 효율화를 함
//하지만 기존의 preprocessing_phi()는 너무 비효율적으로 작동하여 수정함, 대응되는게 MakeTempLoc()

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

//Merge Sort에서 사용하는 값. 패턴의 길이를 넘어가지 않음
#define Repeat 5
#define MAX_COUNT 1'000
#define ThreadCount 1'024
#define CopySize 1'000'005
#define GpuTextLen 100
using namespace std;

typedef pair<int,int> P;

__constant__ int DevLoc[16'000]; //MAX
__constant__ int DevPreCalFac[10];

//Input Folder Name
string InputFolder = "./TESTCASE/TC-";
string OutputFolder = "./JournalV1OUTPUT/TC-";
string TimeFolder = "./JournalV1TIME/";
string TextInput = "TextSample";
string PatternInput = "IntStr";
string TimeInput = "TimeRecord_";

struct timeval PreStart, PreEnd, SearchStart, SearchEnd, TotalStart, TotalEnd, CopyToHostStart, CopyToHostEnd;

int PreCalFac[10] = { 0, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880}; //0!~9!

void InputData(int ** Pattern, int * Text, int PatternCount, int PatternLen, int TextLen, int FolderNumber){
	//Pattern input
	string pattern_filename = InputFolder + to_string(FolderNumber)+"/"+PatternInput + "_" + to_string(PatternCount) + "_" +to_string(PatternLen) + ".txt";
	ifstream pattern(pattern_filename);
	
	for (int i = 0; i < PatternCount; i++) {
    	for (int j = 0; j < PatternLen; j++) {
        	pattern >> Pattern[i][j];
		}
	}
	pattern.close();

	//Text input
	string text_filename = InputFolder + to_string(FolderNumber)+"/"+ TextInput + "_" + to_string(TextLen) + ".txt";
	ifstream text(text_filename);

	for (int i = 0; i < TextLen; i++) {
		text >> Text[i];
	}
	text.close();
	return ;
}

void OutputData(int PatternCount, int PatternLen, int TextLen,int BlockSize, int FolderNumber,int MatchRes, bool * MatchResDetail){
	string FileName = OutputFolder+ to_string(FolderNumber)+"/"+PatternInput + "_" +
	 to_string(PatternCount) + "_" +to_string(PatternLen) +"_"+to_string(TextLen) +"_"+to_string(BlockSize) + ".txt";
	 
	ofstream FileStream(FileName);
	FileStream<<MatchRes;
	/*FileStream<<"\n";
	for(int t=0;t<TextLen; t++){
		FileStream<<MatchResDetail[t]<<" ";
	}*/
	FileStream.close();
}

void OutputTime(double Pre, float Search, double Total,double TotalCopy, int PatternCount,int PatternLen, int TextLen,int BlockSize){
	string FileName = TimeFolder + PatternInput + "_" +
					  to_string(PatternCount) + "_" + to_string(PatternLen) + "_" +
					   to_string(TextLen) + "_" + to_string(BlockSize)+".txt";

	ofstream FileStream(FileName);
	FileStream<<(double)(Pre)/Repeat<<" "<<(double)(Search)/Repeat<<" "
	<<(double)(Total)/Repeat<<" "<<(double)(TotalCopy)/Repeat;

	FileStream.close();
}

ofstream GetFileStream(int PatternCount, int PatternLen){
	string FileName = OutputFolder + "FP_" + to_string(PatternCount) + "_" + to_string(PatternLen) + ".txt";
	ofstream FileStream(FileName);
	return FileStream;
}

int FindLen(int* p, int PatternLen) {

	int ret = PatternLen;
	for (int i = 0; i < PatternLen; i++) {
		if (p[i] < 0 || p[i] == 0) {
			ret = i;
			break;
		}
	}

	return ret;
}

void merge(int first, int mid, int last, P* arr) {

	int idx = first;
	P TempArr[MAX_COUNT];


	int i = first, j = mid + 1;

	while (i <= mid && j <= last) {
		if (arr[i] <= arr[j]) {
			TempArr[idx] = arr[i];
			idx++;
			i++;
		}
		else if (arr[i] > arr[j]) {
			TempArr[idx] = arr[j];
			idx++;
			j++;
		}
	}

	if (i > mid) {
		for (int m = j; m <= last; m++) {
			TempArr[idx] = arr[m];
			idx++;
		}
	}
	else {
		for (int m = i; m <= mid; m++) {
			TempArr[idx] = arr[m];
			idx++;
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
		result += count * PreCalFac[j-StartIdx];
	}
	return result;
}

__device__ int DevCalQgram(int Text[], int StartIdx, int PatternLen, int BlockSize){
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
void MakeLoc(P* TempPattern, int* Loc, int Len, int PatternCount,int PatternLen, int CurPatternIdx) {
	for (int i = 0; i < Len; i++) {
		int idx = CurPatternIdx + i * PatternCount;
		Loc[idx] = TempPattern[i].second;
	}
}

void MakeE(int* Pattern, int* Loc, int* E, int Len,int PatternCount, int CurPatternIdx) {
	for (int i = 0; i < Len - 1; i++) {
		int idx = CurPatternIdx + i * PatternCount;

		if (Pattern[Loc[idx]] == Pattern[Loc[idx + PatternCount]])
			E[idx] = 1;
		else
			E[idx] = 0;
	}
}

void FillLoc(int ** Pattern, int * Loc, int* E, int PatternCount, int PatternLen){
	int Len;
	P* TempPattern;

	for (int i = 0; i < PatternCount; i++) {
		Len = FindLen(Pattern[i], PatternLen);
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

void FillHash(int **Pattern, int BlockSize, int PatternCount, int PatternLen, int * Hash){
	int range = PatternLen - BlockSize + 1;

	for (int i = 0; i < PatternCount; i++) {
		Hash[i] = CalQgram(Pattern[i], range - 1, PatternLen, BlockSize);
	}
}

//__device__ InitSharedMemory()
__device__ bool CheckOP(int Text[], int* E, int StartIdx, int PatternLen, int PatternIdx, int PatternCount) {
	
	bool ret = true;
	for (int i = 0; i < PatternLen-1; i++) {
		int idx = PatternCount * i + PatternIdx;
		
		if (E[idx] == 0) {
			if (Text[StartIdx + DevLoc[idx]] >= Text[StartIdx + DevLoc[idx + PatternCount]]) {
				ret = false;
				break;
			}
		}

		else {
			if (Text[StartIdx + DevLoc[idx]] != Text[StartIdx + DevLoc[idx + PatternCount]]) {
				ret = false;
				break;
			}
		}
	}
	return ret;
}


__global__ void Search(int * DevText, int * DevHash,int * DevE,int * DevMatchRes,
	 int TextLen, int PatternCount, int PatternLen,int BlockSize,bool * DevMatchDetail){

	extern __shared__ int sharedText[]; //dynamic allocation
	int bidx = blockIdx.x;
	int tidx = threadIdx.x;
	int TextRange = GpuTextLen + PatternLen;
	int TextStart = bidx * GpuTextLen;

	//마지막 block일때 길이.
	int CurTextLen = (TextLen/GpuTextLen) -1 == bidx ? GpuTextLen-PatternLen : GpuTextLen;

	if(tidx<TextRange && (TextStart + tidx < TextLen)){
		sharedText[tidx] = DevText[TextStart+tidx];
	}
	__syncthreads();
	if(tidx<PatternCount){
		for(int i=0; i < CurTextLen; i++){
			int temp = DevCalQgram(sharedText, i+PatternLen-BlockSize, PatternLen, BlockSize);
			
			if(temp == DevHash[tidx]){
				if(CheckOP(sharedText, DevE, i,PatternLen, tidx, PatternCount)){
				//atomicAdd(&DevMatchRes[0], 1);
				DevMatchDetail[(TextStart+i) + (tidx * TextLen)] = true;
				}
			}
		}
	}
	__syncthreads();
}

extern "C" void InitLocGpu(int * Loc,int PatternCount, int PatternLen)
{
	HANDLE_ERROR(cudaMemcpyToSymbol(DevLoc, Loc, PatternCount * PatternLen * sizeof(int)));
	HANDLE_ERROR(cudaMemcpyToSymbol(DevPreCalFac, PreCalFac, 10 * sizeof(int)));
}

void FreeVariable(int * DevMatchRes,int * DevHash,int * DevText, int *DevE,
	int * Text, int **Pattern,int * Loc,int * Hash,int * E, int PatternCount,int * MatchRes, bool *MatchResDetail, bool * DevMatchDetail){
	
	for(int i=0;i<PatternCount;i++){
		delete[] Pattern[i];
	}
	delete[] Text;
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

void PrintTestInfo(int PatternCount,int PatternLen,int TextLen, int MatchRes){
	printf("Pattern count: %d Pattern_length : %d TEXT SIZE : %d\nOP size : %d\n\n", PatternCount, PatternLen,TextLen, MatchRes);
}

int main(){
	int ** Pattern;
	int * Loc;
	int * E;
	int * Hash;
	int * Text;
	int * MatchRes;
	bool * MatchResDetail;

	//GPU variables
	int * DevMatchRes;
	int * DevHash;
	int * DevText;
	int * DevE;
	bool * DevMatchDetail;

	for (int BlockSize = 7; BlockSize <= 7; BlockSize++) {
		for (int PatternCount = 100; PatternCount <= 1'000; PatternCount += 100) { // 100~1000
			for (int PatternLen = 7; PatternLen <= 15; PatternLen += 1) { //3~15
				printf("Pattern Count: %d\nPattern Len : %d\n",PatternCount, PatternLen);

				for (int TextLen = 100'000; TextLen <= 1'000'000; TextLen += 100'000) { //100'000 ~ 1'000'000
				double sec, usec;
				double TotalPre = 0;
				double TotalSearch = 0;
				double Total = 0;
				double TotalCopy = 0;
				for(int FolderNumber = 0;FolderNumber < Repeat;FolderNumber++){
					Text = new int[TextLen];

					//!Warning! Only this two table is row * col => PatternLen * PatternCount
					Loc = new int[PatternLen * PatternCount];
					E = new int[PatternLen * PatternCount];
					Hash = new int[PatternCount];

					Pattern = new int*[PatternCount];
					for (int i = 0; i < PatternCount; i++) {
						Pattern[i] = new int[PatternLen];
					}
					MatchResDetail = new bool[TextLen * PatternCount];

					//Read Text and Pattern
					InputData(Pattern, Text, PatternCount, PatternLen, TextLen,FolderNumber);

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
					HANDLE_ERROR(cudaMalloc((void**)&DevMatchRes, sizeof(int) * 1));
					HANDLE_ERROR(cudaMalloc((void**)&DevHash, sizeof(int) * PatternCount));
					HANDLE_ERROR(cudaMalloc((void**)&DevText, sizeof(int) * TextLen));
					HANDLE_ERROR(cudaMalloc((void**)&DevE, sizeof(int) * PatternCount * PatternLen));
					HANDLE_ERROR(cudaMalloc((void**)&DevMatchDetail, TextLen*PatternCount * sizeof(bool)));

					HANDLE_ERROR(cudaMemcpy(DevHash, Hash, sizeof(int) * PatternCount, cudaMemcpyHostToDevice));
					HANDLE_ERROR(cudaMemcpy(DevText, Text, sizeof(int) * TextLen, cudaMemcpyHostToDevice));
					HANDLE_ERROR(cudaMemcpy(DevE, E, sizeof(int) * PatternCount * PatternLen, cudaMemcpyHostToDevice));
					HANDLE_ERROR(cudaMemset(DevMatchRes, 0, sizeof(int)));
					HANDLE_ERROR(cudaMemset(DevMatchDetail, 0 ,TextLen*PatternCount*sizeof(bool)));

					//Kernel !3rd parameter is shared memory size in byte. Take care!
					gettimeofday(&SearchStart, NULL);
					//블럭개수 늘리기
					Search<<<(TextLen/GpuTextLen), ThreadCount, 1000>>>(DevText, DevHash, DevE, DevMatchRes, TextLen, PatternCount, PatternLen,BlockSize,DevMatchDetail);
					cudaDeviceSynchronize();

					gettimeofday(&SearchEnd, NULL);
					
					MatchRes = new int[2];
					gettimeofday(&CopyToHostStart,NULL);
					HANDLE_ERROR(cudaMemcpy(MatchResDetail, DevMatchDetail, sizeof(bool) * TextLen * PatternCount, cudaMemcpyDeviceToHost));
					HANDLE_ERROR(cudaMemcpy(MatchRes, DevMatchRes, sizeof(int), cudaMemcpyDeviceToHost));
					gettimeofday(&CopyToHostEnd,NULL);
					
					//PrintTestInfo(PatternCount, PatternLen,TextLen, MatchRes[0]);
					OutputData(PatternCount, PatternLen, TextLen, BlockSize,FolderNumber, MatchRes[0], MatchResDetail);
					//Freeing Variable
					FreeVariable(DevMatchRes, DevHash, DevText,DevE, Text, Pattern, Loc, Hash, E, PatternCount, MatchRes, MatchResDetail, DevMatchDetail);
					gettimeofday(&TotalEnd, NULL);
					
					sec = TotalEnd.tv_sec - TotalStart.tv_sec;
					usec = TotalEnd.tv_usec - TotalStart.tv_usec;
					Total += (sec*1000+usec/1000.0);

					sec = PreEnd.tv_sec - PreStart.tv_sec;
					usec = PreEnd.tv_usec - PreStart.tv_usec;
					TotalPre += (sec*1000+usec/1000.0);

					sec = SearchEnd.tv_sec - SearchStart.tv_sec;
					usec = SearchEnd.tv_usec - SearchStart.tv_usec;
					TotalSearch += (sec*1000+usec/1000.0);

					sec = CopyToHostEnd.tv_sec - CopyToHostStart.tv_sec;
					usec = CopyToHostEnd.tv_usec - CopyToHostStart.tv_usec;
					TotalCopy += (sec*1000+usec/1000.0); 
				}	
				//Folder End
				OutputTime(TotalPre, TotalSearch, Total,TotalCopy,PatternCount,PatternLen, TextLen,BlockSize);
			}
		}
	}
}
	return 0;
}