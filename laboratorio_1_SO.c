#include <stdio.h>

int main() {
  char name[50];
  printf("Ingrese un nombre: ");
  scanf("%s", name);
  printf("Hola, %n! \n", name);
  return 0;
}
