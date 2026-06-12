#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

// Integrando: 4 / (1 + x^2), cuya integral de 0 a 1 es pi.
static inline double f(double x) {
    return 4.0 / (1.0 + x * x);
}

// Regla del punto medio: n rectángulos, cada uno centrado en (i + 0.5)*fH.
double CalcPi(int n) {
    const double fH = 1.0 / (double) n;
    double fSum = 0.0;
    double fX;
    int i;

    for (i = 0; i < n; i += 1) {
        fX = fH * ((double) i + 0.5);
        fSum += f(fX);
    }
    return fH * fSum;
}

// Tiempo en segundos con resolución de microsegundos.
double GetTime(void) {
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec + t.tv_usec * 1e-6;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <n>\n", argv[0]);
        return 1;
    }

    // n puede ser 2e9 -> no cabe en int. Usar long y validar.
    long n = strtol(argv[1], NULL, 10);
    if (n <= 0 || n > 2147483647L) {
        fprintf(stderr, "n fuera de rango para int (max 2147483647)\n");
        return 1;
    }

    double t0 = GetTime();
    double pi = CalcPi((int) n);
    double t1 = GetTime();

    printf("pi = %.15f\n", pi);
    printf("tiempo CalcPi = %.6f s\n", t1 - t0);
    return 0;
}
