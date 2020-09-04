#define _CRT_SECURE_NO_WARNINGS
#include<iostream>
#include<fstream>
#include<cstdlib>
#include<ctime>
#include<iomanip>
#include<cmath>
#include<cstring>

using namespace std;
int a = 0;
#define MAX_COUNT 2000
#define MAX_LEN 15
//#define BLOCK_SIZE 3
//#define TEXT_SIZE 10000

#define min(a,b) a<b?a:b
#define max(a,b) a<b?b:a

// Set Files Name and Folder Name
string TC_FOLDER = "./TESTCASE/TC-";
string TEXT_FILE = "TextSample";
string PATTERN_FILE = "IntStr";
string TIME_FOLDER = "./TIME/";
string OutputFolder = "./OriginalOUTPUT/TC-";
string PatternInput = "IntStr";

void OutputData(int PatternCount, int PatternLen, int TextLen, int FolderNumber,int MatchRes){
	string FileName = OutputFolder+ to_string(FolderNumber)+"/"+PatternInput + "_" +
	 to_string(PatternCount) + "_" +to_string(PatternLen) +"_"+to_string(TextLen) + ".txt";
	 
	ofstream FileStream(FileName);
	FileStream<<MatchRes;
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
void preprocessing_table(int** p, int B_size, int PATTERN_COUNT, int PATTERN_LEN, int* Hash_Arr, inv_H* inverse_Hash, int* check, int table_size) {

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
int find_len(int* p, int PATTERN_LEN) {

	int ret = PATTERN_LEN;
	for (int i = 0; i < PATTERN_LEN; i++) {
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
void preprocessing_phi(int** p, int** phi, int** phi_inv, int** E, int PATTERN_COUNT, int PATTERN_LEN) {//����
	int len;
	int* temp_arr;
	for (int i = 0; i < PATTERN_COUNT; i++) {

		len = find_len(p[i], PATTERN_LEN);
		temp_arr = new int[len];

		for (int j = 0; j < len; j++) {
			temp_arr[j] = p[i][j];
		}
		mergeSort(0, len - 1, temp_arr);
;
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
bool Check_OP(int* T, int* P, int s, int len, int* phi_inv, int* E) {

	bool ret = true;

	for (int i = 0; i < len - 1; i++) {
		
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
void Search_H(int* match_count, int* match, int* Text, int** p, int* Hash_Arr, int** phi_inv, int** E, int PATTERN_COUNT, int PATTERN_LEN, inv_H* inv_Hash, int* check, int table_size,int BLOCK_SIZE,int TEXT_SIZE) {

	int m = PATTERN_LEN;
	int q = BLOCK_SIZE;
	int start_idx = m - q;
	int s = 0;

	// start_idx 
	// Fingerprint table

	while (start_idx < TEXT_SIZE-q) { // -q

		int temp = q_gram_H(Text, start_idx, m, q);
		for (int i = 0; i < PATTERN_COUNT; i++) { //temp�� ��ġ��
			//match[TEXT_SIZE*i + (start_idx + q)] = Hash_Arr[i];
			if (temp == Hash_Arr[i]) {

				int P_len = find_len(p[i], PATTERN_LEN);
				
				if (Check_OP(Text, p[i], s, P_len, phi_inv[i], E[i])) {
					/*if(s == 49187){
						for(int tmp=s;tmp<s+PATTERN_LEN;tmp++){
							printf("%d ",Text[tmp]);
						}
						printf("\n");

						for(int tmp = 0; tmp<PATTERN_LEN;tmp++){
							printf("%d ",p[i][tmp]);
						}
						printf("\n");
				
					}*/
					match_count[0]+=1;
					//printf("Text idx : %d Pattern num : %d\n",s,i);
					//match[match_count[0]- 2] = i;
					//match[match_count[0]- 1] = start_idx+q;

				}
			}
		}
		start_idx++;
		s++;
	}
}

void PrintTestInfo(int PatternCount,int PatternLen,int TextLen, int MatchRes){
	printf("Pattern count: %d Pattern_length : %d TEXT SIZE : %d\nOP size : %d\n\n", PatternCount, PatternLen,TextLen, MatchRes);
}
int main() {
	int** PATTERN_SET;
	int** phi;
	int** phi_inv;
	int** E;
	int table_size;
	int* TEXT;
	int* hash_Arr;
	struct inv_H * inverse_hash_Arr;
	int* check_table;
	int* match;
	int TABLE_SIZE[10] = { 0, 0, 0, 6, 24, 120, 720, 5040, 40320, 362880 }; // Q : 3 ~ 9

	int T = 1;
	// PATTERN_COUNT : ���� ���� ( k )
	// PATTERN_LEN : ���� ���� ( m )
	for(int FolderNumber = 0;FolderNumber <=50;FolderNumber++){
	for (int BLOCK_SIZE = 3; BLOCK_SIZE <= 3; BLOCK_SIZE++) {
		for (int PATTERN_COUNT = 100; PATTERN_COUNT <= 1000; PATTERN_COUNT += 100) {
			for (int PATTERN_LEN = 3; PATTERN_LEN <= 15; PATTERN_LEN += 1) {
				for (int TEXT_SIZE = 50'000; TEXT_SIZE <= 50'000; TEXT_SIZE += 10'000) {
					for (int t = 0; t < T; t++) {
					a = 0;

					// Read Pattern Information
					string pattern_filename = TC_FOLDER  + to_string(FolderNumber)+"/"+ PATTERN_FILE + "_" + 
					to_string(PATTERN_COUNT) + "_" + to_string(PATTERN_LEN) + ".txt";
					ifstream pattern(pattern_filename);
					PATTERN_SET = new int*[PATTERN_COUNT];
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
					string text_filename = TC_FOLDER  + to_string(FolderNumber)+"/"+ TEXT_FILE
					+"_"+to_string(TEXT_SIZE)+".txt";
					ifstream text(text_filename);
					TEXT = new int[TEXT_SIZE];
					for (int i = 0; i < TEXT_SIZE; i++) {
						text >> TEXT[i];
					}
					text.close();
					/****************************************/

					// ��ó�� �ܰ迡�� ���� Array �ʱ�ȭ
					table_size = TABLE_SIZE[BLOCK_SIZE] + 1;
					hash_Arr = new int[PATTERN_COUNT];
					inverse_hash_Arr = new inv_H[PATTERN_COUNT];
					check_table = new int[table_size];
					for (int i = 0; i < table_size; i++)
						check_table[i] = 0;

					phi = new int *[PATTERN_COUNT];
					phi_inv = new int *[PATTERN_COUNT];
					E = new int *[PATTERN_COUNT];
					for (int i = 0; i < PATTERN_COUNT; i++)
					{
						phi[i] = new int[PATTERN_LEN];
						phi_inv[i] = new int[PATTERN_LEN];
						E[i] = new int[PATTERN_LEN];
					}

					// PatternSet
					preprocessing_phi(PATTERN_SET, phi, phi_inv, E, PATTERN_COUNT, PATTERN_LEN);

					/*for(int i=0;i<PATTERN_COUNT;i++){
						for(int j=0;j<PATTERN_LEN;j++){
							printf("%d\n",phi_inv[i][j]);
						}
					}*/
					// FingerPrint Table
					preprocessing_table(PATTERN_SET, BLOCK_SIZE, PATTERN_COUNT, PATTERN_LEN, hash_Arr, inverse_hash_Arr, check_table, table_size);

					/*for(int i=0;i<10;i++){
						printf("%d ",hash_Arr[i]);
					}
					printf("\n");*/

					//match = new int[10 * 1'000'000];
					int* match_count = new int[1];
					match_count[0] = 0;

					//memset(match, 0, 10 * 1'000'000 * sizeof(int));
					Search_H(match_count,match, TEXT, PATTERN_SET, hash_Arr, phi_inv, E, PATTERN_COUNT, PATTERN_LEN, inverse_hash_Arr, check_table, table_size, BLOCK_SIZE,TEXT_SIZE);
					
					OutputData(PATTERN_COUNT, PATTERN_LEN,TEXT_SIZE, FolderNumber,match_count[0] );

					/*for (int col = 0; col < PATTERN_COUNT; col++) {
						for (int row = 0; row < TEXT_SIZE; row++) {
							out_fp << (match[col*TEXT_SIZE+row]) << " ";
						}
						out_fp << "\n";
					}*/

					
					//delete[] match;
					delete[] hash_Arr;
					delete[] inverse_hash_Arr;
					delete[] check_table;
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
					delete[] TEXT;
					delete[] PATTERN_SET;
					PrintTestInfo(PATTERN_COUNT, PATTERN_LEN,TEXT_SIZE,match_count[0]);
					}
				}
			}
			cout << endl;
		}
	}
	}
	return 0;
	
}

//////////////////////////////////////////////////////////////////////////////////////