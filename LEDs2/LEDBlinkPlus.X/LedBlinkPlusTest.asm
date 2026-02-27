;===================================================== 
; 5 parpadeos de 1s
; luego 2 parpadeos de 2s
; PIC18F4550 - Timer0 16bits
;=====================================================

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
TIEMPO:   DS 1      ; Cuenta segundos de 0 a 17

;============================
; CÓDIGO
;============================
PSECT code
GLOBAL _main

_main:

;--------------------------------
; Configurar oscilador a 8 MHz
;--------------------------------
    MOVLW 0x72
    MOVWF OSCCON, A

;--------------------------------
; Configurar RB0 como salida
;--------------------------------
    BCF TRISB,0,A        ; RB0 salida
    BCF LATB,0,A         ; LED inicia apagado

;--------------------------------
; Inicializar contador
;--------------------------------
    CLRF TIEMPO,A

;--------------------------------
; Configurar Timer0
; 16 bits, prescaler 1:256
;--------------------------------
    MOVLW 0b00000111
    MOVWF T0CON,A

;--------------------------------
; Precarga para 1 segundo
;--------------------------------
    MOVLW 0xE1
    MOVWF TMR0H,A
    MOVLW 0x6B
    MOVWF TMR0L,A

    BSF T0CON,7,A        ; Encender Timer0



