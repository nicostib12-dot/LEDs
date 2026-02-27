;=====================================================
; PROGRAMA: LED 1s ENCENDIDO - 2s APAGADO
; MICRO: PIC18F4550
; MÉTODO: Timer0 modo 16 bits (Polling)
; SOLO SE CONFIGURA RB0 COMO SALIDA
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
SEGUNDOS:      DS 1
ESTADO_LED:    DS 1

;============================
; CÓDIGO PRINCIPAL
;============================
PSECT code
GLOBAL _main

_main:

    ;-------------------------
    ; Oscilador interno 8MHz
    ;-------------------------
    MOVLW   0x72
    MOVWF   OSCCON, A

    ;-------------------------
    ; RB0 como salida
    ;-------------------------
    BCF     TRISB, 0, A
    BCF     LATB, 0, A

    CLRF    SEGUNDOS, A
    CLRF    ESTADO_LED, A

    ;-------------------------
    ; Configuración Timer0
    ; 16 bits
    ; Prescaler 1:256
    ;-------------------------
    MOVLW   0b00000111
    MOVWF   T0CON, A

    ; Precarga para 1 segundo
    ; Valor inicial = 0xE16B
    MOVLW   0xE1
    MOVWF   TMR0H, A
    MOVLW   0x6B
    MOVWF   TMR0L, A

    BSF     T0CON, 7, A   ; Encender Timer0
