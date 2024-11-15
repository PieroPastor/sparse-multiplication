extern void matriz_vector_traditional_simd(float *row, float *col, float *val, float *vector, float *sol, float *tam);
void matriz_vector(float *row, float *col, float *val, float *vector, float *sol, int *repeats, int n, int cant_data){
    int sumador=0;
    for(int i=0; i < n; i++){
        for(int j=0; j < repeats[i]; j++){
            sol[i] += val[j + sumador] * vector[(int)col[j + sumador]];
        }
        sumador += repeats[i];
    }
    return;
}
void matriz_vector_traditional(float *row, float *col, float *val, float *vector, float *sol, int n_ptrs, int n){
    for(int i=0; i < n_ptrs-1; i++){
        for(int j=(int)row[i]; j < (int)row[i+1]; j++) sol[i] += val[j] * vector[(int)col[j]];
    }
    for(int i=(int)row[n_ptrs-1]; i < n; i++) sol[n_ptrs-1] += val[i] * vector[(int)col[i]];
    return;
}
