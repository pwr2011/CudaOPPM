/*

2020.01.02

검색단계 병렬화 correctness 확인완료

*/

#define _CRT_SECURE_NO_WARNINGS

#include<iostream>

#include<ctime>

#include<fstream>

#include<cstdlib>

#include<iomanip>

#include<cmath>

#include<string>

#include "cuda_by_example/common/book.h"

#include "cuda_runtime.h"

#include "device_launch_parameters.h"

 

using namespace std;

 

#define MAX_COUNT 2000
#define MAX_LEN 20
#define CopySize 1'000'000
//#define BlockSize 3

//#define TextLen 1048575

 

#define min(a,b) a<b?a:b

#define max(a,b) a<b?b:a

string InputFolder = "./TESTCASE/TC-";
string OutputFolder = "./OUTPUT/TC-";
string TimeFolder = "./TIME/";
string TextInput = "TextSample";
string PatternInput = "IntStr";
string TimeInput = "TimeRecord_";
clock_t CopyToHostStart;
clock_t CopyToHostEnd;
clock_t SearchStart;
clock_t SearchEnd;
clock_t TotalStart;
clock_t TotalEnd;



class Hash_T {

public:

	int* pattern;

	Hash_T* next;

	int p_num;

	Hash_T();

};

Hash_T::Hash_T() {

 

	this->pattern = NULL;

	this->next = NULL;

	this->p_num = -1;

}

struct inv_H {

	int pattern_num;

	int FP_value;

};

 

int** make_p_prime(int** p, int m, int PatternCount) {

 

	int** temp = new int*[PatternCount];

	for (int i = 0; i < PatternCount; i++) {

		temp[i] = new int[m];

	}

 

	for (int i = 0; i < PatternCount; i++) {

		for (int j = 0; j < m; j++) {

			temp[i][j] = p[i][j];

		}

	}

 

	return temp;

}

void merge_H(int first, int mid, int last, inv_H* arr) {

 

	int idx = first;

 

	inv_H temp_arr[MAX_COUNT];

	int i = first, j = mid + 1;

 

	while (i <= mid && j <= last) {

		if (arr[i].FP_value <= arr[j].FP_value) {

			temp_arr[idx] = arr[i];

			idx++;

			i++;

		}

		else if (arr[i].FP_value > arr[j].FP_value) {

			temp_arr[idx] = arr[j];

			idx++;

			j++;

		}

	}

 

	if (i > mid) {

		for (int m = j; m <= last; m++) {

			temp_arr[idx] = arr[m];

			idx++;

		}

	}

	else {

		for (int m = i; m <= mid; m++) {

			temp_arr[idx] = arr[m];

			idx++;

		}

	}

 

	for (int m = first; m <= last; m++) {

		arr[m] = temp_arr[m];

	}

}

void mergeSort_H(int first, int last, inv_H* arr) {

	if (first < last) {

		int mid = (first + last) / 2;

		mergeSort_H(first, mid, arr);

		mergeSort_H(mid + 1, last, arr);

		merge_H(first, mid, last, arr);

	}

}

int Binary_Search(inv_H* arr, int size, int find_FP) {

 

	int low = 0, high = size - 1, mid;

 

	while (low <= high) {

		mid = (low + high) / 2;

		if (arr[mid].FP_value > find_FP) {

			high = mid - 1;

		}

		else if (arr[mid].FP_value < find_FP) {

			low = mid + 1;

		}

		else {

			return mid;

		}

	}

 

	return -1;

}

int factorial(int n) {

	return (n == 1 || n == 0) ? 1 : factorial(n - 1)*n;

}

 

__device__ int fac(int n) {

	return (n == 1 || n == 0) ? 1 : fac(n - 1)*n;

}

int q_gram_H(int* p, int s_idx, int m, int q) {

 

	//int size = m - q + 1;

	//int* ret = new int[size];

	int ret;

	int result;

	int count;

 

	//for (int i = 0; i < size; i++) {

 

	int i = s_idx;

	result = 0;

 

	for (int j = i; j < i + q; j++) {

		count = 0;

		for (int k = i; k < j; k++) {

			if (p[k] <= p[j])

				count++;

		}

		result += count * factorial(j - i);

	}

 

	ret = result;

	//}

	return ret;

}

 

__device__ int q_gram(int* p, int s_idx, int m, int q) {

 

	//int size = m - q + 1;

	//int* ret = new int[size];

	int ret;

	int result;

	int count;

 

	//for (int i = 0; i < size; i++) {

 

	int i = s_idx;

	result = 0;

 

	for (int j = i; j < i + q; j++) {

		count = 0;

		for (int k = i; k < j; k++) {

			if (p[k] <= p[j])

				count++;

		}

		result += count * fac(j - i);

	}

 

	ret = result;

	//}

	return ret;

}

void preprocessing_table(int** p, int B_size, int PatternCount, int PatternLen, int* Hash_Arr, inv_H* inverse_Hash) {

 

	int m = PatternLen;

	int range = m - B_size + 1;

	int** p_prime = make_p_prime(p, m, PatternCount);

 

	for (int i = 0; i < PatternCount; i++) {

		Hash_Arr[i] = q_gram_H(p_prime[i], range - 1, m, B_size);

	}

	for (int i = 0; i < PatternCount; i++)

		delete[] p_prime[i];

	delete[] p_prime;

}

 

int find_len_H(int* p, int PatternLen) {

 

	int ret = PatternLen;

	for (int i = 0; i < PatternLen; i++) {

		if (p[i] < 0 || p[i] == 0) {

			ret = i;

			break;

		}

	}

 

	return ret;

}

 

__device__ int find_len(int* p, int arr_idx, int PatternLen) {

 

	int ret = PatternLen;

	for (int i = arr_idx; i < PatternLen + arr_idx; i++) {

		if (p[i] < 0 || p[i] == 0) {

			ret = i;

			break;

		}

	}

	return ret;

}

__device__ int find_max_H(int* p,int s_idx, int len) {

 

	int ret = 0;

 

	for (int i = s_idx; i < s_idx+len; i++) {

		if (p[i] > ret)

			ret = p[i];

	}

 

	return ret;

}

int find_max(int* p, int len) {

 

	int ret = 0;

 

	for (int i = 0; i < len; i++) {

		if (p[i] > ret)

			ret = p[i];

	}

 

	return ret;

}

void merge(int first, int mid, int last, int* arr) {

 

	int idx = first;

	int temp_arr[MAX_COUNT];

 

 

	int i = first, j = mid + 1;

 

	while (i <= mid && j <= last) {

		if (arr[i] <= arr[j]) {

			temp_arr[idx] = arr[i];

			idx++;

			i++;

		}

		else if (arr[i] > arr[j]) {

			temp_arr[idx] = arr[j];

			idx++;

			j++;

		}

	}

 

	if (i > mid) {

		for (int m = j; m <= last; m++) {

			temp_arr[idx] = arr[m];

			idx++;

		}

	}

	else {

		for (int m = i; m <= mid; m++) {

			temp_arr[idx] = arr[m];

			idx++;

		}

	}

 

	for (int m = first; m <= last; m++) {

		arr[m] = temp_arr[m];

	}

}

void mergeSort(int first, int last, int* arr) {

 

	if (first < last) {

		int mid = (first + last) / 2;

		mergeSort(first, mid, arr);

		mergeSort(mid + 1, last, arr);

		merge(first, mid, last, arr);

	}

}

 

void make_phi_inv(int* phi, int* phi_inv, int len) {

 

	for (int i = 0; i < len; i++) {

		phi_inv[phi[i]] = i;

	}

}

void make_E(int* p, int* phi_inv, int* E, int len) {

 

	for (int i = 0; i < len - 1; i++) {

		if (p[phi_inv[i]] == p[phi_inv[i + 1]])

			E[i] = 1;

		else

			E[i] = 0;

	}

}

__global__ void make_phi(int* temp_p_1d, int* p_1d, int* phi_1d, int len, int PatternCount) {

	//temp_p_1d 가 정렬되어있는것임

	//하나의 스레드가 하나의 파이 만든다

	int idx = blockDim.x*blockIdx.x + threadIdx.x;

	int arr_idx = idx * len;

 

	if (idx <PatternCount) {

		int * flag = new int[len];

		for (int i = 0; i < len; i++) {

			flag[i] = 0;

		}

		for (int i = arr_idx; i < arr_idx + len; i++) {

			phi_1d[i] = -1;

		}

 

		int temp;

		for (int i = arr_idx; i < arr_idx+len; i++) {

			temp = p_1d[i];

			for (int j = arr_idx; j < arr_idx+len; j++) {

				if (temp_p_1d[j] == temp && flag[j-arr_idx] == 0) {// temp_p_1d는 정렬되어 있음 

					phi_1d[i] = j - arr_idx;

					flag[j-arr_idx] = 1;

					break;

				}

			}

		}

		delete flag;

	}

}

 

void preprocessing_phi(int* pattern_1d, int** p, int** phi, int** phi_inv, int** E, int PatternCount, int PatternLen) {

	//string FOLDER = "./OUTPUT/";

	//string FILENAME = "out.txt";

	int* temp_pattern_1d = new int[PatternCount * PatternLen];

	int* temp_arr = new int[PatternLen];

	int* phi_1d = new int[PatternCount *PatternLen];

 

	//global 함수//

	int* dev_pattern_1d;

	int* dev_temp_pattern_1d;

	int* dev_phi_1d;

	//gpu 메모리 할당//

	HANDLE_ERROR(cudaMalloc((void**)&dev_pattern_1d, PatternCount * PatternLen * sizeof(int)));

	HANDLE_ERROR(cudaMalloc((void**)&dev_temp_pattern_1d, PatternCount * PatternLen * sizeof(int)));

	HANDLE_ERROR(cudaMalloc((void**)&dev_phi_1d, PatternCount * PatternLen * sizeof(int)));

 

	for (int i = 0; i < PatternCount; i++) {

		for (int j = 0; j < PatternLen; j++) {

			temp_arr[j] = pattern_1d[i*PatternLen+j];

		}

		mergeSort(0, PatternLen - 1, temp_arr);

 

		for (int j = 0; j < PatternLen; j++) {

			temp_pattern_1d[i*PatternLen + j] = temp_arr[j];

		}

	}

 

	HANDLE_ERROR(cudaMemcpy(dev_pattern_1d, pattern_1d, PatternCount * PatternLen * sizeof(int), cudaMemcpyHostToDevice));

	HANDLE_ERROR(cudaMemcpy(dev_temp_pattern_1d, temp_pattern_1d, PatternCount * PatternLen * sizeof(int),cudaMemcpyHostToDevice));

 

	make_phi << <(PatternCount + 127) / 128, 128 >> > (dev_temp_pattern_1d, dev_pattern_1d, dev_phi_1d, PatternLen, PatternCount);

	cudaThreadSynchronize();

	HANDLE_ERROR(cudaMemcpy(phi_1d, dev_phi_1d, PatternCount * PatternLen * sizeof(int), cudaMemcpyDeviceToHost));

 

	for (int i = 0; i < PatternCount; i++) {
		
		for (int j = 0; j < PatternLen; j++) {

			phi[i][j] = phi_1d[i*PatternLen + j];

		}

	}

	

	for (int i = 0; i < PatternCount; i++) {
		make_phi_inv(phi[i], phi_inv[i], PatternLen);

		make_E(p[i], phi_inv[i], E[i], PatternLen);
	}

	cudaFree(dev_pattern_1d);

	cudaFree(dev_phi_1d);

	cudaFree(dev_temp_pattern_1d);

	delete[] phi_1d;

	delete[] temp_pattern_1d;


}

int finger_printing(int* p, int s, int m, int q) {

 

	int ret = 0;

 

	//for (int i = 0; i < q; i++) {

 

	int count;

	for (int j = s; j < s + q; j++) {

		count = 0;

		for (int k = s; k < j; k++) {

			if (p[k] <= p[j])

				count++;

		}

		ret += count * factorial(j - s);

	}

	//}

 

	return ret;

}

__device__ bool Check_OP(int* T, int arr_idx, int* P, int s, int len, int* phi_inv, int* E) {

 

	bool ret = true;

	for (int i = arr_idx; i < arr_idx + len - 1; i++) {

 

		if (E[i] == 0) {

			if (T[s + phi_inv[i]] >= T[s + phi_inv[i + 1]]) {

				ret = false;

				break;

			}

		}

		else {

			if (T[s + phi_inv[i]] != T[s + phi_inv[i + 1]]) {

				ret = false;

				break;

			}

		}

	}

	return ret;

}

__global__ void Search (int* match_count, bool * match, int* Text, int* p, int* Hash_Arr, int* phi_inv, int* E, int PatternCount, int PatternLen, int BlockSize, int TextLen) {

	int m = PatternLen;

	int q = BlockSize;


	int idx = blockIdx.x * blockDim.x + threadIdx.x;

	int totalthreadsize = blockDim.x * gridDim.x;

	int threadPerTextlen = (TextLen+totalthreadsize-1) / totalthreadsize;

	int start_idx = idx * threadPerTextlen; //Text start idx

	int end_idx = (idx + 1) *threadPerTextlen;//Text end idx 둘다 

	int s = start_idx-(m-q);

	 

	while (start_idx < end_idx) {

		if (start_idx < m - q) {

			start_idx++;

			continue;

		}

		if (start_idx >= TextLen - q) {

			break;

		}

		int temp = q_gram(Text, start_idx, m, q);

		for (int i = 0; i < PatternCount; i++) {

			if (temp == Hash_Arr[i]) {

				int P_len = find_len(p,i*m, PatternLen);

				if (Check_OP(Text,i*m, p, s, P_len, phi_inv, E)) {

					//match[TextLen*i + start_idx + q]=1;

					atomicAdd(&match_count[0], 2);
					match[start_idx+q] = true;

				}

			}

		}

		start_idx++;

		s++;

	}

	__syncthreads();

}
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

void PrintTestInfo(int PatternCount,int PatternLen,int TextLen, int MatchRes){
	printf("Pattern count: %d Pattern_length : %d TEXT SIZE : %d\nOP size : %d\n\n", PatternCount, PatternLen,TextLen, MatchRes);
}

int main() {

	int** Pattern;
	int* pattern_1d;
	int* PatternLength;
	int** phi;
	int** phi_inv;
	int* phi_inv_1d;
	int** E;
	int* E_1d;
	int* Text;
	int* hash_Arr;
	bool* match;
	int* match_count;

	struct inv_H * inverse_hash_Arr;

	// Calculated Table Size - 미리 계산된 q!
for(int FolderNumber = 0; FolderNumber <=2;FolderNumber++){
	for (int BlockSize = 3; BlockSize <= 3; BlockSize++) {
		for (int PatternCount = 100; PatternCount <= 1'000; PatternCount += 100) {
			for (int PatternLen = 3; PatternLen <= 15; PatternLen += 1) {
				for (int TextLen = 50'000; TextLen <= 50'000; TextLen += 10'000) {
					TotalStart = clock();

					Text = new int[TextLen];
					
					Pattern = new int*[PatternCount];
					for (int i = 0; i < PatternCount; i++) {
						Pattern[i] = new int[PatternLen];
					}
					//Read Text and Pattern
					InputData(Pattern, Text, PatternCount, PatternLen, TextLen,FolderNumber);
					hash_Arr = new int[PatternCount];
					inverse_hash_Arr = new inv_H[PatternCount];
					phi = new int *[PatternCount];
					phi_inv = new int *[PatternCount];
					E = new int *[PatternCount];
					PatternLength = new int[PatternCount];

					for (int i = 0; i < PatternCount; i++) {
						PatternLength[i] = PatternLen;
					}
					int res = 0;

 					for (int i = 0; i < PatternCount; i++)
					{
						res += PatternLength[i];
						phi[i] = new int[PatternLen];
						phi_inv[i] = new int[PatternLen];
						E[i] = new int[PatternLen];
					}
					pattern_1d = new int[res];

 
					int temp = 0;
					for (int i = 0; i < PatternCount; i++) {
						for (int j = 0; j < PatternLength[i]; j++) {
							pattern_1d[temp++] = Pattern[i][j];
						}
					}

					/* GPU 변수들 */

 					int* dev_text;
					int* dev_p;
					int* dev_hash_Arr;
					int* dev_phi_inv;
					int* dev_E;
					bool* dev_match;
					int* dev_match_count; 

					//********************************** finger 값 계산 *******************************************//

 					HANDLE_ERROR(cudaMalloc((void**)&dev_p, res * sizeof(int)));//pattern
					HANDLE_ERROR(cudaMalloc((void**)&dev_text, TextLen * sizeof(int)));
					//HANDLE_ERROR(cudaMalloc((void**)&dev_p_length, PatternCount * sizeof(int)));
					HANDLE_ERROR(cudaMalloc((void**)&dev_hash_Arr, PatternCount * sizeof(int)));
					HANDLE_ERROR(cudaMalloc((void**)&dev_phi_inv, res * sizeof(int)));//make 1d arr!
					HANDLE_ERROR(cudaMalloc((void**)&dev_E, res * sizeof(int)));
					HANDLE_ERROR(cudaMalloc((void**)&dev_match, CopySize * sizeof(bool)));
					HANDLE_ERROR(cudaMalloc((void**)&dev_match_count, 1 * sizeof(int)));

					HANDLE_ERROR(cudaMemcpy(dev_p, pattern_1d, res * sizeof(int), cudaMemcpyHostToDevice));
					HANDLE_ERROR(cudaMemcpy(dev_text, Text, TextLen * sizeof(int), cudaMemcpyHostToDevice));
					HANDLE_ERROR(cudaMemset(dev_match_count, 0, 1 * sizeof(int)));
					HANDLE_ERROR(cudaMemset(dev_match, 0, CopySize * sizeof(bool)));
					// PatternSet을 전처리하여 순위동형을 확인하는데 사용되는 phi_inverse, E 계산

					preprocessing_phi(pattern_1d, Pattern, phi, phi_inv, E, PatternCount, PatternLen);
 					// 각 패턴의 마지막 q그램을 계산하여 FingerPrint Table 생성

					preprocessing_table(Pattern, BlockSize, PatternCount, PatternLen, hash_Arr, inverse_hash_Arr);
 
					phi_inv_1d = new int[res];
					E_1d = new int[res];
					temp = 0;

					for (int i = 0; i < PatternCount; i++) {
						for (int j = 0; j < PatternLength[i]; j++) {
							phi_inv_1d[temp++] = phi_inv[i][j];
						}
					}

 					temp = 0;
					for (int i = 0; i < PatternCount; i++) {
						for (int j = 0; j < PatternLength[i]; j++) {
							E_1d[temp++] = E[i][j];
						}
					}

					HANDLE_ERROR(cudaMemcpy(dev_phi_inv, phi_inv_1d, res * sizeof(int), cudaMemcpyHostToDevice));
					HANDLE_ERROR(cudaMemcpy(dev_E, E_1d, res * sizeof(int), cudaMemcpyHostToDevice));
					HANDLE_ERROR(cudaMemcpy(dev_hash_Arr, hash_Arr, PatternCount * sizeof(int), cudaMemcpyHostToDevice));		
 
					SearchStart = clock();
					// 생성된 테이블로 Search 진행
					Search << < ((TextLen + 1023) / 1024), 1024 >> > (dev_match_count, dev_match, dev_text, dev_p, dev_hash_Arr, dev_phi_inv, dev_E, PatternCount, PatternLen, BlockSize, TextLen);
					SearchEnd = clock();
					cudaDeviceSynchronize(); 

					//매치된 결과를 host에 복사

					match = new bool[CopySize];
					match_count = new int[1];
					CopyToHostStart = clock();
					HANDLE_ERROR(cudaMemcpy(match_count, dev_match_count, 1 * sizeof(int), cudaMemcpyDeviceToHost));
					HANDLE_ERROR(cudaMemcpy(match, dev_match, CopySize * sizeof(bool), cudaMemcpyDeviceToHost));
					CopyToHostEnd= clock();
					
					cudaFree(dev_p);
					cudaFree(dev_E);
					cudaFree(dev_hash_Arr);
					cudaFree(dev_phi_inv);
					cudaFree(dev_text);
					cudaFree(dev_match_count);
					cudaFree(dev_match);

 					delete[] match;
					delete[] match_count;
					delete[] PatternLength;
					delete[] pattern_1d;
					delete[] E_1d;
					delete[] phi_inv_1d;
					delete[] hash_Arr;
					delete[] inverse_hash_Arr;

 					for (int i = 0; i < PatternCount; i++) {

						delete[] phi[i];

						delete[] phi_inv[i];

						delete[] E[i];

					}
					delete[] phi;
					delete[] phi_inv;
					delete[] E;
					for (int i = 0; i < PatternCount; i++) {

						delete[] Pattern[i];

					}
					delete[] Text;
					delete[] Pattern;

					TotalEnd = clock();
					PrintTestInfo(PatternCount, PatternLen,TextLen, match_count[0]);
					printf("Search Time : %fms\n",(double)(SearchEnd-SearchStart)/CLOCKS_PER_SEC);
					printf("Copy Time : %fms\n",(double)(CopyToHostEnd-CopyToHostStart)/CLOCKS_PER_SEC);
					printf("Total Time : %fms\n",(double)(TotalEnd-TotalStart)/CLOCKS_PER_SEC);
				}
			}

		}
	}
	}

	cout << endl;

	return 0;

}

 