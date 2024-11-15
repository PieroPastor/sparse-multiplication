section .text
    global matriz_vector_traditional_simd
;rdi <- row
;rsi <- col
;rdx <- val
;rcx <- vector
;r8 <- sol
;r9 <- n_ptrs, n
;Se tiene un algoritmo que mezcla SIMD y al mismo tiempo operaciones normales para ciertas operaciones, ya que, no se puede predecir cuantos valores
;diferente de cero habrá en cada columna de la matriz.
matriz_vector_traditional_simd:
    movss xmm1, [r9 + 4] ;Guarda n en xmm1 ya que se mandó como doubles y se debe de convertir
    movss xmm0, [r9] ;Guarda n_ptrs
    cvtss2si r9, xmm0 ;Los convierte a enteros
    cvtss2si r10, xmm1
    dec r9 ;Le resta uno porque el bucle es hasta n_ptrs-1
    mov r12, 0 ;Valor de i
    cmp r12, r9
    jl bucle1
ret

bucle1:
    xorps xmm0, xmm0 ;Se limpian todos los registros para evitar fallos en las operaciones
    xorps xmm1, xmm1
    xorps xmm2, xmm2
    xorps xmm3, xmm3
    xorps xmm4, xmm4
    movss xmm15, [rdi + r12*4] ;Pasa la información del puntero a fila y la pasa a entero
    cvtss2si r13, xmm15
    movss xmm15, [rdi + r12*4 + 4] ;Pasa el siguiente puntero a fila como tope y lo pasa a entero
    cvtss2si r14, xmm15
    cmp r13, r14
    push r12
    jl bucle2
    jmp fin_bucle2
  
bucle2:
    push r13 ;Guarda el contador r13, ya que, se necesitan más registros
    mov r12, r14 
    sub r12, r13
    mov rax, r12
    cmp r12, 4 ;Para ver si faltan menos de 4 manda especial, es decir, usará los registros xmmx como cola y almacenará la información ahí hasta donde haya
    jl enviar_especial
    mov r12, 4
    movups xmm1, [rdx + r13*4] ;Manda cuatro valores con una sola operacion
    movups xmm2, [rsi + r13*4]
    mov r13, r12
    jmp guardar_datos_vector

enviar_especial:
    xorps xmm4, xmm4 ;Lo almacena de esa forma para también poder operar con mulps, ya que, como los sobrantes es cero no hay problema y aún se ahorra tiempo
    movss xmm4, [rdx + r13*4] ;Se necesita el auxiliar porque el movss cuando se trabaja con un puntero limpia todo el registro, por lo que la cola se borra
    movss xmm1, xmm4
    movss xmm4, [rsi + r13*4]
    movss xmm2, xmm4
    shufps xmm1, xmm1, 00111001b ;Envía el valor guardado al final y el siguiente para guardarlo ahí (una cola)
    shufps xmm2, xmm2, 00111001b
    dec r12
    inc r13
    cmp r12, 0 ;Hasta que se ingrese la cantidad de data que haya
    jg enviar_especial
    mov rbx, 4 ;Para mantener todo alineado y operar correctamente se deben de completar las vueltas a la cola por lo que la diferencia con 4 es la cantidad de vueltas que faltan.
    sub rbx, rax
    jmp organizar_especial

organizar_especial:
    shufps xmm1, xmm1, 00111001b ;Realiza solo vueltas para alinear los datos
    shufps xmm2, xmm2, 00111001b
    dec rbx
    cmp rbx, 0
    jg organizar_especial
    mov r13, rax
    mov r12, rax
    jmp guardar_datos_vector

guardar_datos_vector:
    cvtss2si r15, xmm2 ;Realiza la misma lógica para guardar todos los datos necesarios del vector en un registro y así operarlo junto aprovechando el SIMD
    movss xmm4, [rcx + r15*4]
    movss xmm3, xmm4
    shufps xmm2, xmm2, 00111001b ;Pasa a la siguiente columna
    shufps xmm3, xmm3, 00111001b ;Para guardar el siguiente dato de vector
    dec r12
    cmp r12, 0
    jg guardar_datos_vector
    mov r12, 4
    sub r12, r13
    cmp r13, 4 ;En caso haya habido menos de 4 valores también se tendrán que alinear los datos
    jl organizar_datos 
    jmp fin_bucle2

organizar_datos:
    shufps xmm3, xmm3, 00111001b 
    shufps xmm2, xmm2, 00111001b
    dec r12
    cmp r12, 0
    jg organizar_datos
    jmp fin_bucle2

fin_bucle2:
    pop r13 ;Regresa r13 a la normalidad
    mulps xmm3, xmm1 ;Multiplica los datos del vector y la matriz y los suma entre ellos
    haddps xmm3, xmm3
    haddps xmm3, xmm3
    addss xmm0, xmm3 ;Se agrega al sumador
    add r13, 4 ;Se suma cuatro porque se avanzo esa cantidad si o si
    xorps xmm1, xmm1 ;Se limpian los registros
    xorps xmm2, xmm2
    xorps xmm3, xmm3
    cmp r13, r14
    jl bucle2
    pop r12 ;Se retira r12 para usarlo y guardar en soluciones el xmm0
    movss [r8 + r12*4], xmm0
    inc r12
    cmp r10, -1 ;Se tiene esta bandera especial para poder usar el código desde otro punto fuera del bucle principal
    je fin_algoritmo
    cmp r12, r9
    jl bucle1
    jmp segunda_parte

segunda_parte:
    movss xmm15, [rdi + r9*4] ;Como falta el valor para n_ptrs porque se evitó, se setean los registros y se salta al bucle2 como si fuera una función
    xorps xmm0, xmm0
    cvtss2si r13, xmm15 ;Pasa el [n_ptrs-1]
    mov r14, r10 ;El final es la cantidad de columnas
    mov r12, r9
    push r12 ;Guarda r12 más que nada por el futuro popeo y que así el PC se mantenga intacto y pueda retornar
    mov r10, -1 ;Servirá como una bandera
    xorps xmm0, xmm0
    xorps xmm1, xmm1
    xorps xmm2, xmm2
    xorps xmm3, xmm3
    xorps xmm4, xmm4
    jmp bucle2
    
fin_algoritmo:
    ret
