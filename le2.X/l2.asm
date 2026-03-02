#include <xc.inc>

CONFIG FOSC = INTOSCIO_EC
CONFIG WDT = OFF
CONFIG LVP = OFF
CONFIG PBADEN = OFF

PSECT resetVec, class=CODE, reloc=2
ORG 0x00
GOTO inicio

PSECT main_code, class=CODE, reloc=2

inicio:
    CLRF TRISB
    CLRF LATB

principal:
    CALL prender1
    CALL prender2
    GOTO principal

;============================
; 5 parpadeos 1 segundo
;============================
prender1:
    MOVLW 5
    MOVWF Contador1

bucle1:
    BSF LATB,0
    CALL timer1

    BCF LATB,0
    CALL timer1

    DECFSZ Contador1, F
    GOTO bucle1
    RETURN

;============================
; 2 parpadeos 2 segundos
;============================
prender2:
    MOVLW 2
    MOVWF Contador2

bucle2:
    BSF LATB,0
    CALL timer2

    BCF LATB,0
    CALL timer2

    DECFSZ Contador2, F
    GOTO bucle2
    RETURN

timer1:
    MOVLW 17
    MOVWF Cont1

Loop1:
    MOVLW 50
    MOVWF Cont2

Loop2:
    MOVLW 50
    MOVWF Cont3

Loop3:
    nop
    nop
    DECFSZ Cont3, F
    GOTO Loop3

    DECFSZ Cont2, F
    GOTO Loop2

    DECFSZ Cont1, F
    GOTO Loop1

    RETURN
timer2:
    CALL timer1
    CALL timer1
    RETURN

;============================
; VARIABLES
;============================
PSECT udata
Contador1: DS 1
Contador2: DS 1
Cont1: DS 1
Cont2: DS 1
Cont3: DS 1