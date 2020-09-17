#define _CRT_SECURE_NO_WARNINGS
#include "cuda_by_example/common/book.h"
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include<iostream>
#include<sys/time.h>
#include<fstream>
#include<cstdlib>
#include<ctime>
#include<iomanip>
#include<cmath>
#include<string>

using namespace std;
int a = 0;
#define MAX_COUNT 2000
#define MAX_LEN 20
#define Repeat 10
//#define BLOCK_SIZE 3
//#define TEXT_SIZE 1048575

#define min(a,b) a<b?a:b
#define max(a,b) a<b?b:a

string InputFolder = "./TESTCASE/TC-";
string OutputFolder = "./JournalV4OUTPUT/TC-";
string TimeFolder = "./JournalV4TIME/";
string TextInput = "TextSample";
string PatternInput = "IntStr";
string TimeInput = "TimeRecord_";

__constant__ int dev_phi_inv[16'000]; //MAX

void OutputData(int PatternCount, int PatternLen, int TextLen, int BlockSize, int FolderNumber, int MatchRes) {
	string FileName = OutputFolder + to_string(FolderNumber) + "/" + PatternInput + "_" +
		to_string(PatternCount) + "_" + to_string(PatternLen) + "_" + to_string(TextLen) + "_" + to_string(BlockSize) + ".txt";

	ofstream FileStream(FileName);
	FileStream << MatchRes;
	/*FileStream<<"\n";
	for(int t=0;t<TextLen; t++){
		FileStream<<MatchResDetail[t]<<" ";
	}*/
	FileStream.close();
}

void OutputTime(double Pre, float Search, double Total, double TotalCopy, int PatternCount, int PatternLen, int TextLen, int BlockSize) {
	string FileName = TimeFolder + PatternInput + "_" +
		to_string(PatternCount) + "_" + to_string(PatternLen) + "_" +
		to_string(TextLen) + "_" + to_string(BlockSize) + ".txt";

	ofstream FileStream(FileName);
	FileStream << (double)(Pre) / Repeat << " " << (double)(Search) / Repeat << " "
		<< (double)(Total) / Repeat << " " << (double)(TotalCopy) / Repeat;

	FileStream.close();
}


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
void make_phi(int* temp_p, int* p, int* phi, int len) { 

	int max_val = find_max(p, len);
	int* flag = new int[max_val + 1];
	for (int i = 0; i <= max_val; i++) {
		flag[i] = 0;
	}

	int temp;

	for (int i = 0; i < len; i++) {
		temp = p[i];
		for (int j = flag[temp]; j < len; j++) {
			if (temp_p[j] == temp) {
				flag[temp] = j + 1;
				phi[i] = j;
				break;
			}
		}
	}

	delete[]flag;
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
void preprocessing_phi(int** p, int** phi, int** phi_inv, int** E, int PATTERN_COUNT, int PATTERN_LEN) {

	int len;
	int* temp_arr;
	for (int i = 0; i < PATTERN_COUNT; i++) {

		len = find_len_H(p[i], PATTERN_LEN);
		temp_arr = new int[len];

		for (int j = 0; j < len; j++) {
			temp_arr[j] = p[i][j];
		}
		mergeSort(0, len - 1, temp_arr);

		make_phi(temp_arr, p[i], phi[i], len);

		make_phi_inv(phi[i], phi_inv[i], len);

		make_E(p[i], phi_inv[i], E[i], len);

		delete[]temp_arr;
	}
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
__device__ bool Check_OP(int* T, int arr_idx, int* P, int s, int len, int* E) {

	bool ret = true;
	for (int i = arr_idx; i < arr_idx + len - 1; i++) {

		if (E[i] == 0) {
			if (T[s + dev_phi_inv[i]] >= T[s + dev_phi_inv[i + 1]]) {
				ret = false;
				break;
			}
		}
		else {
			if (T[s + dev_phi_inv[i]] != T[s + dev_phi_inv[i + 1]]) {
				ret = false;
				break;
			}
		}
	}
	return ret;
}
__global__ void Search (int* match_count, int* match, int* Text, int* p, int* Hash_Arr, int* E, int PATTERN_COUNT, int PATTERN_LEN, int BLOCK_SIZE, int TEXT_SIZE) {
	int m = PATTERN_LEN;
	int q = BLOCK_SIZE;

	int bidx = blockIdx.x;
	int tidx = threadIdx.x;
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	int totalthreadsize = blockDim.x * gridDim.x;
	int threadPerTextlen = (TEXT_SIZE+totalthreadsize-1) / totalthreadsize;
	int start_idx = idx * threadPerTextlen; //Text start idx
	int end_idx = (idx + 1) *threadPerTextlen;//Text end idx �Ѵ� 
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
				if (Check_OP(Text,i*m, p, s, P_len, E)) {
					//match[TEXT_SIZE*i + start_idx + q]=1;
					atomicAdd(&match_count[0], 1);
					/*atomicExch(&(match[match_count[0] - 2]), i);
					atomicExch(&(match[match_count[0] - 1]), start_idx + q);*/
				}
			}
		}
		start_idx++;
		s++;
	}
	__syncthreads();
}

int main() {

	struct timeval PreStart, PreEnd, SearchStart, SearchEnd, TotalStart, TotalEnd, CopyToHostStart, CopyToHostEnd;

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

	// Calculated Table Size - �̸� ���� q!
	int TABLE_SIZE[10] = { 0, 0, 0, 6, 24, 120, 720, 5040, 40320, 362880 }; // Q : 3 ~ 9

	// Set Files Name and Folder Name
	string TC_FOLDER = "./TESTCASE/";
	string TEXT_FILE = "TextSample";
	string PATTERN_FILE = "IntStr";
	string TIME_FOLDER = "./TIME/";
	string TIME_FILE = "TimeRecord_";

	// PATTERN_COUNT : ���� ���� ( k )
	// PATTERN_LEN : ���� ���� ( m )

	for (int BLOCK_SIZE = 7; BLOCK_SIZE <= 7; BLOCK_SIZE++) {
		for (int PATTERN_COUNT = 100; PATTERN_COUNT <= 1'000; PATTERN_COUNT += 100) {
			for (int PATTERN_LEN = 7; PATTERN_LEN <= 15; PATTERN_LEN += 1) {
				printf("Pattern Count: %d\nPattern Len : %d\n",PATTERN_COUNT, PATTERN_LEN);
for (int TEXT_SIZE = 100'000; TEXT_SIZE <= 1'000'000; TEXT_SIZE += 100'000) {
					double sec, usec;
					double TotalPre = 0;
					double TotalSearch = 0;
					double Total = 0;
					double TotalCopy = 0;
					for (int FolderNumber = 0; FolderNumber < Repeat; FolderNumber++) {
						// Read Pattern Information - ���ϰ����� ���ϱ��̿� �°� ���� ���� ����
						string pattern_filename = InputFolder + to_string(FolderNumber) + "/" + PatternInput + "_" + to_string(PATTERN_COUNT) + "_" + to_string(PATTERN_LEN) + ".txt";

						ifstream pattern(pattern_filename);

						PATTERN_SET = new int* [PATTERN_COUNT];
						for (int i = 0; i < PATTERN_COUNT; i++) {
							PATTERN_SET[i] = new int[PATTERN_LEN];
						}
						for (int i = 0; i < PATTERN_COUNT; i++) {
							for (int j = 0; j < PATTERN_LEN; j++) {
								pattern >> PATTERN_SET[i][j];
							}
						}
						pattern.close();

						// Read Text Information - �ؽ�Ʈ ���� ����
						string text_filename = InputFolder + to_string(FolderNumber) + "/" + TextInput + "_" + to_string(TEXT_SIZE) + ".txt";
						ifstream text(text_filename);
						Text = new int[TEXT_SIZE];
						for (int i = 0; i < TEXT_SIZE; i++) {
							text >> Text[i];
						}
						text.close();
						/****************************************/

						// ��ó�� �ܰ迡�� ���� Array �ʱ�ȭ

						gettimeofday(&TotalStart, NULL);

						hash_Arr = new int[PATTERN_COUNT];
						inverse_hash_Arr = new inv_H[PATTERN_COUNT];
						phi = new int* [PATTERN_COUNT];
						phi_inv = new int* [PATTERN_COUNT];
						E = new int* [PATTERN_COUNT];

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

						/* GPU ������ */

						int* dev_text;
						int* dev_p;
						int* dev_hash_Arr;
						//int* dev_phi_inv;
						int* dev_E;
						int* dev_match;
						int* dev_match_count;

						//********************************** finger �� ��� *******************************************//

						HANDLE_ERROR(cudaMalloc((void**)&dev_p, res * sizeof(int)));//pattern
						HANDLE_ERROR(cudaMalloc((void**)&dev_text, TEXT_SIZE * sizeof(int)));
						//HANDLE_ERROR(cudaMalloc((void**)&dev_p_length, PATTERN_COUNT * sizeof(int)));
						HANDLE_ERROR(cudaMalloc((void**)&dev_hash_Arr, PATTERN_COUNT * sizeof(int)));
						//HANDLE_ERROR(cudaMalloc((void**)&dev_phi_inv, PATTERN_LEN * PATTERN_COUNT * sizeof(int)));//make 1d arr!
						HANDLE_ERROR(cudaMalloc((void**)&dev_E, res * sizeof(int)));
						HANDLE_ERROR(cudaMalloc((void**)&dev_match, 5 * 100'000 * sizeof(int)));
						HANDLE_ERROR(cudaMalloc((void**)&dev_match_count, 1 * sizeof(int)));

						//copy_stime = clock();
						HANDLE_ERROR(cudaMemcpy(dev_p, pattern_1d, res * sizeof(int), cudaMemcpyHostToDevice));
						HANDLE_ERROR(cudaMemcpy(dev_text, Text, TEXT_SIZE * sizeof(int), cudaMemcpyHostToDevice));
						HANDLE_ERROR(cudaMemset(dev_match_count, 0, 1 * sizeof(int)));
						HANDLE_ERROR(cudaMemset(dev_match, 0, 5 * 100'000 * sizeof(int)));
						// PatternSet�� ��ó���Ͽ� ���������� Ȯ���ϴµ� ���Ǵ� phi_inverse, E ���
						gettimeofday(&PreStart, NULL);
						preprocessing_phi(PATTERN_SET, phi, phi_inv, E, PATTERN_COUNT, PATTERN_LEN);

						// �� ������ ������ q�׷��� ����Ͽ� FingerPrint Table ����
						preprocessing_table(PATTERN_SET, BLOCK_SIZE, PATTERN_COUNT, PATTERN_LEN, hash_Arr, inverse_hash_Arr);
						gettimeofday(&PreEnd, NULL);

						phi_inv_1d = new int[PATTERN_LEN * PATTERN_COUNT];
						E_1d = new int[res];
						temp = 0;
						for (int i = 0; i < PATTERN_COUNT; i++) {
							for (int j = 0; j < PATTERN_LEN; j++) {
								phi_inv_1d[temp++] = phi_inv[i][j];
							}
						}

						temp = 0;
						for (int i = 0; i < PATTERN_COUNT; i++) {
							for (int j = 0; j < pattern_length[i]; j++) {
								E_1d[temp++] = E[i][j];
							}
						}
						//HANDLE_ERROR(cudaMemcpy(dev_phi_inv, phi_inv_1d, res * sizeof(int), cudaMemcpyHostToDevice));
						HANDLE_ERROR(cudaMemcpy(dev_E, E_1d, res * sizeof(int), cudaMemcpyHostToDevice));
						HANDLE_ERROR(cudaMemcpy(dev_hash_Arr, hash_Arr, PATTERN_COUNT * sizeof(int), cudaMemcpyHostToDevice));


						HANDLE_ERROR(cudaMemcpyToSymbol(dev_phi_inv, phi_inv_1d, PATTERN_COUNT * PATTERN_LEN * sizeof(int)));

						// ������ ���̺��� Search ����
						gettimeofday(&SearchStart, NULL);
						Search << < ((TEXT_SIZE + 1023) / 1024), 1024 >> > (dev_match_count, dev_match, dev_text, dev_p, dev_hash_Arr, dev_E, PATTERN_COUNT, PATTERN_LEN, BLOCK_SIZE, TEXT_SIZE);
						cudaDeviceSynchronize();

						gettimeofday(&SearchEnd, NULL);

						//��ġ�� ����� host�� ����
						match = new int[5 * 100'000];
						match_count = new int[1];
						HANDLE_ERROR(cudaMemcpy(match_count, dev_match_count, 1 * sizeof(int), cudaMemcpyDeviceToHost));
						HANDLE_ERROR(cudaMemcpy(match, dev_match, 5 * 100'000 * sizeof(int), cudaMemcpyDeviceToHost));

						int host_match_count = match_count[0];
						OutputData(PATTERN_COUNT, PATTERN_LEN, TEXT_SIZE, BLOCK_SIZE, FolderNumber, host_match_count);

						/*for (int col = 0; col < PATTERN_COUNT; col++) {
								for (int row = 0; row < TEXT_SIZE; row++) {
									out << (match[col*TEXT_SIZE + row]) << " ";
								}
								out << "\n";
						}*/

						gettimeofday(&TotalEnd, NULL);

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

						sec = TotalEnd.tv_sec - TotalStart.tv_sec;
						usec = TotalEnd.tv_usec - TotalStart.tv_usec;
						Total += (sec * 1000 + usec / 1000.0);

						sec = PreEnd.tv_sec - PreStart.tv_sec;
						usec = PreEnd.tv_usec - PreStart.tv_usec;
						TotalPre += (sec * 1000 + usec / 1000.0);

						sec = SearchEnd.tv_sec - SearchStart.tv_sec;
						usec = SearchEnd.tv_usec - SearchStart.tv_usec;
						TotalSearch += (sec * 1000 + usec / 1000.0);

						sec = CopyToHostEnd.tv_sec - CopyToHostStart.tv_sec;
						usec = CopyToHostEnd.tv_usec - CopyToHostStart.tv_usec;
						TotalCopy += (sec * 1000 + usec / 1000.0);
					}
					OutputTime(TotalPre, TotalSearch, Total, TotalCopy, PATTERN_COUNT, PATTERN_LEN, TEXT_SIZE, BLOCK_SIZE);
				}
			}
		}
	}
	cout << endl;
	return 0;
}

//////////////////////////////////////////////////////////////////////////////////////
