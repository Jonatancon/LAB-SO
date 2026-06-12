#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

static inline double f(double x) { return 4.0 / (1.0 + x * x); }

double GetTime(void) {
  struct timeval t;
  gettimeofday(&t, NULL);
  return t.tv_sec + t.tv_usec * 1e-6;
}

// Argumentos por hilo: su sub-rango [start, end) y fH compartido.
// El resultado parcial se retorna vía pthread_exit (puntero a double),
// no se escribe en memoria compartida -> sin mutex, sin contención.
typedef struct {
  long start;
  long end;
  double fH;
} ThreadArg;

void *worker(void *arg) {
  ThreadArg *a = (ThreadArg *)arg;
  double *partial = malloc(sizeof(double)); // liberado por main tras join
  double sum = 0.0;

  for (long i = a->start; i < a->end; i += 1) {
    double fX = a->fH * ((double)i + 0.5);
    sum += f(fX);
  }
  *partial = sum;
  return partial;
}

// fH se aplica una sola vez al final sobre la suma agregada.
double CalcPiParallel(long n, int T) {
  const double fH = 1.0 / (double)n;
  pthread_t *threads = malloc(T * sizeof(pthread_t));
  ThreadArg *args = malloc(T * sizeof(ThreadArg));

  // Partición por bloques: reparte el residuo (n % T) entre los
  // primeros hilos para que ninguno difiera en más de 1 iteración.
  long base = n / T;
  long rem = n % T;
  long cursor = 0;

  for (int t = 0; t < T; t += 1) {
    long count = base + (t < rem ? 1 : 0);
    args[t].start = cursor;
    args[t].end = cursor + count;
    args[t].fH = fH;
    cursor += count;
    pthread_create(&threads[t], NULL, worker, &args[t]);
  }

  double total = 0.0;
  for (int t = 0; t < T; t += 1) {
    void *ret;
    pthread_join(threads[t], &ret); // bloquea hasta que el hilo t termine
    total += *(double *)ret;
    free(ret);
  }

  free(threads);
  free(args);
  return fH * total;
}

int main(int argc, char *argv[]) {
  if (argc != 3) {
    fprintf(stderr, "Uso: %s <n> <num_hilos>\n", argv[0]);
    return 1;
  }

  long n = strtol(argv[1], NULL, 10);
  int T = atoi(argv[2]);
  if (n <= 0 || T <= 0) {
    fprintf(stderr, "n y num_hilos deben ser > 0\n");
    return 1;
  }

  double t0 = GetTime();
  double pi = CalcPiParallel(n, T);
  double t1 = GetTime();

  printf("pi = %.15f\n", pi);
  printf("hilos = %d\n", T);
  printf("tiempo CalcPi = %.6f s\n", t1 - t0);
  return 0;
}
