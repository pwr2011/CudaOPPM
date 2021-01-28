#include "Journal_test.cu"
#include<cstring>
#include<stdio.h>
#include<utility>

using namespace std;

//Input Folder Name
string InputFolder = "./TESTCASE/";
string TextInput = "TextSample";
string PatternInput = "IntStr";

void InputData(int ** Pattern, int * Text, int PatternCount, int PatternLen, int TextLen){
	//Pattern input
	string pattern_filename = InputFolder +PatternInput + "_" + to_string(PatternCount) + "_" +to_string(PatternLen) + ".txt";
	ifstream pattern(pattern_filename);
	
	for (int i = 0; i < PatternCount; i++) {
    	for (int j = 0; j < PatternLen; j++) {
        	pattern >> Pattern[i][j];
		}
	}
	pattern.close();

	//Text input
	string text_filename = InputFolder + TextInput + "_" + to_string(TextLen) + ".txt";
	ifstream text(text_filename);

	for (int i = 0; i < TextLen; i++) {
		text >> Text[i];
	}
	text.close();
	return ;
}

int main(){
    int PatternCount =1000;
    int PatternLen = 8;
    int TextLen = 1000000;
    int ** Pattern;
    Pattern = new int*[PatternCount];
	for (int i = 0; i < PatternCount; i++) {
		Pattern[i] = new int[PatternLen];
	}
    int * Text = new int[TextLen];
    
    InputData(Pattern, Text, PatternCount,PatternLen,TextLen);
    pair<int,double> res = Do_Test_JH(Text, Pattern, TextLen, PatternLen, PatternCount);
    printf("match : %d time : %f\n",res.first, res.second);
    //(int* T, int** P, int TextLen, int PatternLen, int PatternCount)
}