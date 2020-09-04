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

//#define BLOCK_SIZE 3

//#define TEXT_SIZE 1048575

 

#define min(a,b) a<b?a:b

#define max(a,b) a<b?b:a

 

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

 

int** make_p_prime(int** p, int m, int PATTERN_COUNT) {

 

	int** temp = new int*[PATTERN_COUNT];

	for (int i = 0; i < PATTERN_COUNT; i++) {

		temp[i] = new int[m];

	}

 

	for (int i = 0; i < PATTERN_COUNT; i++) {

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

void preprocessing_table(int** p, int B_size, int PATTERN_COUNT, int PATTERN_LEN, int* Hash_Arr, inv_H* inverse_Hash) {

 

	int m = PATTERN_LEN;

	int range = m - B_size + 1;

	int** p_prime = make_p_prime(p, m, PATTERN_COUNT);

 

	for (int i = 0; i < PATTERN_COUNT; i++) {

		Hash_Arr[i] = q_gram_H(p_prime[i], range - 1, m, B_size);

	}

	for (int i = 0; i < PATTERN_COUNT; i++)

		delete[] p_prime[i];

	delete[] p_prime;

}

 

int find_len_H(int* p, int PATTERN_LEN) {

 

	int ret = PATTERN_LEN;

	for (int i = 0; i < PATTERN_LEN; i++) {

		if (p[i] < 0 || p[i] == 0) {

			ret = i;

			break;

		}

	}

 

	return ret;

}

 

__device__ int find_len(int* p, int arr_idx, int PATTERN_LEN) {

 

	int ret = PATTERN_LEN;

	for (int i = arr_idx; i < PATTERN_LEN + arr_idx; i++) {

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

__global__ void make_phi(int* temp_p_1d, int* p_1d, int* phi_1d, int len, int PATTERN_COUNT) {

	//temp_p_1d 가 정렬되어있는것임

	//하나의 스레드가 하나의 파이 만든다

	int idx = blockDim.x*blockIdx.x + threadIdx.x;

	int arr_idx = idx * len;

 

	if (idx <PATTERN_COUNT) {

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

 

void preprocessing_phi(int* pattern_1d, int** p, int** phi, int** phi_inv, int** E, int PATTERN_COUNT, int PATTERN_LEN) {

	//string FOLDER = "./OUTPUT/";

	//string FILENAME = "out.txt";

	int* temp_pattern_1d = new int[PATTERN_COUNT * PATTERN_LEN];

	int* temp_arr = new int[PATTERN_LEN];

	int* phi_1d = new int[PATTERN_COUNT *PATTERN_LEN];

 

	//global 함수//

	int* dev_pattern_1d;

	int* dev_temp_pattern_1d;

	int* dev_phi_1d;

	//gpu 메모리 할당//

	HANDLE_ERROR(cudaMalloc((void**)&dev_pattern_1d, PATTERN_COUNT * PATTERN_LEN * sizeof(int)));

	HANDLE_ERROR(cudaMalloc((void**)&dev_temp_pattern_1d, PATTERN_COUNT * PATTERN_LEN * sizeof(int)));

	HANDLE_ERROR(cudaMalloc((void**)&dev_phi_1d, PATTERN_COUNT * PATTERN_LEN * sizeof(int)));

 

	for (int i = 0; i < PATTERN_COUNT; i++) {

		for (int j = 0; j < PATTERN_LEN; j++) {

			temp_arr[j] = pattern_1d[i*PATTERN_LEN+j];

		}

		mergeSort(0, PATTERN_LEN - 1, temp_arr);

 

		for (int j = 0; j < PATTERN_LEN; j++) {

			temp_pattern_1d[i*PATTERN_LEN + j] = temp_arr[j];

		}

	}

 

	HANDLE_ERROR(cudaMemcpy(dev_pattern_1d, pattern_1d, PATTERN_COUNT * PATTERN_LEN * sizeof(int), cudaMemcpyHostToDevice));

	HANDLE_ERROR(cudaMemcpy(dev_temp_pattern_1d, temp_pattern_1d, PATTERN_COUNT * PATTERN_LEN * sizeof(int),cudaMemcpyHostToDevice));

 

	make_phi << <(PATTERN_COUNT + 127) / 128, 128 >> > (dev_temp_pattern_1d, dev_pattern_1d, dev_phi_1d, PATTERN_LEN, PATTERN_COUNT);

	cudaThreadSynchronize();

	HANDLE_ERROR(cudaMemcpy(phi_1d, dev_phi_1d, PATTERN_COUNT * PATTERN_LEN * sizeof(int), cudaMemcpyDeviceToHost));

 

	for (int i = 0; i < PATTERN_COUNT; i++) {
		make_phi
		for (int j = 0; j < PATTERN_LEN; j++) {

			phi[i][j] = phi_1d[i*PATTERN_LEN + j];

		}

	}

	

	for (int i = 0; i < PATTERN_COUNT; i++) {

 

		make_phi_inv(phi[i], phi_inv[i], PATTERN_LEN);

		make_E(p[i], phi_inv[i], E[i], PATTERN_LEN);

 

	}

	cudaFree(dev_pattern_1d);

	cudaFree(dev_phi_1d);

	cudaFree(dev_temp_pattern_1d);

	delete[] phi_1d;

	delete[] temp_pattern_1d;

	cout << "preprocessing 1d : " << ee - ss << endl;

	cout << "preprocessing phi_inv, E : " << e - s << endl;

 

	/*string output = FOLDER + FILENAME;

	ofstream out(output);

	for (int i = 0; i < PATTERN_COUNT; i++) {

		for (int j = 0; j < PATTERN_LEN; j++) {

			out << phi_1d[i*PATTERN_LEN + j] << " ";

		}

		out << "\n";

	}

	out.close();*/

 

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

__global__ void Search (int* match_count, int* match, int* Text, int* p, int* Hash_Arr, int* phi_inv, int* E, int PATTERN_COUNT, int PATTERN_LEN, int BLOCK_SIZE, int TEXT_SIZE) {

	int m = PATTERN_LEN;

	int q = BLOCK_SIZE;

 

	int bidx = blockIdx.x;

	int tidx = threadIdx.x;

	int idx = blockIdx.x * blockDim.x + threadIdx.x;

	int totalthreadsize = blockDim.x * gridDim.x;

	int threadPerTextlen = (TEXT_SIZE+totalthreadsize-1) / totalthreadsize;

	int start_idx = idx * threadPerTextlen; //Text start idx

	int end_idx = (idx + 1) *threadPerTextlen;//Text end idx 둘다 

	int s = start_idx-(m-q);

	 

	while (start_idx < end_idx) {

		if (start_idx < m - q) {

			start_idx++;

			continue;

		}

		if (start_idx >= TEXT_SIZE - q) {

			break;

		}

		 

		int temp = q_gram(Text, start_idx, m, q);

		for (int i = 0; i < PATTERN_COUNT; i++) {

			if (temp == Hash_Arr[i]) {

				int P_len = find_len(p,i*m, PATTERN_LEN);

				if (Check_OP(Text,i*m, p, s, P_len, phi_inv, E)) {

					//match[TEXT_SIZE*i + start_idx + q]=1;

					atomicAdd(&match_count[0], 2);

					atomicExch(&(match[match_count[0] - 2]), i);

					atomicExch(&(match[match_count[0] - 1]), start_idx + q);

				}

			}

		}

		start_idx++;

		s++;

	}

	__syncthreads();

}

 

int main() {

 

	clock_t makephi_stime, makephi_etime;

	clock_t maketable_stime, maketable_etime;

	clock_t search_stime, search_etime;

	clock_t total_stime, total_etime;

 

	int** PATTERN_SET;

	int* pattern_1d;

	int* pattern_length;

	int** phi;

	int** phi_inv;

	int* phi_inv_1d;

	int** E;

	int* E_1d;

	int* Text;

	int* hash_Arr;

	int* match;

	int* match_count;

	struct inv_H * inverse_hash_Arr;

 

	// Calculated Table Size - 미리 계산된 q!

	int TABLE_SIZE[10] = { 0, 0, 0, 6, 24, 120, 720, 5040, 40320, 362880 }; // Q : 3 ~ 9

 

	// Set Files Name and Folder Name

	string TC_FOLDER = "./TESTCASE/";

	string TEXT_FILE = "TextSample";

	string PATTERN_FILE = "IntStr";

	string TIME_FOLDER = "./TIME/";

	string TIME_FILE = "TimeRecord_";

	string check = "check";

 

	// PATTERN_COUNT : 패턴 개수 ( k )

	// PATTERN_LEN : 패턴 길이 ( m )

 

	string time_filename = TIME_FOLDER + check + ".txt";

	ofstream out(time_filename);

 

	for (int BLOCK_SIZE = 5; BLOCK_SIZE <= 5; BLOCK_SIZE++) {

		for (int PATTERN_COUNT = 1'000; PATTERN_COUNT <= 5'000; PATTERN_COUNT += 1'000) {

			for (int PATTERN_LEN = 6; PATTERN_LEN <= 10; PATTERN_LEN += 1) {

				for (int TEXT_SIZE = 10'000; TEXT_SIZE <= 50'000; TEXT_SIZE += 10'000) {

					double phi_time = 0;

					double search_time = 0;

					double maketable_time = 0;

					double total_time = 0;

 

					// Read Pattern Information - 패턴개수와 패턴길이에 맞게 패턴 파일 읽음

					string pattern_filename = TC_FOLDER + PATTERN_FILE + "_" + to_string(PATTERN_COUNT) + "_" + to_string(PATTERN_LEN) + ".txt";

					ifstream pattern(pattern_filename);

 

					PATTERN_SET = new int*[PATTERN_COUNT

					];

					for (int i = 0; i < PATTERN_COUNT; i++) {

						PATTERN_SET[i] = new int[PATTERN_LEN];

					}

					for (int i = 0; i < PATTERN_COUNT; i++) {

						for (int j = 0; j < PATTERN_LEN; j++) {

							pattern >> PATTERN_SET[i][j];

						}

					}

					pattern.close();

 

					// Read Text Information - 텍스트 파일 읽음

					string text_filename = TC_FOLDER + TEXT_FILE + "_" + to_string(TEXT_SIZE) + ".txt";

					ifstream text(text_filename);

					Text = new int[TEXT_SIZE];

					for (int i = 0; i < TEXT_SIZE; i++) {

						text >> Text[i];

					}

					text.close();

					/****************************************/

 

					// 전처리 단계에서 사용될 Array 초기화

 

					total_stime = clock();

 

					hash_Arr = new int[PATTERN_COUNT];

					inverse_hash_Arr = new inv_H[PATTERN_COUNT];

					phi = new int *[PATTERN_COUNT];

					phi_inv = new int *[PATTERN_COUNT];

					E = new int *[PATTERN_COUNT];

 

					pattern_length = new int[PATTERN_COUNT];

					for (int i = 0; i < PATTERN_COUNT; i++) {

						pattern_length[i] = PATTERN_LEN;

					}

 

					int res = 0;

 

					for (int i = 0; i < PATTERN_COUNT; i++)

					{

						res += pattern_length[i];

						phi[i] = new int[PATTERN_LEN];

						phi_inv[i] = new int[PATTERN_LEN];

						E[i] = new int[PATTERN_LEN];

					}

					pattern_1d = new int[res];

 

					int temp = 0;

					for (int i = 0; i < PATTERN_COUNT; i++) {

						for (int j = 0; j < pattern_length[i]; j++) {

							pattern_1d[temp++] = PATTERN_SET[i][j];

						}

					}

 

					/* GPU 변수들 */

 

					int* dev_text;

					int* dev_p;

					int* dev_hash_Arr;

					int* dev_phi_inv;

					int* dev_E;

					int* dev_match;

					int* dev_match_count; 

 

					//********************************** finger 값 계산 *******************************************//

 

					HANDLE_ERROR(cudaMalloc((void**)&dev_p, res * sizeof(int)));//pattern

					HANDLE_ERROR(cudaMalloc((void**)&dev_text, TEXT_SIZE * sizeof(int)));

					//HANDLE_ERROR(cudaMalloc((void**)&dev_p_length, PATTERN_COUNT * sizeof(int)));

					HANDLE_ERROR(cudaMalloc((void**)&dev_hash_Arr, PATTERN_COUNT * sizeof(int)));

					HANDLE_ERROR(cudaMalloc((void**)&dev_phi_inv, res * sizeof(int)));//make 1d arr!

					HANDLE_ERROR(cudaMalloc((void**)&dev_E, res * sizeof(int)));

					HANDLE_ERROR(cudaMalloc((void**)&dev_match, 5 * 1'000'000 * sizeof(int)));

					HANDLE_ERROR(cudaMalloc((void**)&dev_match_count, 1 * sizeof(int)));

 

					//copy_stime = clock();

					HANDLE_ERROR(cudaMemcpy(dev_p, pattern_1d, res * sizeof(int), cudaMemcpyHostToDevice));

					HANDLE_ERROR(cudaMemcpy(dev_text, Text, TEXT_SIZE * sizeof(int), cudaMemcpyHostToDevice));

					HANDLE_ERROR(cudaMemset(dev_match_count, 0, 1 * sizeof(int)));

					HANDLE_ERROR(cudaMemset(dev_match, 0, 5*1'000'000 * sizeof(int)));

					// PatternSet을 전처리하여 순위동형을 확인하는데 사용되는 phi_inverse, E 계산

					makephi_stime = clock();

					preprocessing_phi(pattern_1d, PATTERN_SET, phi, phi_inv, E, PATTERN_COUNT, PATTERN_LEN);

					makephi_etime = clock();

 

					// 각 패턴의 마지막 q그램을 계산하여 FingerPrint Table 생성

					maketable_stime = clock();

					preprocessing_table(PATTERN_SET, BLOCK_SIZE, PATTERN_COUNT, PATTERN_LEN, hash_Arr, inverse_hash_Arr);

					maketable_etime = clock();

 

					phi_inv_1d = new int[res];

					E_1d = new int[res];

					temp = 0;

					for (int i = 0; i < PATTERN_COUNT; i++) {

						for (int j = 0; j < pattern_length[i]; j++) {

							phi_inv_1d[temp++] = phi_inv[i][j];

						}

					}

 

					temp = 0;

					for (int i = 0; i < PATTERN_COUNT; i++) {

						for (int j = 0; j < pattern_length[i]; j++) {

							E_1d[temp++] = E[i][j];

						}

					}

					HANDLE_ERROR(cudaMemcpy(dev_phi_inv, phi_inv_1d, res * sizeof(int), cudaMemcpyHostToDevice));

					HANDLE_ERROR(cudaMemcpy(dev_E, E_1d, res * sizeof(int), cudaMemcpyHostToDevice));

					HANDLE_ERROR(cudaMemcpy(dev_hash_Arr, hash_Arr, PATTERN_COUNT * sizeof(int), cudaMemcpyHostToDevice));

 

					

 

					// 생성된 테이블로 Search 진행

					search_stime = clock();

					Search << < ((TEXT_SIZE + 1023) / 1024), 1024 >> > (dev_match_count, dev_match, dev_text, dev_p, dev_hash_Arr, dev_phi_inv, dev_E, PATTERN_COUNT, PATTERN_LEN, BLOCK_SIZE, TEXT_SIZE);

					cudaThreadSynchronize();

					search_etime = clock();

 

					//매치된 결과를 host에 복사

					match = new int[5 * 1'000'000];

					match_count = new int[1];

					HANDLE_ERROR(cudaMemcpy(match_count, dev_match_count, 1 * sizeof(int), cudaMemcpyDeviceToHost));

					HANDLE_ERROR(cudaMemcpy(match, dev_match, 5 * 1'000'000 * sizeof(int), cudaMemcpyDeviceToHost));

					

					int host_match_count = match_count[0];

					out << match_count[0] << "\n";

 

					/*for (int col = 0; col < PATTERN_COUNT; col++) {

							for (int row = 0; row < PATTERN_LEN; row++) {

								out <<phi[col][row] << " ";

							}

							out << "\n";

					}*/

 

					total_etime = clock();

 

					cudaFree(dev_p);

					cudaFree(dev_E);

					cudaFree(dev_hash_Arr);

					cudaFree(dev_phi_inv);

					cudaFree(dev_text);

					cudaFree(dev_match_count);

					cudaFree(dev_match);

 

					delete[] match;

					delete[] match_count;

					delete[] pattern_length;

					delete[] pattern_1d;

					delete[] E_1d;

					delete[] phi_inv_1d;

					delete[] hash_Arr;

					delete[] inverse_hash_Arr;

 

					for (int i = 0; i < PATTERN_COUNT; i++) {

						delete[] phi[i];

						delete[] phi_inv[i];

						delete[] E[i];

					}

					delete[] phi;

					delete[] phi_inv;

					delete[] E;

 

					for (int i = 0; i < PATTERN_COUNT; i++) {

						delete[] PATTERN_SET[i];

					}

					delete[] Text;

					delete[] PATTERN_SET;

 

					printf("Pattern count: %d Pattern_length : %d\n TEXT SIZE : %d\n", PATTERN_COUNT, PATTERN_LEN, TEXT_SIZE);

					printf("Make PI Time : %3.10f ms\n", (float)makephi_etime - makephi_stime);

					printf("Search Time : %3.10f ms\n", (float)search_etime - search_stime);

					printf("Table Time : %3.10f ms\n", (float)maketable_etime - maketable_stime);

					printf("Total TIme : %3.10f ms\n\n", (float)total_etime - total_stime);

				}

			}

		}

	}

	cout << endl;

	return 0;

}

 