//============================================================================
// Name        : TestFileGenerator.cpp
// Author      : YHKim
// Version     :
// Copyright   : Your copyright notice
// Description : Hello World in C++, Ansi-style
//============================================================================
#define _CRT_SECURE_NO_WARNINGS
#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <time.h>
#include <string>

using namespace std;

#define BINARY_ALPHABET_SIZE 2
char BINARY_ALPHABET[BINARY_ALPHABET_SIZE] = {'0', '1'};

#define DNA_ALPHABET_SIZE 4
char DNA_ALPHABET[DNA_ALPHABET_SIZE] = {'A', 'C', 'G', 'T'};

#define QUIERY_ALPHABET_SIZE 5
char QUIERY_ALPHABET[QUIERY_ALPHABET_SIZE] = {'0', '1', '2', '3', '4'};

#define HEXA_ALPHABET_SIZE 6
char HEXA_ALPHABET[HEXA_ALPHABET_SIZE] = {'0', '1', '2', '3', '4', '5'};

// A, R, N, D, C, Q, E, G, H, I, L, K, M, F, P, S, T, W, Y, V
#define PROTEIN_ALPHABET_SIZE 20
//												 0    1    2    3    4    5    6    7    8    9    10  11    12   13   14  15    16   17   18  19
char PROTEIN_ALPHABET[PROTEIN_ALPHABET_SIZE] = {'A', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'Y'};

#define ENGLISH_ALPHABET_SIZE 26
char ENGLISH_ALPHABET[ENGLISH_ALPHABET_SIZE] = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'};

/*#define TEST_NUM 100	   //패턴 개수
#define STR_LEN 3 //패턴 길이
*/

#define TEST_NUM 1   //패턴 개수
#define STR_LEN 100'000 //패턴 길이

int main()
{
	int temp = 0;
	char text1_c[200];
	srand((unsigned)time(NULL));
	for (int number = 0; number <= 99; number++)
	{
		for (int e = 1; e <= 10; e += 1)
		{
			int strLen = e * STR_LEN;
			//int strLen = e + STR_LEN;
			for (int t = 1; t <= 1; t++)
			{
				int test_num = t * TEST_NUM;
				//sprintf(text1_c, "./TC-%d/IntStr_%d_%d.txt",number, test_num, strLen);
				sprintf(text1_c, "./TC-%d/TextSample_%d.txt", number, strLen);
				//sprintf(text1_c, "../inputDC_1000.txt", strLen);
				ofstream fout(text1_c, ios_base::out);

				//fout << TEST_NUM << " " << strLen << endl;	// �Է������� ù��° ���� ����

				for (int k = 0; k < test_num; k++) // test
				{
					for (int i = 0; i < strLen; i++)
					{
						temp = (rand() % 30000) + 1;
						//temp = rand();

						fout << temp << " ";
					}
					fout << endl;
				}
				fout.close();
			}
		}

		cout << "program end" << endl;
	}
	return 0;
}
