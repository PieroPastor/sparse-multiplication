#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

extern float simd_section(float *col, float *val, float *vector, int size);

typedef struct th_info{
    pthread_t thread;
    int size;
    int id;
    float *col;
    float *val;
    float *vector;
    float suma;
} th_info;

void *pth_func(void *args){
    th_info *th_info_args = (th_info*) args;
    th_info_args->suma = simd_section(th_info_args->col, th_info_args->val, th_info_args->vector, th_info_args->size);
    return NULL;
}

float multithreading_vector(int n, float *col, float *val, float *vector, int sumador, int ths){
    float suma=0;
    int size=n/ths;
    if(n > ths)size = n/ths;
    else if(n > 0){
        size = 1;
        ths = n;
    }
    th_info threads[ths];

    for(int i=0; i < ths; i++){
        if(i == ths-1) threads[i].size = size + (n-(ths*size)); //Da el residuo como extra
        else threads[i].size = size;
        threads[i].id = i;
        threads[i].col = col + i*size + sumador;
        threads[i].val = val + i*size + sumador;
        threads[i].vector = vector;
        threads[i].suma = 0;
    }

    pth_func((void *)&threads[0]);

    if(ths > 1){
        for(size_t i=1; i < ths; i++) pthread_create(&threads[i].thread, NULL, pth_func, (void*)&threads[i]);
        for(size_t i=1; i < ths; i++) pthread_join(threads[i].thread, NULL);
    }

    for(int i=0; i < ths; i++) suma += threads[i].suma;

    return suma;
}

void matriz_vector(int *repeats, int len_rep, float *col, float *val, float *vector, float *sol, int ths){
    int sumador=0;
    for(int i=0; i < len_rep; i++){
        sol[i] = multithreading_vector(repeats[i], col, val, vector, sumador, ths);
        sumador += repeats[i];
    }
}
