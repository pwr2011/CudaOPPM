#define _CRT_SECURE_NO_WARNINGS

#include <iostream>
#include <fstream>
#include <string>

using namespace std;

//#define TEXT_LEN	10000

int main()
{
	string FOLDER = "./Compare/";
	string temp1;
	string temp2;
	bool isCorrect = true;
	char fileName1[200];
	char fileName2[200];
	unsigned int i = 0;

	cout << "Result Comparator" << endl;
	for (int k = 10000; k <= 10000; k += 20000)
	{
		for (int j = 10; j <= 10; j++) {
			//sprintf(fileName1, "../../DeltaGammaApproximatePeriods/output_gamma_cpu_sorting_1000_%d.txt", k * 1000);
			//sprintf(fileName2, "../../DeltaGammaApproximatePeriodsCUDA/output_gamma_cuda_sorting_1000_%d.txt", k * 1000);
			//sprintf(fileName1, "FP_%d_%d.txt", k, j);
			//sprintf(fileName2, "FP_%d_%d_gpu.txt", k, j);
			sprintf(fileName1, "./Compare/check_cpu.txt");
			sprintf(fileName2, "./Compare/check_gpu.txt");

			cout << fileName1 << endl << fileName2 << endl;
			 
			ifstream fin1(fileName1, ios_base::in);
			ifstream fin2(fileName2, ios_base::in);

			if (!(fin1.is_open() && fin1.is_open())) {
				cout << "file don't open" << endl;
				return 0;
			}
			isCorrect = true;

			while (!(fin1.eof() && fin2.eof())) {
				fin1 >> temp1;
				fin2 >> temp2;

				//if(i == 11019380)
				//	continue;

				if (temp1 != temp2) {
					isCorrect = false;
					break;
				}
				i++;
			}

			if (isCorrect)
				cout << "Correct" << endl;
			else {
				cout << "Mismatch" << endl;
				cout << i << endl << i / 1001 << ", " << i % 1001 << endl;
				cout << "temp1 = " << temp1 << endl;
				cout << "temp2 = " << temp2 << endl;
			}

			fin1.close();
			fin2.close();
		}
	}

	return 0;
}