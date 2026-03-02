; ========================================================================
; PIC18F4550 - SECUENCIA 4 LEDs
; 
; ========================================================================

#include <xc.inc>

CONFIG FOSC = INTOSCIO_EC
CONFIG WDT = OFF
CONFIG LVP = OFF
CONFIG PBADEN = OFF
CONFIG MCLRE = OFF
CONFIG XINST = OFF
CONFIG PWRT = ON
CONFIG DEBUG = OFF

; VARIABLES
PSECT udata_acs
secuencia:  DS 1
contador:   DS 1
velocidad:  DS 1
btnState:   DS 1
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

        MOVLW 0x72
        MOVWF OSCCON, a
WAIT_OSC:
        BTFSS OSCCON, 2, a
        BRA WAIT_OSC

        MOVLW 0xF0
        MOVWF TRISD, a
        CLRF LATD, a

        ; RB0 = velocidad
        BSF TRISB, 0, a

        ; RB1 = secuencia (INT0)
        BSF TRISB, 1, a

        ; INT0 flanco descendente
        BCF INTCON2, 6, a
        BCF INTCON, 1, a
        BSF INTCON, 4, a
        BSF INTCON, 7, a

        CLRF secuencia, a
        CLRF contador, a
        CLRF velocidad, a

        MOVLW 1
        MOVWF btnState, a

        MOVLW 0x01
        MOVWF LATD, a

; ========================================================================
; BUCLE PRINCIPAL
; ========================================================================

BUCLE:

        CALL CHECK_VEL     ; ? NUEVO

        CALL MOSTRAR_LED
        CALL ESPERAR_300MS

        INCF contador, f, a
        BRA BUCLE

; ========================================================================
; RUTINA BOTÓN VELOCIDAD (3 NIVELES)
; ========================================================================

CHECK_VEL:

        BTFSC PORTB,0      ; Si está en 1 (no presionado)
        GOTO RELEASE

        MOVF btnState,W
        BZ END_CHECK       ; Ya estaba presionado

        CLRF btnState      ; Bloqueo anti-rebote
        INCF velocidad,f   ; Cambiar nivel

        MOVLW 3
        CPFSEQ velocidad
        GOTO END_CHECK

        CLRF velocidad     ; Si llega a 3 ? vuelve a 0

END_CHECK:
        RETURN

RELEASE:
        MOVLW 1
        MOVWF btnState
        RETURN

; ========================================================================
; MOSTRAR LED SEGÚN SECUENCIA
; (Aquí pegas tus SEQ0, SEQ1, SEQ2, SEQ3 sin cambios)
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



; ========================================================================
; DELAY (AÚN FIJO)
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


ISR_BOTON:
        BTFSS INTCON, 1, a
        RETFIE

        BCF INTCON, 1, a

        INCF secuencia, f, a
        CLRF contador, a
        CLRF LATD, a

        RETFIE

END