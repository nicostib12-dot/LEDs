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
TIEMPO:   DS 1      ; contador general de segundos

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
; Precarga del timer0
;--------------------------------
    CAll RELOAD_TIMER0
    BSF T0CON,7,A        ; Encender Timer0
;=====================================================
; LOOP PRINCIPAL (INFINITO)
;=====================================================

LOOP:

;--------------------------------
; Esperar 1 segundo (overflow)
;--------------------------------
ESPERA:
    BTFSS INTCON,2,A     ; ¿TMR0IF = 1?
    GOTO ESPERA          ; Si no, seguir esperando

    BCF INTCON,2,A       ; Limpiar bandera

;--------------------------------
; Recargar Timer para siguiente segundo
;--------------------------------
    CALL RELOAD_TIMER0

;--------------------------------
; Incrementar tiempo global
;--------------------------------
    INCF TIEMPO,F,A

;=====================================================
; FASE1: 5 parpadeos de 1s
;=====================================================

    MOVLW 10
    SUBWF TIEMPO,W,A     ; W = TIEMPO - 10
    BTFSS STATUS,0       ; ¿Borrow? (TIEMPO < 10)
    GOTO FASE1
    GOTO FASE2           ; Si no hay borrow, TIEMPO >= 10

;--------------------------------
; FASE 1: cambiar LED cada segundo
;--------------------------------
FASE1:
    BTG LATB,0,A         ; Toggle cada segundo
    GOTO VERIFICAR_RESET

;=====================================================
; FASE 2 
;=====================================================

FASE2:

;--------------------------------
; Parpadea LED cada 2 segundos
;--------------------------------
; Revisamos bit 0 del contador:
; Si TIEMPO es PAR (bit0 = 0)
; entonces cambiamos LED
;--------------------------------

    BTFSC TIEMPO,0,A     ; ¿Bit0 = 1? (impar)
    GOTO VERIFICAR_RESET ; Si impar = no hacer nada

    BTG LATB,0,A         ; Si par ? cambiar LED

;=====================================================
; Verificar si terminó el ciclo de 18 segundos
;=====================================================

VERIFICAR_RESET:

    MOVLW 18
    SUBWF TIEMPO,W,A     ; W = TIEMPO - 18
    BTFSS STATUS,2       ; ¿TIEMPO = 18?
    GOTO LOOP

;--------------------------------
; Reiniciar ciclo completo
;--------------------------------
    CLRF TIEMPO,A
    GOTO LOOP
    
;==============================
; SUBRUTINA: RECARGAR TIMER0
;==============================
RELOAD_TIMER0:
    MOVLW 0xE1
    MOVWF TMR0H,A
    MOVLW 0x6B
    MOVWF TMR0L,A
    RETURN
    
    

END


