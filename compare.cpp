#include <iostream>
#include <cstring>
#include <fstream>
using namespace std;

int main()
{
    int match = 0;
    int notmatch = 0;

    for (int t = 0; t <= 99; t++)
    {
        for (int len = 3; len <= 15; len++)
        {
            for (int cou = 100; cou <= 1000; cou += 100)
            {
                for(int TextLen = 100'000;TextLen<=1'000'000;TextLen += 100'000){
                string journal = "./OriginalOUTPUT/TC-" + to_string(t) + "/IntStr_" + to_string(cou) + "_" +
                                 to_string(len) + "_" + to_string(TextLen) +".txt";

                string original = "./JournalV3OUTPUT/TC-" + to_string(t) + "/IntStr_" + to_string(cou) + "_" +
                                  to_string(len) +  "_" + to_string(TextLen) +".txt";

                ifstream j(journal);
                ifstream o(original);
                for (int i = 0; i <= 0; i++)
                {
                    
                    int A, B;
                    j >> A;
                    o >> B;
                    if (A != B)
                    {
                        notmatch++;
                    }
                    else
                    {
                        match++;
                    }
                }
            }
            }
        }
    }
    cout << "Match : " << match << "\nNotmatch : " << notmatch << "\n";
}