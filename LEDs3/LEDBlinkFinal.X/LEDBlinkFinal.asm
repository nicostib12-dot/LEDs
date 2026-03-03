;===========================================================
; Microcontrolador: PIC18F4550
; Oscilador interno: 8 MHz
; Funcionalidades:
;   - 4 efectos distintos en 4 LEDs (RD0/RD3)
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
MODO:        DS 1   ;  secuencia actual
VELOCIDAD:   DS 1   ; 0=rápida  1=lenta
INDICE:      DS 1   ; posición dentro del efecto
TICK:        DS 1   ; contador base 10 ms
FLAG_UPDATE: DS 1   ; indica cuándo actualizar LEDs
DB_MODE:     DS 1   ; debounce botón secuencia
DB_SPEED:    DS 1   ; debounce botón velocidad

;---------------------------------------------------------
; VECTOR DE RESET
;---------------------------------------------------------
PSECT resetVec
ORG 0x0000
GOTO INIT

;---------------------------------------------------------
; VECTOR DE INTERRUPCIÓN (alta prioridad)
;---------------------------------------------------------
PSECT intVec
ORG 0x0008
 GOTO ISR
 
;---------------------------------------------------------
; INICIALIZACIÓN
;---------------------------------------------------------
PSECT code
INIT:

    ; PORTD como salida (LEDs)
    CLRF LATD,A
    CLRF PORTD,A
    CLRF TRISD,A

    ; RB0 y RB1 como entradas (botones)
    BSF TRISB,0,A
    BSF TRISB,1,A

    ; Inicializar variables
    CLRF TICK,A
    CLRF MODO,A
    CLRF VELOCIDAD,A
    CLRF FLAG_UPDATE,A
    CLRF DB_MODE,A
    CLRF DB_SPEED,A
    MOVLW 0x01
    MOVWF INDICE,A

;---------------------------------------------------------
; CONFIGURAR TIMER0
;---------------------------------------------------------

    MOVLW 0b10000111     ; Timer0 ON, 16bit, prescaler 256
    MOVWF T0CON,A

    ; Precarga para ~10ms (depende del cristal)
    MOVLW 0x63
    MOVWF TMR0H,A
    MOVLW 0xC0
    MOVWF TMR0L,A

    BSF INTCON,5,A       ; habilita Timer0
    BSF INTCON,7,A        ; Habilita interrupciones globales

;---------------------------------------------------------
; CONFIGURAR INTERRUPCIONES EXTERNAS
;---------------------------------------------------------

    BSF INTCON,4,A
    BCF INTCON2,6,A    ; Flanco descendente

    BSF INTCON3,3,A
    BCF INTCON2,7,A    ; Flanco descendente

;---------------------------------------------------------
; BUCLE PRINCIPAL
;---------------------------------------------------------

MAIN:
    ; Espera hasta que Timer0 indique actualización
    BTFSS FLAG_UPDATE,0,A
    GOTO MAIN

    BCF FLAG_UPDATE,0,A

    MOVF MODO,W,A
    SUBLW 0x00
    BZ SEQ1
    
    MOVF MODO,W,A
    SUBLW 0x01
    BZ SEQ2

    MOVF MODO,W,A
    SUBLW 0x02
    BZ SEQ3

    GOTO SEQ4

    
;---------------------------------------------------------
; SECUENCIA 1  Corrimiento derecha
;---------------------------------------------------------

SEQ1:
    MOVF INDICE,W,A
    MOVWF LATD,A

    RLNCF INDICE,F,A
    MOVLW 0x10
    CPFSGT INDICE,A
    MOVLW 0x01
    MOVWF INDICE,A
    RETURN
;---------------------------------------------------------
; SECUENCIA 2 Corrimiento izquierda
;---------------------------------------------------------

SEQ2:
    MOVF INDICE,W,A
    MOVWF LATD,A

    RRNCF INDICE,F,A
    MOVLW 0x00
    CPFSLT INDICE,A
    MOVLW 0x08
    MOVWF INDICE,A
    RETURN
;---------------------------------------------------------
; SECUENCIA 3  Par/Impar
;---------------------------------------------------------

SEQ3:
    MOVLW 0x0A
    MOVWF LATD,A
    RETURN

;---------------------------------------------------------
; SECUENCIA 4  Toggle completo
;---------------------------------------------------------

SEQ4:
    COMF LATD,F,A

;---------------------------------------------------------
; INTERRUPCIONES
;---------------------------------------------------------

ISR:

    ; Timer0
    BTFSC INTCON,2,A
    CALL ISR_TIMER0

    ; INT0
    BTFSC INTCON,4,A
    CALL ISR_INT0

    ; INT1
    BTFSC INTCON3,3,A
    CALL ISR_INT1

    RETFIE

;---------------------------------------------------------
; ISR TIMER0
;---------------------------------------------------------

ISR_TIMER0:

    BCF INTCON,2,A

    ; Recargar Timer0
    MOVLW 0x63
    MOVWF TMR0H,A
    MOVLW 0xC0
    MOVWF TMR0L,A
    INCF TICK,F,A

    ; Decrementar debounce si >0
    MOVF DB_MODE,W,A
    BTFSC STATUS,2,A
    GOTO SKIP_MODE
    DECF DB_MODE,F,A
    
SKIP_MODE:
    MOVF DB_SPEED,W,A
    BTFSC STATUS,2,A
    GOTO SKIP_SPEED
    DECF DB_SPEED,F,A
SKIP_SPEED:

    ; Verificar velocidad
    BTFSC VELOCIDAD,0,A
    GOTO RAPIDA
    
LENTA:
    MOVLW 30
    CPFSGT TICK,A
    RETURN
    GOTO ACTUALIZAR

RAPIDA:
    MOVLW 10
    CPFSGT TICK,A
    RETURN

ACTUALIZAR:
    CLRF TICK,A
    BSF FLAG_UPDATE,0,A
    RETURN

;---------------------------------------------------------
; ISR INT0 Cambiar secuencia con debounce
;---------------------------------------------------------

ISR_INT0:

    BCF INTCON,4,A  ; Limpiar bandera INT0
    MOVF DB_MODE,W,A
    BTFSC STATUS,2,A           ; Si DB_MODE = 0
    GOTO OK_MODE
    RETURN
    
OK_MODE:
    INCF MODO,F,A
    MOVLW 4
    CPFSEQ MODO,A
    MOVLW 5                ; Valor de debounce (~50 ms)
    MOVWF DB_MODE,A
    RETURN
;---------------------------------------------------------
; ISR INT1  Cambiar velocidad
;---------------------------------------------------------

ISR_INT1:

    BCF INTCON3,3,A ; Limpiar bandera INT1
    MOVF DB_SPEED,W,A
    BTFSC STATUS,2,A
    GOTO OK_SPEED
    RETURN
    
OK_SPEED:
    COMF VELOCIDAD,F,A
    MOVLW 5                ; Valor de debounce (~50 ms)
    MOVWF DB_SPEED,A
    RETURN

END
