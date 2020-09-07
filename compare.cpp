#include <iostream>
#include <cstring>
#include <fstream>
using namespace std;

int main()
{
    int match = 0;
    int notmatch = 0;

    for (int t = 0; t <= 2; t++)
    {
        for (int len = 3; len <= 15; len++)
        {
            for (int cou = 100; cou <= 1000; cou += 100)
            {
                string journal = "./JournalOUTPUT/TC-" + to_string(t) + "/IntStr_" + to_string(cou) + "_" +
                                 to_string(len) + "_50000.txt";

                string original = "./OriginalOUTPUT/TC-" + to_string(t) + "/IntStr_" + to_string(cou) + "_" +
                                  to_string(len) + "_50000.txt";

                ifstream j(journal);
                ifstream o(original);
                for (int i = 0; i <= 50'000; i++)
                {
                    
                    int A, B;
                    j >> A;
                    o >> B;
                    if(i==2){
                        cout<<"i = 2:"<<A<<" "<<B<<"\n";
                    }
                    if(i==3){
                        cout<<"i = 3:"<<A<<" "<<B<<"\n";
                    }
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
    cout << "Match : " << match << "\nNotmatch : " << notmatch << "\n";
}