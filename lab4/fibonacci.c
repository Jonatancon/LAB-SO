#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

// Arreglo compartido + tamaño. main reserva con malloc, el hilo trabajador
// solo escribe; no hay carrera porque main no lee hasta después del join.
typedef struct {
  long long *seq;
  long n;
} FibArg;

// F(-2)=0, F(-1)=1 -> seq[0]=1, seq[1]=1, seq[i]=seq[i-1]+seq[i-2].
// (Con esta convención F(0)=1; la salida arranca 1 1 2 3 5...)
void *worker(void *arg) {
  FibArg *a = (FibArg *)arg;
  long n = a->n;
  long long *seq = a->seq;

  if (n >= 1)
    seq[0] = 1;
  if (n >= 2)
    seq[1] = 1;
  for (long i = 2; i < n; i += 1) {
    seq[i] = seq[i - 1] + seq[i - 2];
  }
  return NULL;
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    fprintf(stderr, "Uso: %s <N>\n", argv[0]);
    return 1;
  }

  long N = strtol(argv[1], NULL, 10);
  if (N <= 0) {
    fprintf(stderr, "N debe ser > 0\n");
    return 1;
  }

  long long *seq = malloc(N * sizeof(long long));
  if (!seq) {
    fprintf(stderr, "malloc falló\n");
    return 1;
  }

  FibArg arg = {.seq = seq, .n = N};
  pthread_t worker_thread;
  pthread_create(&worker_thread, NULL, worker, &arg);

  // Barrera: main no toca seq hasta confirmar que el trabajador terminó.
  pthread_join(worker_thread, NULL);

  for (long i = 0; i < N; i += 1) {
    printf("%lld ", seq[i]);
  }
  printf("\n");

  free(seq);
  return 0;
}
