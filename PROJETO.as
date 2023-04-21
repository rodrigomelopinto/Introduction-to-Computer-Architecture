TERM_WRITE      EQU     FFFEh
TERM_CURSOR     EQU     FFFCh
INT_TEMPO       EQU     10
STACK_POINTER   EQU     7000h
ACEL_GRAV       EQU     09CBh  ;AproximaÃ§Ã£o de 9,8 com 8 bits decimais. (~9.792)
INT_MASK        EQU     FFFAh
MASK_TIMER_ON   EQU     8000h
CTRL_TIMER      EQU     FFF7h
TIMER_ON        EQU     1
TIMER_VALUE     EQU     FFF6h
ACELEROMETRO_X  EQU     FFEBh
INTERVALO_TEMPO EQU     1
FATOR_DE_ESCALA EQU     0100h
                
ACELERACAO_X    WORD    0000h
BITS_RAC_AC     WORD    8
VEL_ATUAL       WORD    0300h
BITS_RAC_VEL    WORD    8
POS_ATUAL       WORD    0100h
BITS_RAC_POS    WORD    8
POS_78_A_ESCALA WORD    0
ULTIMA_POSICAO  WORD    0101h
                
                ORIG    0000h
                MVI     R6, STACK_POINTER
                ENI
                
                MVI     R1, FATOR_DE_ESCALA
                JAL     POR_78_A_ESCALA 
                
                JAL     IMPRIME
                
                MVI     R1, INT_MASK
                MVI     R2, MASK_TIMER_ON
                STOR    M[R1], R2
                
                MVI     R1, CTRL_TIMER
                MVI     R2, TIMER_ON
                STOR    M[R1], R2
                
                MVI     R1, TIMER_VALUE
                MVI     R2, INTERVALO_TEMPO
                STOR    M[R1], R2
                
                

                
WAIT:           BR      WAIT
;-------------------------------------------------------------------------------
Main:          ;InicializaÃ§Ã£o do timer. 
                ENI
                MVI     R1, TIMER_VALUE
                MVI     R2, INTERVALO_TEMPO
                STOR    M[R1], R2
                MVI     R1, CTRL_TIMER
                MVI     R2, TIMER_ON
                STOR    M[R1], R2
               ;Passagem dos parametros e chamada da funÃ§Ã£o POS_x.
                MVI     R1, POS_ATUAL
                LOAD    R1, M[R1]
                MVI     R2, VEL_ATUAL
                LOAD    R2, M[R2]
                JAL     POS_X
               ;Passagem dos parametros e chamada da funÃ§Ã£o VEL_X.
                MVI     R1, VEL_ATUAL
                LOAD    R1, M[R1]
                MVI     R2, ACELERACAO_X
                LOAD    R2, M[R2]
                JAL     VEL_X
               ;Rotina de atualizaÃ§Ã£o da aceleraÃ§Ã£o no eixo dos x. 
                JAL     ACEL_X
               ;Passagem dos parametros e salto para a subrotina CHOQUE.
                MVI     R1, POS_ATUAL
                LOAD    R1, M[R1]
                MVI     R2, VEL_ATUAL
                LOAD    R2, M[R2]
                JAL     CHOQUE 
               ;Passagem dos parametros e chamada da funÃ§Ã£o ROUND_DOWN.
                MOV     R1, R3
                MVI     R2, BITS_RAC_POS
                LOAD    R2, M[R2]
                JAL     ROUND_DOWN 
                
                MOV     R1, R3
                JAL     PRINT_POSICAO
                BR      WAIT
               
                        
;-------------------------------------------------------------------------------
;Argumentos: R1 = Valor do acelerometro em x, R2 = AceleraÃ§Ã£o da gravidade;
;Resultado:  R3
;Efeitos:    Devolve a aceleraÃ§Ã£o em x
;Destroi:    R1, R2, R3, R4, R5
;-------------------------------------------------------------------------------
ACEL_X:         DEC     R6
                STOR    M[R6], R4
                DEC     R6 
                STOR    M[R6], R5
                DEC     R6
                STOR    M[R6], R7
                
                MVI     R1, ACELEROMETRO_X
                LOAD    R1, M[R1]
                
                MVI     R2, 8
                DEC     R6
                STOR    M[R6], R2
                DEC     R6
                STOR    M[R6], R2
                MVI     R2, ACEL_GRAV
                
                JAL     MULT_FRAC
                
                MVI     R1, ACELERACAO_X
                STOR    M[R1], R3
                
                LOAD    R2, M[R6]
                INC     R6
                MVI     R1, BITS_RAC_AC
                STOR    M[R1], R2
                
                LOAD    R7, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                JMP     R7
;-------------------------------------------------------------------------------
;Argumentos: R1 = Velocidade atual, R2 = AceleraÃ§Ã£o no x
;Resultado:  R3
;Efeitos:    Devolve a velocidade em x em funÃ§Ã£o da aceleraÃ§Ã£o em x
;Destroi:    R1, R2, R3
;-------------------------------------------------------------------------------
VEL_X:         ;Soma da velocidade com a aceleraÃ§Ã£o.
                ADD     R3, R1, R2
               ;AtualizaÃ§Ã£o dos valores de VEL_ATUAL.
                MVI     R1, VEL_ATUAL
                STOR    M[R1], R3            
                JMP     R7
                
;-------------------------------------------------------------------------------                
;Argumentos: R1 = PosiÃ§Ã£o atual, R2 = Velocidade atual
;Resultado:  R3
;Efeitos:    Devolve a posiÃ§Ã£o em x no fim do intervalo de tempo 
;            em funÃ§Ã£o da velocidade atual e da posiÃ§Ã£o atual
;Destroi:    R1, R2, R3
;-------------------------------------------------------------------------------
POS_X:         ;Soma da posiÃ§Ã£o com a velocidade. 
                ADD     R3, R1, R2
                
               ;AtualizaÃ§Ã£o dos valores de POS_ATUAL.
                MVI     R1, POS_ATUAL
                STOR    M[R1], R3

                JMP     R7
;-------------------------------------------------------------------------------
;Argumentos: R4 = PosiÃ§Ã£o atual, R2 = Velocidade atual
;Resultado:  R3
;Efeitos:    Devolve a posiÃ§Ã£o em x apos a bola ter ou não chocado com as
;            paredes
;Destroi:    R1, R2, R3
;-------------------------------------------------------------------------------
CHOQUE:         MVI     R4, POS_78_A_ESCALA
                LOAD    R4, M[R4]
                CMP     R1, R4
                BR.P    .CHOQUE_D
                CMP     R1, R0
                BR.NP   .CHOQUE_E
                BR      .FIM
                
.CHOQUE_D:      COM     R2
                INC     R2
                MVI     R4, VEL_ATUAL
                STOR    M[R4], R2
                
                MVI     R4, POS_78_A_ESCALA
                LOAD    R4, M[R4]
                SUB     R4, R1, R4
                MVI     R1, POS_78_A_ESCALA
                LOAD    R1, M[R1]
                SUB     R1, R1, R4
                
                BR      CHOQUE

.CHOQUE_E:      COM     R2
                INC     R2
                MVI     R4, VEL_ATUAL
                STOR    M[R4], R2
                
                COM     R1
                INC     R1
                MVI     R2, FATOR_DE_ESCALA
                SHL     R2
                ADD     R1, R1, R2
                
                BR      CHOQUE
                     
.FIM:           MOV     R3, R1
                MVI     R1, POS_ATUAL
                STOR    M[R1], R3
                JMP     R7
;-------------------------------------------------------------------------------
;Argumentos: R1 = PosiÃ§Ã£o atual
;Resultado:  
;Efeitos:    Imprime no terminal um 'o' na posição onde a bola se encontra num
;            determinado instante
;Destroi:    R2,R4
;-------------------------------------------------------------------------------
PRINT_POSICAO:  DEC     R6
                STOR    M[R6], R4
                MVI     R4, ULTIMA_POSICAO
                LOAD    R4, M[R4]
                MVI     R2,TERM_CURSOR
                STOR    M[R2],R4
                
                MVI     R3, ' '
                MVI     R2, TERM_WRITE
                STOR    M[R2], R3
                
                MVI     R4, 0100h
                ADD     R4, R4, R1
                MVI     R2,TERM_CURSOR
                STOR    M[R2],R4
                
                MVI     R3, 'O'
                MVI     R2, TERM_WRITE
                STOR    M[R2], R3
                
                MVI     R2, ULTIMA_POSICAO
                STOR    M[R2], R4
                
                LOAD    R4, M[R6]
                INC     R6
                JMP     R7
;-------------------------------------------------------------------------------
;Argumentos: R2 = Posição atual com casas decimais
;Resultado:  R3
;Efeitos:    Devolve a posiÃ§Ã£o em x arredendada às unidades
;Destroi:    R1,R3
;-------------------------------------------------------------------------------
ROUND_DOWN:     CMP     R2, R0
                BR.Z    .SAI
                SHRA    R1
                DEC     R2
                BR      ROUND_DOWN
.SAI:           MOV     R3, R1
                JMP     R7
;-------------------------------------------------------------------------------
;Argumentos: R1 = Escala convencionada , 
;            R2 = Numero de posições onde a bola se pode mexer
;Resultado:  R3
;Efeitos:    Devolve as posiÃ§Ã£o em x à escala que foi convencionada
;Destroi:    R1, R2, R3
;-------------------------------------------------------------------------------
POR_78_A_ESCALA:MVI     R2, 78

                DEC     R6
                STOR    M[R6], R7
                JAL     MULTIPLY
                LOAD    R7, M[R6]
                INC     R6
                
                MVI     R1, POS_78_A_ESCALA
                STOR    M[R1], R3
                JMP     R7
;-------------------------------------------------------------------------------
;Argumentos: R1, R2 = Operadores
;            Posicao mais baixa da stack = bits racionais de R1
;            Posicao da stack anterior = bits racionais de R2
;Resultado:  R3 e posiÃ§Ã£o mais baixa da stack
;Efeitos:    Devolve a multiplicaÃ§Ã£o entre dois numeros,
;            e o nÃºmero de bits racionais do resultado (sempre 8).
;Destroi:    R1, R2, R3, R4, R5
;-------------------------------------------------------------------------------
MULT_FRAC:     ;Carregamento dos bits racionais de op1 para R2 preservando R2.
                LOAD    R4, M[R6]
                INC     R6
                DEC     R6
                STOR    M[R6], R2
                MOV     R2, R4   
               ;PUSH R7
                DEC     R6
                STOR    M[R6], R7
               ;Passagem dos bits racionais do op1 para 4.
                JAL     PARA_QUATRO
               ;POP R7
                LOAD    R7, M[R6]
                INC     R6
               ;Passagem do op2 para R1 e dos seus bits racionais para R2.
                LOAD    R1, M[R6]
                INC     R6
                LOAD    R2, M[R6]
                INC     R6
               ;Carregamento do op1 com 4 bits racionais para a pilha e PUSH R7. 
                DEC     R6        
                STOR    M[R6], R3
                DEC     R6        
                STOR    M[R6], R7
               ;Passagem dos bits racionais do op2 para 4. 
                JAL     PARA_QUATRO
               ;POP R7 
                LOAD    R7, M[R6]  
                INC     R6
               ;Passagem do op1 para R1 e op2 para R2. 
                LOAD    R1, M[R6]  
                INC     R6
                MOV     R2, R3  
               ;PUSH R7 
                DEC     R6
                STOR    M[R6], R7
               ;MultiplicaÃ§Ã£o dos nÃºmeros inteiros correspondentes a op1 e op2. 
                JAL     MULTIPLY
               ;POP R7                 
                LOAD    R7, M[R6]
                INC     R6
               ;Passagem dos bits racionais de op1*op2 para a stack. 
                MVI     R4, 8
                DEC     R6
                STOR    M[R6], R4
                JMP     R7 
;-------------------------------------------------------------------------------
MULTIPLY:       MOV     R3, R0
                CMP     R2, R0
                BR.Z    .SAI
.LOOPM:         ADD     R3, R3, R1
                DEC     R2
                BR.NZ   .LOOPM
.SAI:           JMP     R7
;-------------------------------------------------------------------------------
;Argumentos: R1 = NÃºmero inteiro; R2 = NÃºmero de bits racionais de R1;
;Resultado:  R3
;Efeitos:    Devolve o nÃºmero que entra em R1 com 4 bits racionais
;Destroi:    R3, R4, (pode destruir: R1, R2)
;-------------------------------------------------------------------------------
PARA_QUATRO:   ;ComparaÃ§Ã£o do nÃºmero de bits racionais de R1 com 4.
                MVI     R4, 4
.LOOP:          CMP     R2, R4
                BR.Z    .SAI
                BR.N    .SHL_R1
               ;NÃºmero de bits racionais de R1 > 4.
                DEC     R2
                SHR     R1
                BR      .LOOP
               ;NÃºmero de bits racionais de R1 < 4.
.SHL_R1:        INC     R2
                SHL     R1
                BR      .LOOP
               ;NÃºmero de bits racionais de R1 = 4.
.SAI:           MOV     R3, R1
                JMP     R7
;-------------------------------------------------------------------------------
;Argumentos: R1 = Variável para se escrever no terminal; 
;            R2 = Numero de colunas que se imprime
;Resultado:  
;Efeitos:    Imprime no terminal as colunas e as linhas
;Destroi:    R2,R4
;-------------------------------------------------------------------------------
IMPRIME:        DEC     R6
                STOR    M[R6], R4
                MVI     R1,TERM_WRITE
                MVI     R2,81
                
.LOOP:          MVI     R4,'*'
                DEC     R2
                STOR    M[R1],R4
                CMP     R2,R0
                BR.NZ   .LOOP
                
                MVI     R4,014Fh
                MVI     R2, TERM_CURSOR
                STOR    M[R2], R4
                
                MVI     R2,81
                
.LOOP3:         MVI     R4,'*'
                DEC     R2
                STOR    M[R1],R4
                BR.NZ   .LOOP3
                LOAD    R4, M[R6]
                INC     R6
                JMP     R7
;-------------------------------------------------------------------------------
                ORIG    7FF0h
                JMP     Main