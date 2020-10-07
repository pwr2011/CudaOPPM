#define _CRT_SECURE_NO_WARNINGS
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <sys/time.h>
#include <iomanip>
#include <cmath>
#include <cstring>

using namespace std;
typedef pair<int, int> P;
int a = 0;
#define MAX_TEXT_SIZE 1'000'000
#define MAX_COUNT 2000
#define MAX_LEN 15
#define Repeat 100
//#define BLOCK_SIZE 3
//#define TEXT_SIZE 10000

#define min(a, b) a < b ? a : b
#define max(a, b) a < b ? b : a

// Set Files Name and Folder Name
string TC_FOLDER = "./Dow/";
string TEXT_FILE = "Dow_36000.txt";
string TIME_FOLDER = "./OriginalTIME/";
string OutputFolder = "./OriginalOUTPUT/TC-";
string PatternInput = "DowStr_";
int PreCalFac[10] = { 0, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880 };

void OutputData(int PatternCount, int PatternLen, int TextLen, int BlockSize, int FolderNumber, int MatchRes, bool *Match)
{
	string FileName = OutputFolder + to_string(FolderNumber) + "/" + PatternInput + "_" +
					  to_string(PatternCount) + "_" + to_string(PatternLen) + "_" + to_string(TextLen) + "_" + to_string(BlockSize) + ".txt";

	ofstream FileStream(FileName);
	FileStream << MatchRes;
	/*FileStream<<"\n";
	for(int t=0;t<TextLen; t++){
		FileStream<<Match[t]<<" ";
	}*/
	FileStream.close();
}
void OutputTime(double Pre, double Search, double Total, int PatternCount, int PatternLen, int TextLen, int BlockSize)
{
	string FileName = TIME_FOLDER + PatternInput +
					  to_string(PatternCount) + "_" + to_string(PatternLen) + "_" +
					  to_string(TextLen) + "_" + to_string(BlockSize) + ".txt";

	ofstream FileStream(FileName);
	FileStream << (double)(Pre) / Repeat << " " << (double)(Search) / Repeat << " " << (double)(Total) / Repeat;
	FileStream.close();
}

int** make_p_prime(int** p, int m, int PATTERN_COUNT)
{

	int** temp = new int* [PATTERN_COUNT];
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

int q_gram_H(int* p, int s_idx, int m, int q)
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
		result += count * PreCalFac[j - i];
	}

	ret = result;
	//}
	return ret;
}
void preprocessing_table(int** p, int B_size, int PATTERN_COUNT, int PATTERN_LEN, int* Hash_Arr)
{

	int m = PATTERN_LEN;
	int range = m - B_size + 1;
	int** p_prime = make_p_prime(p, m, PATTERN_COUNT);

	for (int i = 0; i < PATTERN_COUNT; i++)
	{
		Hash_Arr[i] = q_gram_H(p_prime[i], range - 1, m, B_size);
	}
	for (int i = 0; i < PATTERN_COUNT; i++)
		delete[] p_prime[i];
	delete[] p_prime;
}
int find_len(int* p, int PATTERN_LEN)
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
int find_max(int* p, int len)
{

	int ret = 0;

	for (int i = 0; i < len; i++)
	{
		if (p[i] > ret)
			ret = p[i];
	}

	return ret;
}
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
void make_phi(int* temp_p, int* p, int* phi, int len)
{

	int max_val = find_max(p, len);
	int* flag = new int[max_val + 1];
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
void make_phi_inv(int* phi, int* phi_inv, int len)
{

	for (int i = 0; i < len; i++)
	{
		phi_inv[phi[i]] = i;
	}
}
void make_E(int* p, int* phi_inv, int* E, int len)
{

	for (int i = 0; i < len - 1; i++)
	{
		if (p[phi_inv[i]] == p[phi_inv[i + 1]])
			E[i] = 1;
		else
			E[i] = 0;
	}
}
void MakeLoc(P* TempPattern, int* Loc, int Len, int PatternCount, int PatternLen, int CurPatternIdx) {
	for (int i = 0; i < Len; i++) {
		Loc[i] = TempPattern[i].second;
	}
}
void MakeE(int* Pattern, int* Loc, int* E, int Len, int PatternCount, int CurPatternIdx) {
	for (int i = 0; i < Len - 1; i++) {

		if (Pattern[Loc[i]] == Pattern[Loc[i + 1]])
			E[i] = 1;
		else
			E[i] = 0;
	}
}
void preprocessing_phi(int** p, int** phi, int** phi_inv, int** E, int PATTERN_COUNT, int PATTERN_LEN)
{ //����
	int Len;
	P* TempPattern;

	for (int i = 0; i < PATTERN_COUNT; i++) {
		Len = find_len(p[i], PATTERN_LEN);
		TempPattern = new P[Len];

		for (int j = 0; j < Len; j++) {
			TempPattern[j].first = p[i][j];
			TempPattern[j].second = j;
		}
		mergeSort(0, Len - 1, TempPattern);

		MakeLoc(TempPattern, phi_inv[i], Len, PATTERN_COUNT, PATTERN_LEN, i);

		MakeE(p[i], phi_inv[i], E[i], Len, PATTERN_COUNT, i);
		delete[] TempPattern;
	}
}

bool Check_OP(int* T, int* P, int s, int len, int* phi_inv, int* E)
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

void Search_H(int* match_count, bool* match, int* Text, int** p, int* Hash_Arr, int** phi_inv, int** E, int PATTERN_COUNT, int PATTERN_LEN, int BLOCK_SIZE, int TEXT_SIZE)
{

	int m = PATTERN_LEN;
	int q = BLOCK_SIZE;
	int start_idx = m - q;
	int s = 0;

	// start_idx
	// Fingerprint table

	while (start_idx <= TEXT_SIZE - q)
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
	struct timeval PreStart, PreEnd, SearchStart, SearchEnd, TotalStart, TotalEnd;
	int** PATTERN_SET;
	int** phi;
	int** phi_inv;
	int** E;
	int* TEXT;
	int* hash_Arr;

	bool* match;

	for (int BLOCK_SIZE = 7; BLOCK_SIZE <= 7; BLOCK_SIZE++)
	{
		for (int PATTERN_COUNT = 100; PATTERN_COUNT <= 1000; PATTERN_COUNT += 100)
		{
			for (int PATTERN_LEN = 7; PATTERN_LEN <= 15; PATTERN_LEN += 1)
			{
				printf("Pattern Count: %d\nPattern Len : %d\n", PATTERN_COUNT, PATTERN_LEN);
				for (int TEXT_SIZE = 3'000; TEXT_SIZE <= 36'000; TEXT_SIZE += 3'000)
				{
					double sec, usec;
					double TotalPre = 0;
					double TotalSearch = 0;
					double Total = 0;
					for (int FolderNumber = 0; FolderNumber < Repeat; FolderNumber++)
					{
						a = 0;

						// Read Pattern Information
						string pattern_filename = TC_FOLDER + PatternInput + to_string(PATTERN_COUNT) + "_" + to_string(PATTERN_LEN) + ".txt";
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
						string text_filename = TC_FOLDER + TEXT_FILE;
						ifstream text(text_filename);
						TEXT = new int[TEXT_SIZE];
						for (int i = 0; i < TEXT_SIZE; i++)
						{
							text >> TEXT[i];
						}
						text.close();
						/****************************************/

						// ��ó�� �ܰ迡�� ���� Array �ʱ�ȭ

						gettimeofday(&TotalStart, NULL);
						hash_Arr = new int[PATTERN_COUNT];
						phi = new int* [PATTERN_COUNT];
						phi_inv = new int* [PATTERN_COUNT];
						E = new int* [PATTERN_COUNT];
						for (int i = 0; i < PATTERN_COUNT; i++)
						{
							phi[i] = new int[PATTERN_LEN];
							phi_inv[i] = new int[PATTERN_LEN];
							E[i] = new int[PATTERN_LEN];
						}

						gettimeofday(&PreStart, NULL);
						// PatternSet
						preprocessing_phi(PATTERN_SET, phi, phi_inv, E, PATTERN_COUNT, PATTERN_LEN);

						// FingerPrint Table
						preprocessing_table(PATTERN_SET, BLOCK_SIZE, PATTERN_COUNT, PATTERN_LEN, hash_Arr);
						gettimeofday(&PreEnd, NULL);

						match = new bool[MAX_TEXT_SIZE];
						int* match_count = new int[1];
						match_count[0] = 0;

						memset(match, 0, MAX_TEXT_SIZE * sizeof(bool));
						gettimeofday(&SearchStart, NULL);
						Search_H(match_count, match, TEXT, PATTERN_SET, hash_Arr, phi_inv, E, PATTERN_COUNT, PATTERN_LEN, BLOCK_SIZE, TEXT_SIZE);
						gettimeofday(&SearchEnd, NULL);

						OutputData(PATTERN_COUNT, PATTERN_LEN, TEXT_SIZE, BLOCK_SIZE, FolderNumber, match_count[0], match);

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
						//PrintTestInfo(PATTERN_COUNT, PATTERN_LEN, TEXT_SIZE, match_count[0]);
					}
					OutputTime(TotalPre, TotalSearch, Total, PATTERN_COUNT, PATTERN_LEN, TEXT_SIZE, BLOCK_SIZE);
				}
			}
		}
	}
	return 0;
}
