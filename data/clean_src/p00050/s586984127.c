#include <stdio.h>
void convert(char stc[], int len);
void convertapp(char stc[], int from);
void convertpea(char str[], int from);
int appsearch(char str[], int from);
int peasearch(char str[], int from);

int main(int argc, const char * argv[])
{
    char stc[1050];
    int len = 0;
    int k;

    while (1) {
        stc[len] = getchar();
        if (stc[len] == '\n') break;
        len++;
    }
    convert(stc, len);
    for (k = 0; k < len; k++) {
        printf("%c", stc[k]);
    }
    puts("");
    return 0;
}

void convert(char stc[], int len){
    int i;
    for (i = 0; i < len; i++) {
        if (appsearch(stc, i)) {
            convertpea(stc, i);
            i += 5;
        }
        else if (peasearch(stc, i)) {
            convertapp(stc, i);
            i += 5;
        }
    }
}

int appsearch(char stc[], int i){
    if (stc[i] == 'a') {
        if (stc[i + 1] == 'p') {
            if (stc[i + 2] == 'p') {
                if (stc[i + 3] == 'l') {
                    if (stc[i + 4] == 'e') {
                        return 1;
                    }
                }
            }
        }
    }
    return 0;
}

int peasearch(char stc[], int i){
    if (stc[i] == 'p') {
        if (stc[i + 1] == 'e') {
            if (stc[i + 2] == 'a') {
                if (stc[i + 3] == 'c') {
                    if (stc[i + 4] == 'h') {
                        return 1;
                    }
                }
            }
        }
    }
    return 0;
}

void convertpea(char stc[], int i){
    stc[i] = 'p';
    stc[i + 1] = 'e';
    stc[i + 2] = 'a';
    stc[i + 3] = 'c';
    stc[i + 4] = 'h';
    return;
}
void convertapp(char stc[], int i){
    stc[i] = 'a';
    stc[i + 1] = 'p';
    stc[i + 2] = 'p';
    stc[i + 3] = 'l';
    stc[i + 4] = 'e';
    return;
}