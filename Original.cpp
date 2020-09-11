#define _CRT_SECURE_NO_WARNINGS
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <ctime>
#include <iomanip>
#include <cmath>
#include <cstring>

using namespace std;
int a = 0;
#define MAX_TEXT_SIZE 1'000'000
#define MAX_COUNT 2000
#define MAX_LEN 15
//#define BLOCK_SIZE 3
//#define TEXT_SIZE 10000

#define min(a, b) a < b ? a : b
#define max(a, b) a < b ? b : a

// Set Files Name and Folder Name
string TC_FOLDER = "./TESTCASE/TC-";
string TEXT_FILE = "TextSample";
string PATTERN_FILE = "IntStr";
string TIME_FOLDER = "./OriginalTIME/TC-";
string OutputFolder = "./OriginalOUTPUT/TC-";
string PatternInput = "IntStr";

void OutputData(int PatternCount, int PatternLen, int TextLen, int FolderNumber, int MatchRes,bool *Match)
{
	string FileName = OutputFolder + to_string(FolderNumber) + "/" + PatternInput + "_" +
					  to_string(PatternCount) + "_" + to_string(PatternLen) + "_" + to_string(TextLen) + ".txt";

	ofstream FileStream(FileName);
	FileStream << MatchRes;
	/*FileStream<<"\n";
	for(int t=0;t<TextLen; t++){
		FileStream<<Match[t]<<" ";
	}*/
	FileStream.close();
}

void OutputTime(double Pre1, double Pre2, double Search, double Total, int PatternCount,int PatternLen, int TextLen, int FolderNumber ){
	string FileName = TIME_FOLDER + to_string(FolderNumber) + "/" + PatternInput + "_" +
					  to_string(PatternCount) + "_" + to_string(PatternLen) + "_" + to_string(TextLen) + ".txt";

	ofstream FileStream(FileName);
	FileStream<<(Pre1 / CLOCKS_PER_SEC)<<" "<<(Search/CLOCKS_PER_SEC)<<" "<<(Total/CLOCKS_PER_SEC);
	FileStream.close();
}

int **make_p_prime(int **p, int m, int PATTERN_COUNT)
{

	int **temp = new int *[PATTERN_COUNT];
	for (int i = 0; i < PATTERN_COUNT; i++)
	{
		temp[i] = new int[m];
	}

	for (int i = 0; i < PATTERN_COUNT; i++)
	{
		for (int j = 0; j < m; j++)
		{
			temp[i][j] = p[i][j];
		}
	}

	return temp;
}

int factorial(int n)
{
	return (n == 1 || n == 0) ? 1 : factorial(n - 1) * n;
}
int q_gram_H(int *p, int s_idx, int m, int q)
{

	//int size = m - q + 1;
	//int* ret = new int[size];
	int ret;
	int result;
	int count;

	//for (int i = 0; i < size; i++) {

	int i = s_idx;
	result = 0;

	for (int j = i; j < i + q; j++)
	{
		count = 0;
		for (int k = i; k < j; k++)
		{
			if (p[k] <= p[j])
				count++;
		}
		result += count * factorial(j - i);
	}

	ret = result;
	//}
	return ret;
}
void preprocessing_table(int **p, int B_size, int PATTERN_COUNT, int PATTERN_LEN, int *Hash_Arr)
{

	int m = PATTERN_LEN;
	int range = m - B_size + 1;
	int **p_prime = make_p_prime(p, m, PATTERN_COUNT);

	for (int i = 0; i < PATTERN_COUNT; i++)
	{
		Hash_Arr[i] = q_gram_H(p_prime[i], range - 1, m, B_size);
	}
	for (int i = 0; i < PATTERN_COUNT; i++)
		delete[] p_prime[i];
	delete[] p_prime;
}
int find_len(int *p, int PATTERN_LEN)
{

	int ret = PATTERN_LEN;
	for (int i = 0; i < PATTERN_LEN; i++)
	{
		if (p[i] < 0 || p[i] == 0)
		{
			ret = i;
			break;
		}
	}

	return ret;
}
int find_max(int *p, int len)
{

	int ret = 0;

	for (int i = 0; i < len; i++)
	{
		if (p[i] > ret)
			ret = p[i];
	}

	return ret;
}
void merge(int first, int mid, int last, int *arr)
{

	int idx = first;
	int temp_arr[MAX_COUNT];

	int i = first, j = mid + 1;

	while (i <= mid && j <= last)
	{
		if (arr[i] <= arr[j])
		{
			temp_arr[idx] = arr[i];
			idx++;
			i++;
		}
		else if (arr[i] > arr[j])
		{
			temp_arr[idx] = arr[j];
			idx++;
			j++;
		}
	}

	if (i > mid)
	{
		for (int m = j; m <= last; m++)
		{
			temp_arr[idx] = arr[m];
			idx++;
		}
	}
	else
	{
		for (int m = i; m <= mid; m++)
		{
			temp_arr[idx] = arr[m];
			idx++;
		}
	}

	for (int m = first; m <= last; m++)
	{
		arr[m] = temp_arr[m];
	}
}
void mergeSort(int first, int last, int *arr)
{

	if (first < last)
	{
		int mid = (first + last) / 2;
		mergeSort(first, mid, arr);
		mergeSort(mid + 1, last, arr);
		merge(first, mid, last, arr);
	}
}
void make_phi(int *temp_p, int *p, int *phi, int len)
{

	int max_val = find_max(p, len);
	int *flag = new int[max_val + 1];
	for (int i = 0; i <= max_val; i++)
	{
		flag[i] = 0;
	}

	int temp;

	for (int i = 0; i < len; i++)
	{
		temp = p[i];
		for (int j = flag[temp]; j < len; j++)
		{
			if (temp_p[j] == temp)
			{
				flag[temp] = j + 1;
				phi[i] = j;
				break;
			}
		}
	}

	delete[] flag;
}
void make_phi_inv(int *phi, int *phi_inv, int len)
{

	for (int i = 0; i < len; i++)
	{
		phi_inv[phi[i]] = i;
	}
}
void make_E(int *p, int *phi_inv, int *E, int len)
{

	for (int i = 0; i < len - 1; i++)
	{
		if (p[phi_inv[i]] == p[phi_inv[i + 1]])
			E[i] = 1;
		else
			E[i] = 0;
	}
}
void preprocessing_phi(int **p, int **phi, int **phi_inv, int **E, int PATTERN_COUNT, int PATTERN_LEN)
{ //����
	int len;
	int *temp_arr;
	for (int i = 0; i < PATTERN_COUNT; i++)
	{

		len = find_len(p[i], PATTERN_LEN);
		temp_arr = new int[len];

		for (int j = 0; j < len; j++)
		{
			temp_arr[j] = p[i][j];
		}
		mergeSort(0, len - 1, temp_arr);
		;
		make_phi(temp_arr, p[i], phi[i], len);

		make_phi_inv(phi[i], phi_inv[i], len);

		make_E(p[i], phi_inv[i], E[i], len);

		delete[] temp_arr;
	}
}

bool Check_OP(int *T, int *P, int s, int len, int *phi_inv, int *E)
{

	bool ret = true;

	for (int i = 0; i < len - 1; i++)
	{

		if (E[i] == 0)
		{
			if (T[s + phi_inv[i]] >= T[s + phi_inv[i + 1]])
			{
				ret = false;
				break;
			}
		}
		else
		{
			if (T[s + phi_inv[i]] != T[s + phi_inv[i + 1]])
			{
				ret = false;
				break;
			}
		}
	}
	return ret;
}

void Search_H(int *match_count, bool *match, int *Text, int **p, int *Hash_Arr, int **phi_inv, int **E, int PATTERN_COUNT, int PATTERN_LEN, int BLOCK_SIZE, int TEXT_SIZE)
{

	int m = PATTERN_LEN;
	int q = BLOCK_SIZE;
	int start_idx = m - q;
	int s = 0;

	// start_idx
	// Fingerprint table

	while (start_idx < TEXT_SIZE - q)
	{ 
		int temp = q_gram_H(Text, start_idx, m, q);
		for (int i = 0; i < PATTERN_COUNT; i++)
		{ //temp
			if (temp == Hash_Arr[i])
			{

				int P_len = find_len(p[i], PATTERN_LEN);

				if (Check_OP(Text, p[i], s, P_len, phi_inv[i], E[i]))
				{
					match_count[0] += 1;
					match[s] = 1;
				}
			}
		}
		start_idx++;
		s++;
	}
}

void PrintTestInfo(int PatternCount, int PatternLen, int TextLen, int MatchRes)
{
	printf("Pattern count: %d Pattern_length : %d TEXT SIZE : %d\nOP size : %d\n\n", PatternCount, PatternLen, TextLen, MatchRes);
}

int main()
{
	clock_t Pre1Start;
	clock_t Pre1End;
	clock_t Pre2Start;
	clock_t Pre2End;
	clock_t SearchStart;
	clock_t SearchEnd;
	clock_t TotalStart;
	clock_t TotalEnd;
	int **PATTERN_SET;
	int **phi;
	int **phi_inv;
	int **E;
	int *TEXT;
	int *hash_Arr;
	
	bool *match;

	int T = 1;
	for (int FolderNumber = 0; FolderNumber <= 99; FolderNumber++)
	{
		for (int BLOCK_SIZE = 3; BLOCK_SIZE <= 3; BLOCK_SIZE++)
		{
			for (int PATTERN_COUNT = 100; PATTERN_COUNT <= 1000; PATTERN_COUNT += 100)
			{
				for (int PATTERN_LEN = 3; PATTERN_LEN <= 15; PATTERN_LEN += 1)
				{
					for (int TEXT_SIZE = 100'000; TEXT_SIZE <= 1'000'000; TEXT_SIZE += 100'000)
					{
						for (int t = 0; t < T; t++)
						{
							a = 0;

							TotalStart = clock();
							// Read Pattern Information
							string pattern_filename = TC_FOLDER + to_string(FolderNumber) + "/" + PATTERN_FILE + "_" +
													  to_string(PATTERN_COUNT) + "_" + to_string(PATTERN_LEN) + ".txt";
							ifstream pattern(pattern_filename);
							PATTERN_SET = new int *[PATTERN_COUNT];
							for (int i = 0; i < PATTERN_COUNT; i++)
							{
								PATTERN_SET[i] = new int[PATTERN_LEN];
							}
							for (int i = 0; i < PATTERN_COUNT; i++)
							{
								for (int j = 0; j < PATTERN_LEN; j++)
								{
									pattern >> PATTERN_SET[i][j];
								}
							}
							pattern.close();

							// Read Text Information - �ؽ�Ʈ ���� ����
							string text_filename = TC_FOLDER + to_string(FolderNumber) + "/" + TEXT_FILE + "_" + to_string(TEXT_SIZE) + ".txt";
							ifstream text(text_filename);
							TEXT = new int[TEXT_SIZE];
							for (int i = 0; i < TEXT_SIZE; i++)
							{
								text >> TEXT[i];
							}
							text.close();
							/****************************************/

							// ��ó�� �ܰ迡�� ���� Array �ʱ�ȭ
							hash_Arr = new int[PATTERN_COUNT];
							phi = new int *[PATTERN_COUNT];
							phi_inv = new int *[PATTERN_COUNT];
							E = new int *[PATTERN_COUNT];
							for (int i = 0; i < PATTERN_COUNT; i++)
							{
								phi[i] = new int[PATTERN_LEN];
								phi_inv[i] = new int[PATTERN_LEN];
								E[i] = new int[PATTERN_LEN];
							}

							Pre1Start = clock();
							// PatternSet
							preprocessing_phi(PATTERN_SET, phi, phi_inv, E, PATTERN_COUNT, PATTERN_LEN);
							Pre1End = clock();

							// FingerPrint Table
							Pre2Start = clock();
							preprocessing_table(PATTERN_SET, BLOCK_SIZE, PATTERN_COUNT, PATTERN_LEN, hash_Arr);
							Pre2End = clock();

							match = new bool[MAX_TEXT_SIZE];
							int *match_count = new int[1];
							match_count[0] = 0;

							memset(match, 0, MAX_TEXT_SIZE * sizeof(bool));
							SearchStart = clock();
							Search_H(match_count, match, TEXT, PATTERN_SET, hash_Arr, phi_inv, E, PATTERN_COUNT, PATTERN_LEN, BLOCK_SIZE, TEXT_SIZE);
							SearchEnd = clock();

							OutputData(PATTERN_COUNT, PATTERN_LEN, TEXT_SIZE, FolderNumber, match_count[0], match);

							/*for (int col = 0; col < PATTERN_COUNT; col++) {
						for (int row = 0; row < TEXT_SIZE; row++) {
							out_fp << (match[col*TEXT_SIZE+row]) << " ";
						}
						out_fp << "\n";
					}*/

							//printf("Time : %f\n", (double)(SearchEnd - SearchStart) / CLOCKS_PER_SEC);
							delete[] match;
							delete[] hash_Arr;
							for (int i = 0; i < PATTERN_COUNT; i++)
							{
								delete[] phi[i];
								delete[] phi_inv[i];
								delete[] E[i];
							}
							delete[] phi;
							delete[] phi_inv;
							delete[] E;

							for (int i = 0; i < PATTERN_COUNT; i++)
							{
								delete[] PATTERN_SET[i];
							}
							delete[] TEXT;
							delete[] PATTERN_SET;
							TotalEnd = clock();
							OutputTime(Pre1End-Pre1Start, Pre2End-Pre2Start, SearchEnd- SearchStart, TotalEnd-TotalStart,
							PATTERN_COUNT,PATTERN_LEN, TEXT_SIZE, FolderNumber);
							PrintTestInfo(PATTERN_COUNT, PATTERN_LEN, TEXT_SIZE, match_count[0]);
						}
					}
				}
				cout << endl;
			}
		}
	}
	return 0;
}