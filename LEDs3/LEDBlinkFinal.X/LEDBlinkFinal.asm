;===========================================================
; Microcontrolador: PIC18F4550
; Oscilador interno: 8 MHz
; Funcionalidades:
;   - 4 efectos distintos en 4 LEDs (RD0?RD3)
;   - INT0 (RB0) cambia la secuencia
;   - INT1 (RB1) cambia la velocidad
;   - Timer0 genera base de tiempo (~10 ms)
;   - Debounce no bloqueante por software
;   - Máquina de estados en el main
;   - ISR solo modifica variables
;   - El main ejecuta la lógica
;===========================================================

#include <xc.inc>

;============================
; CONFIGURACIÓN
;============================
CONFIG  FOSC = INTOSCIO_EC
CONFIG  WDT = OFF
CONFIG  LVP = OFF
CONFIG  PBADEN = OFF

;============================
; VARIABLES (Access Bank)
;============================
PSECT udata_acs

MODO        DS 1   ; 0?3 secuencia actual
VELOCIDAD   DS 1   ; 0=rápida  1=lenta
INDICE      DS 1   ; posición dentro del efecto
TICK        DS 1   ; contador base 10 ms
FLAG_UPDATE DS 1   ; indica cuándo actualizar LEDs
DB_MODE     DS 1   ; debounce botón secuencia
DB_SPEED    DS 1   ; debounce botón velocidad

;---------------------------------------------------------
; VECTOR DE RESET
;---------------------------------------------------------
PSECT resetVec,class=CODE,reloc=2
ORG 0x0000
GOTO INIT

;---------------------------------------------------------
; VECTOR DE INTERRUPCIÓN (alta prioridad)
;---------------------------------------------------------
PSECT intVec,class=CODE,reloc=2
ORG 0x0008
 
 ;---------------------------------------------------------
; CÓDIGO PRINCIPAL
;---------------------------------------------------------

PSECT code,class=CODE,reloc=2

;---------------------------------------------------------
; INICIALIZACIÓN
;---------------------------------------------------------

INIT:

    ; PORTD como salida (LEDs)
    CLRF LATD
    CLRF PORTD
    CLRF TRISD

    ; RB0 y RB1 como entradas (botones)
    BSF TRISB,0
    BSF TRISB,1

    ; Inicializar variables
    CLRF TICK
    CLRF MODO
    CLRF VELOCIDAD
    CLRF FLAG_UPDATE
    MOVLW 0x01
    MOVWF INDICE

;---------------------------------------------------------
; CONFIGURAR TIMER0
;---------------------------------------------------------

    MOVLW b'10000111'      ; Timer0 ON, 16bit, prescaler 256
    MOVWF T0CON

    ; Precarga para ~10ms (depende del cristal)
    MOVLW 0x63
    MOVWF TMR0H
    MOVLW 0xC0
    MOVWF TMR0L

    BSF INTCON,TMR0IE      ; Habilita Timer0
    BSF INTCON,GIE         ; Habilita interrupciones globales

;---------------------------------------------------------
; CONFIGURAR INTERRUPCIONES EXTERNAS
;---------------------------------------------------------

    BSF INTCON,INT0IE
    BCF INTCON2,INTEDG0    ; Flanco descendente

    BSF INTCON3,INT1IE
    BCF INTCON2,INTEDG1    ; Flanco descendente

