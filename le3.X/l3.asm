; ========================================================================
; PIC18F4550 - SECUENCIA DE 4 LEDs (VERSIÓN SIMPLE - pic-as)
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

; VARIABLES
PSECT udata_acs
seq: DS 1           ; Secuencia actual
step: DS 1          ; Paso actual
d1: DS 1            ; Delay 1
d2: DS 1            ; Delay 2

; VECTORES
PSECT resetVec, class=CODE, reloc=2
ORG 0x00
GOTO INIT

PSECT intVec, class=CODE, reloc=2
ORG 0x08
GOTO INT0_ISR

; CÓDIGO PRINCIPAL
PSECT code

INIT:
        ; Oscilador 8 MHz
        MOVLW 0x72
        MOVWF OSCCON, a
        
        ; Esperar estabilidad
        BTFSS OSCCON, 2, a
        BRA $-2
        
        ; PUERTO D salidas
        MOVLW 0xF0
        MOVWF TRISD, a
        CLRF LATD, a
        
        ; PUERTO B entrada
        BSF TRISB, 0, a
        BSF INTCON2, 7, a
        
        ; INT0 config
        BCF INTCON2, 6, a
        BCF INTCON, 1, a
        BSF INTCON, 4, a
        BSF INTCON, 7, a
        
        ; Variables
        CLRF seq, a
        CLRF step, a
        
        ; Primer LED
        MOVLW 0x01
        MOVWF LATD, a
        
        ; BUCLE PRINCIPAL
LOOP:
        ; Ejecutar secuencia
        CALL RUN_SEQ
        
        ; Delay
        MOVLW 0x20
        MOVWF d2, a
DEXT:
        MOVLW 0xFF
        MOVWF d1, a
DINT:
        DECFSZ d1, f, a
        BRA DINT
        DECFSZ d2, f, a
        BRA DEXT
        
        ; Siguiente paso
        INCF step, f, a
        BRA LOOP

; EJECUTAR SECUENCIA
RUN_SEQ:
        MOVF seq, w, a
        
        ; seq = 0?
        BZ SEQ0
        
        ; seq = 1?
        DECF seq, w, a
        BZ SEQ1
        
        ; seq = 2?
        INCF seq, w, a
        MOVF seq, w, a
        SUBLW 0x02
        BZ SEQ2
        
        ; seq = 3?
        MOVF seq, w, a
        SUBLW 0x03
        BZ SEQ3
        
        RETURN

; ====== SECUENCIA 0: 1 ? 2 ? 4 ? 8 ======
SEQ0:
        MOVF step, w, a
        ANDLW 0x03
        
        ; step = 0
        BZ S0_0
        
        ; step = 1
        MOVF step, w, a
        SUBLW 0x01
        BZ S0_1
        
        ; step = 2
        MOVF step, w, a
        SUBLW 0x02
        BZ S0_2
        
        ; step = 3
        MOVLW 0x08
        MOVWF LATD, a
        RETURN
        
S0_0:
        MOVLW 0x01
        MOVWF LATD, a
        RETURN
        
S0_1:
        MOVLW 0x02
        MOVWF LATD, a
        RETURN
        
S0_2:
        MOVLW 0x04
        MOVWF LATD, a
        RETURN

; ====== SECUENCIA 1: 8 ? 4 ? 2 ? 1 ======
SEQ1:
        MOVF step, w, a
        ANDLW 0x03
        
        BZ S1_0
        MOVF step, w, a
        SUBLW 0x01
        BZ S1_1
        MOVF step, w, a
        SUBLW 0x02
        BZ S1_2
        
        MOVLW 0x01
        MOVWF LATD, a
        RETURN
        
S1_0:
        MOVLW 0x08
        MOVWF LATD, a
        RETURN
        
S1_1:
        MOVLW 0x04
        MOVWF LATD, a
        RETURN
        
S1_2:
        MOVLW 0x02
        MOVWF LATD, a
        RETURN

; ====== SECUENCIA 2: 1 ? 3 ? 7 ? 15 ======
SEQ2:
        MOVF step, w, a
        ANDLW 0x05
        
        BZ S2_0
        MOVF step, w, a
        SUBLW 0x01
        BZ S2_1
        MOVF step, w, a
        SUBLW 0x02
        BZ S2_2
        MOVF step, w, a
        SUBLW 0x03
        BZ S2_3
        MOVF step, w, a
        SUBLW 0x04
        BZ S2_4
        
        MOVLW 0x03
        MOVWF LATD, a
        RETURN
        
S2_0:
        MOVLW 0x01
        MOVWF LATD, a
        RETURN
        
S2_1:
        MOVLW 0x03
        MOVWF LATD, a
        RETURN
        
S2_2:
        MOVLW 0x07
        MOVWF LATD, a
        RETURN
        
S2_3:
        MOVLW 0x0F
        MOVWF LATD, a
        RETURN
        
S2_4:
        MOVLW 0x07
        MOVWF LATD, a
        RETURN

; ====== SECUENCIA 3: 9 ? 6 ======
SEQ3:
        MOVF step, w, a
        ANDLW 0x01
        
        BZ S3_0
        
        MOVLW 0x06
        MOVWF LATD, a
        RETURN
        
S3_0:
        MOVLW 0x09
        MOVWF LATD, a
        RETURN

; ====== INTERRUPCIÓN INT0 ======
INT0_ISR:
        BTFSS INTCON, 1, a
        RETFIE
        
        BCF INTCON, 1, a
        
        ; Siguiente secuencia
        INCF seq, f, a
        
        ; Si seq > 3, reiniciar a 0
        MOVF seq, w, a
        SUBLW 0x04
        BNC CAMBIO_OK
        CLRF seq, a
        
CAMBIO_OK:
        CLRF step, a
        CLRF LATD, a
        
        ; Debounce
        MOVLW 0x10
        MOVWF d2, a
DBEXT:
        MOVLW 0xFF
        MOVWF d1, a
DBINT:
        DECFSZ d1, f, a
        BRA DBINT
        DECFSZ d2, f, a
        BRA DBEXT
        
        RETFIE

END