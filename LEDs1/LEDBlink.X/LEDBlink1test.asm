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
CONFIG  FOSC = INTOSCIO_EC ; Oscilador interno, pines como I/0
CONFIG  WDT = OFF ; Watchdog timer Desahabilitado
CONFIG  LVP = OFF ; Low Voltage Programming deshabilitado
CONFIG  PBADEN = OFF ; PORTB inicia como digital

;============================
; VARIABLES (Access Bank)
;============================
PSECT udata_acs ; Seccion de  datos en Acces bank
SEGUNDOS:      DS 1 ; variable encangarda de contar los segundos
ESTADO_LED:    DS 1 ; 0 = OFF / 1 = ON

;============================
; CÓDIGO PRINCIPAL
;============================
PSECT code
GLOBAL _main

_main:

    ;-------------------------
    ; Oscilador interno 8MHz
    ;-------------------------
    MOVLW   0x72 ; valor para 8Mhz interno
    MOVWF   OSCCON, A ; Guarda registro OSCCON

    ;-------------------------
    ; RB0 como salida
    ;-------------------------
    BCF     TRISB, 0, A ; El pin RB0 como salida
    BCF     LATB, 0, A ; Inicia apagado el led

    CLRF    SEGUNDOS, A ; inicia en 0 la variable "SEGUNDOS"
    CLRF    ESTADO_LED, A ; Led inicia apagado (0)

    ;-------------------------
    ; Configuración Timer0
    ; 16 bits
    ; Prescaler 1:256
    ;-------------------------
    MOVLW   0b00000111
    MOVWF   T0CON, A ; carga la configuracion
    ;-----------------------------------------------------
    ; PRECARGAR TIMER PARA 1 SEGUNDO
    ;-----------------------------------------------------
    ; Cálculo:
    ; Fosc = 8MHz
    ; Ciclo instrucción = 8MHz/4 = 2MHz
    ; Tick = 0.5us
    ; Con prescaler 256 ? 128us por incremento
    ; 1 segundo ? 7813 incrementos
    ; 65536 - 7813 = 57723 = 0xE16B
    ;-----------------------------------------------------

    MOVLW   0xE1
    MOVWF   TMR0H, A         ; Parte alta del contador
    MOVLW   0x6B
    MOVWF   TMR0L, A         ; Parte baja del contador

    ;-----------------------------------------------------
    ; ENCENDER TIMER0
    ;-----------------------------------------------------
    BSF     T0CON, 7, A      ; Bit TMR0ON = 1

;=========================================================
; LOOP PRINCIPAL
;=========================================================
LOOP:

    ; Esperar overflow (desbordamiento)
ESPERA:
    BTFSS   INTCON, 2, A      ; TMR0IF = 1?
    GOTO    ESPERA            ; Si no, seguir esperando

    BCF     INTCON, 2, A      ; Limpiar bandera

    ; Recargar timer para 1s
    MOVLW   0xE1
    MOVWF   TMR0H, A
    MOVLW   0x6B
    MOVWF   TMR0L, A

    ; Incrementar segundos
    INCF    SEGUNDOS, F, A ; SEGUNDOS++

    ;-------------------------
    ; Lógica LED
    ;-------------------------

    ; Si LED apagado
    MOVF    ESTADO_LED, W, A
    BTFSS   STATUS, 2         ; ¿Es 0?
    GOTO    LED_ENCENDIDO     ; Si no es cero = LED encendido

;---------------------------------------------------------
; LED ACTUALMENTE APAGADO
;---------------------------------------------------------
LED_APAGADO:

    MOVLW   2
    SUBWF   SEGUNDOS, W, A   ; SEGUNDOS - 2
    BTFSS   STATUS, 2        ; ¿SEGUNDOS = 2?
    GOTO    LOOP             ; Si no, seguir esperando

    BSF     LATB, 0, A       ; Encender LED
    CLRF    SEGUNDOS, A      ; Reiniciar contador
    MOVLW   1
    MOVWF   ESTADO_LED, A    ; Cambiar estado a encendido
    GOTO    LOOP

;---------------------------------------------------------
; LED ACTUALMENTE ENCENDIDO
;---------------------------------------------------------
LED_ENCENDIDO:

    MOVLW   1
    SUBWF   SEGUNDOS, W, A   ; SEGUNDOS - 1
    BTFSS   STATUS, 2        ; ¿SEGUNDOS = 1?
    GOTO    LOOP             ; Si no, seguir esperando

    BCF     LATB, 0, A       ; Apagar LED
    CLRF    SEGUNDOS, A      ; Reiniciar contador
    CLRF    ESTADO_LED, A    ; Cambiar estado a apagado
    GOTO    LOOP

END