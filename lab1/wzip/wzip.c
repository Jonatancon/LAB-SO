#include <stdio.h>
#include <stdlib.h>

FILE *openFile(char *ruta) {
  FILE *file = fopen(ruta, "rb");

  if (file == NULL) {
    puts("wzip: cannot open file");
    exit(1);
  }

  return file;
}

void readCharacter(FILE *file) {
  int c;
  int count = 1;
  int anterior = fgetc(file);

  if (anterior == EOF)
    return;

  while ((c = fgetc(file)) != EOF) {
    if (c == anterior) {
      count++;
    } else {
      fwrite(&count, sizeof(int), 1, stdout);
      fwrite(&anterior, sizeof(char), 1, stdout);
      count = 1;
      anterior = c;
    }
  }
  fwrite(&count, sizeof(int), 1, stdout);
  fwrite(&anterior, sizeof(char), 1, stdout);
}

int main(int argc, char *argv[]) {
  if (argc <= 1) {
    puts("wzip: file1 [file2 ...]");
    exit(1);
  }

  for (int i = 1; i < argc; i++) {
    FILE *file = openFile(argv[i]);
    readCharacter(file);
    fclose(file);
  }

  return 0;
}
