
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

double GetTime(void){ struct timeval t; gettimeofday(&t,NULL);
    return t.tv_sec + t.tv_usec*1e-6; }

int main(int argc, char**argv){
    long N = strtol(argv[1], NULL, 10);
    unsigned long long *seq = malloc(N*sizeof(unsigned long long));
    double t0 = GetTime();
    if(N>=1) seq[0]=1;
    if(N>=2) seq[1]=1;
    for(long i=2;i<N;i++) seq[i]=seq[i-1]+seq[i-2];  // wraparound: solo medimos tiempo
    double t1 = GetTime();
    printf("N=%ld  tiempo=%.6f s  ultimo(mod 2^64)=%llu\n", N, t1-t0, seq[N-1]);
    free(seq);
    return 0;
}
