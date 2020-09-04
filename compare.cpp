#include<iostream>
#include<cstring>
#include<fstream>
using namespace std;

int main(){
                int match=0;
                int notmatch=0;

    for(int t=0;t<=2;t++){
        for(int len=3;len<=15;len++){
            for(int cou=100;cou<=1000;cou+=100){
                string journal = "./OUTPUT/TC-"+to_string(t)+"/IntStr_"+to_string(cou)+"_"+
                to_string(len)+"_50000.txt";

                string original = "./OriginalOUTPUT/TC-"+to_string(t)+"/IntStr_"+to_string(cou)+"_"+
                to_string(len)+"_50000.txt";
                
                ifstream j(journal);
                ifstream o(original);

                int A,B;
                j>>A; o>>B;
                if(A!=B){
                    notmatch++;
                }
                else{
                    match++;
                }
            }
        }

    }
    cout<<"Match : "<<match<<"\nNotmatch : "<<notmatch<<"\n";
}