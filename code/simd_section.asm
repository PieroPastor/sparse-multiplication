section .text
    global simd_section
;rdi <- *col
;rsi <- *val
;rdx <- *vector
;rcx <- size
simd_section:
    xorps xmm0, xmm0 ;El sumador
    mov r9, 0 ;Será mi índice
    cmp r9, rcx
    jl bucle_sumador
ret

bucle_sumador:
    xorps xmm1, xmm1 ;Guarda los valores de la matriz
    xorps xmm2, xmm2 ;Guarda los valores del vector
    mov r10, rcx
    sub r10, r9
    cmp r10, 4
    jl enviar_no_simd
    movups xmm1, [rsi + r9*4]
    mov r10, rcx
    mov rcx, 4
    jmp guardar_vector

enviar_no_simd:
    movss xmm3, [rsi + r9*4]
    movss xmm1, xmm3
    cvtss2si r12, [rdi + r9*4]
    movss xmm3, [rdx + r12*4]
    movss xmm2, xmm3
    shufps xmm1, xmm1, 00111001b
    shufps xmm2, xmm2, 00111001b
    inc r9
    cmp r9, rcx
    jl enviar_no_simd
    jmp fin_bucle

guardar_vector:
    cvtss2si r12, [rdi + r9*4]
    movss xmm3, [rdx + r12*4]
    movss xmm2, xmm3
    shufps xmm2, xmm2, 00111001b
    inc r9
    ;dec r10
    ;cmp r10, 0
    ;jg guardar_vector
    loop guardar_vector
    mov rcx, r10 ;Regresa rcx a la normalidad
    jmp fin_bucle

fin_bucle:
    mulps xmm1, xmm2
    haddps xmm1, xmm1
    haddps xmm1, xmm1
    addss xmm0, xmm1
    cmp r9, rcx ;Ya se le sumaron 4, o lo que restaba menor a 4 en sus bucles respectivos
    jl bucle_sumador
    ret
