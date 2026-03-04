#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

FILE *openFile(char *ruta) {
  FILE *file = fopen(ruta, "r");

  if (file == NULL) {
    puts("wgrep: cannot open file");
    exit(1);
  }

  return file;
}

void find(char *palabra, FILE *file) {
  char *line = NULL;
  size_t tam = 0;

  while (getline(&line, &tam, file) != -1) {
    if (strstr(line, palabra) != NULL) {
      printf("%s", line);
    }
  }
}

int main(int argc, char *argv[]) {
  if (argc <= 1) {
    puts("wgrep: searchterm [file ...]");
    exit(1);
  }

  if (argc == 2) {
    find(argv[1], stdin);
    return 0;
  }

  for (int i = 2; i < argc; i++) {
    FILE *file = openFile(argv[i]);
    find(argv[1], file);
  }

  return 0;
}
