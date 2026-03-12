#include <stdio.h>
#include <stdlib.h>

FILE *openFile(char *ruta) {
  FILE *file = fopen(ruta, "rb");
  if (file == NULL) {
    puts("wunzip: cannot open file");
    exit(1);
  }
  return file;
}

void decompress(FILE *file) {
  int count;
  char caracter;
  while (fread(&count, sizeof(int), 1, file) == 1 &&
         fread(&caracter, sizeof(char), 1, file) == 1) {
    for (int i = 0; i < count; i++) {
      printf("%c", caracter);
    }
  }
}

int main(int argc, char *argv[]) {
  if (argc <= 1) {
    puts("wunzip: file1 [file2 ...]");
    exit(1);
  }
  for (int i = 1; i < argc; i++) {
    FILE *file = openFile(argv[i]);
    decompress(file);
    fclose(file);
  }
  return 0;
}
