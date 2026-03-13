#include <stdio.h>
#include <stdlib.h>

FILE *openFile(char *ruta) {
  FILE *file = fopen(ruta, "r");

  //  printf("\nArchivo \" %s \" %s", ruta, file != NULL ? "ENCONTRADO \n" : "NO
  //  ENCONTRADO \n");

  if (file == NULL) {
    puts("wcat: cannot open file");
    exit(1);
  }

  return file;
}

void printFile(FILE *file) {
  char buffer[1024];

  //  puts("====================================================================");

  while (fgets(buffer, sizeof(buffer), file) != NULL) {
    printf("%s", buffer);
  }

  // puts("\n");

  //  puts("====================================================================\n");

  fclose(file);
}

int main(int argc, char *argv[]) {
  if (argc <= 1) {
    //    puts("No hay archivos para leer");
    return 0;
  }

  for (int i = 1; i < argc; i++) {
    FILE *nowFile = openFile(argv[i]);

    //    printf("Contenido de: %s \n", argv[i]);

    printFile(nowFile);
  }

  //  puts("Ejecucion completada");
  return 0;
}
