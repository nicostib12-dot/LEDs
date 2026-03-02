; ========================================================================
; PIC18F4550 - SECUENCIA 4 LEDs (PREPARADO PARA VELOCIDAD)
; COMMIT 1: Separación de botones
; RB0 = Velocidad
; RB1 = Secuencia (INT0)
; ========================================================================

#include <xc.inc>

; CONFIGURACIÓN
CONFIG FOSC = INTOSCIO_EC
CONFIG WDT = OFF
CONFIG LVP = OFF
CONFIG PBADEN = OFF
CONFIG MCLRE = OFF
CONFIG XINST = OFF
CONFIG PWRT = ON
CONFIG DEBUG = OFF

; VARIABLES EN RAM
PSECT udata_acs
secuencia:  DS 1
contador:   DS 1
velocidad:  DS 1      ; NUEVA VARIABLE
btnState:   DS 1      ; NUEVA VARIABLE
delay_l:    DS 1
delay_h:    DS 1

; VECTORES
PSECT resetVec, class=CODE, reloc=2
ORG 0x00
GOTO INICIO

PSECT intVec, class=CODE, reloc=2
ORG 0x08
GOTO ISR_BOTON

PSECT code

; ========================================================================
; INICIO
; ========================================================================

INICIO:

        ; Oscilador 8 MHz
        MOVLW 0x72
        MOVWF OSCCON, a
WAIT_OSC:
        BTFSS OSCCON, 2, a
        BRA WAIT_OSC

        ; Puerto D salida
        MOVLW 0xF0
        MOVWF TRISD, a
        CLRF LATD, a

        ; RB0 = Velocidad
        BSF TRISB, 0, a

        ; RB1 = INT0 (Secuencia)
        BSF TRISB, 1, a

        ; INT0 flanco descendente
        BCF INTCON2, 6, a
        BCF INTCON, 1, a
        BSF INTCON, 4, a
        BSF INTCON, 7, a

        ; Inicializar variables
        CLRF secuencia, a
        CLRF contador, a
        CLRF velocidad, a
        MOVLW 1
        MOVWF btnState, a

        ; Primer LED
        MOVLW 0x01
        MOVWF LATD, a

; ========================================================================
; BUCLE PRINCIPAL
; ========================================================================

BUCLE:
        CALL MOSTRAR_LED
        CALL ESPERAR_300MS

        INCF contador, f, a
        BRA BUCLE

; ========================================================================
; MOSTRAR LED SEGÚN SECUENCIA
; (AQUÍ VA TODO TU CÓDIGO ORIGINAL DE SECUENCIAS)
; ========================================================================

MOSTRAR_LED:
        MOVF secuencia, w, a
        ANDLW 0x03
        MOVWF secuencia

        MOVF secuencia, w, a
        BZ SEQ0

        MOVLW 1
        CPFSEQ secuencia
        GOTO CHECK2
        GOTO SEQ1

CHECK2:
        MOVLW 2
        CPFSEQ secuencia
        GOTO SEQ3
        GOTO SEQ2

; ===== SECUENCIAS =====
; (Aquí puedes pegar exactamente tus SEQ0, SEQ1, SEQ2, SEQ3 sin cambios)

; ========================================================================
; DELAY (SIN CAMBIOS TODAVÍA)
; ========================================================================

ESPERAR_300MS:
        MOVLW 0x20
        MOVWF delay_h, a

DELAY_EXT:
        MOVLW 0xFF
        MOVWF delay_l, a

DELAY_INT:
        DECFSZ delay_l, f, a
        BRA DELAY_INT
        DECFSZ delay_h, f, a
        BRA DELAY_EXT
        RETURN

; ========================================================================
; ISR INT0 - SOLO CAMBIA SECUENCIA
; ========================================================================

ISR_BOTON:
        BTFSS INTCON, 1, a
        RETFIE

        BCF INTCON, 1, a

        INCF secuencia, f, a
        CLRF contador, a
        CLRF LATD, a

        RETFIE

END