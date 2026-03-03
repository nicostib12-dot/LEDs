;========================================================
; PROYECTO: 3 Velocidades + 4 Secuencias de LEDs
; Microcontrolador: PIC18F4550
; Oscilador: Interno 8 MHz
;
; RB0 -> Cambia secuencia (INT0 - interrupción externa)
; RB1 -> Cambia velocidad (por polling con anti-rebote)
; RD0?RD3 -> LEDs
;========================================================

#include <xc.inc>        ; Incluye definiciones del dispositivo para pic-as

;========================================================
; BITS DE CONFIGURACIÓN
;========================================================

CONFIG  FOSC = INTOSCIO_EC   ; Oscilador interno, RA6/RA7 como I/O
CONFIG  WDT = OFF            ; Watchdog Timer desactivado
CONFIG  LVP = OFF            ; Programación en bajo voltaje desactivada
CONFIG  PBADEN = OFF         ; PORTB inicia como digital
CONFIG  MCLRE = OFF          ; Pin MCLR como entrada digital
CONFIG  XINST = OFF          ; Set extendido de instrucciones desactivado
CONFIG  PWRT = ON            ; Activa Power-up Timer

;========================================================
; VARIABLES EN RAM (ACCESS BANK)
;========================================================

PSECT udata_acs              ; Sección de datos en banco de acceso rápido

Secuencia:   DS 1            ; Guarda la secuencia actual (0?3)
Velocidad:   DS 1            ; Guarda la velocidad actual (0?2)
Delay1:      DS 1            ; Contador externo de retardo
Delay2:      DS 1            ; Contador medio de retardo
Delay3:      DS 1            ; Contador interno de retardo
Direccion:   DS 1            ; Dirección para modo Ping-Pong
SecTmp:      DS 1            ; Copia temporal de Secuencia
BtnState:    DS 1            ; Controla estado del botón velocidad
Debounce:    DS 1            ; Contador para anti-rebote

;========================================================
; VECTORES
;========================================================

PSECT resetVec,class=CODE,reloc=2
ORG 0x00                     ; Dirección de reset
GOTO INIT                    ; Salta a rutina de inicialización

PSECT intVec,class=CODE,reloc=2
ORG 0x08                     ; Vector de interrupción alta prioridad
GOTO ISR                     ; Salta a rutina de interrupción

PSECT code                   ; Sección principal de código

;========================================================
; INICIALIZACIÓN DEL SISTEMA
;========================================================

INIT:

    MOVLW   0x72             ; Configura OSCCON para 8 MHz
    MOVWF   OSCCON

    MOVLW   0x0F             ; Todos los pines como digitales
    MOVWF   ADCON1

    CLRF    Secuencia        ; Inicia en secuencia 0
    CLRF    Velocidad        ; Inicia en velocidad lenta
    CLRF    Direccion        ; Dirección inicial = izquierda
    MOVLW   1
    MOVWF   BtnState         ; Botón listo para detectar pulsación

    CLRF    TRISD            ; PORTD como salida (LEDs)
    CLRF    LATD             ; LEDs apagados

    MOVLW   0x01             ; Enciende primer LED
    MOVWF   LATD

    BSF     TRISB,0          ; RB0 como entrada (INT0)
    BSF     TRISB,1          ; RB1 como entrada (velocidad)

    BCF     INTCON2,6        ; INT0 por flanco descendente
    BCF     INTCON,1         ; Limpia bandera INT0
    BSF     INTCON,4         ; Habilita INT0
    BSF     INTCON,7         ; Habilita interrupciones globales

;========================================================
; BUCLE PRINCIPAL
;========================================================

MAIN:

    CALL    CHECK_VEL        ; Verifica si se presionó botón velocidad

    MOVF    Secuencia,W      ; Carga número de secuencia
    ANDLW   0x03             ; Limita a 0?3
    MOVWF   Secuencia

    MOVF    Secuencia,W
    BZ      SEQ0             ; Si es 0 -> SEQ0

    MOVLW   1
    CPFSEQ  Secuencia
    GOTO    CHECK2
    GOTO    SEQ1             ; Si es 1 -> SEQ1

CHECK2:
    MOVLW   2
    CPFSEQ  Secuencia
    GOTO    SEQ3
    GOTO    SEQ2             ; Si es 2 -> SEQ2

;========================================================
; SECUENCIA 0 - CIRCULAR
;========================================================

SEQ0:
    CALL RETARDO_INT         ; Retardo según velocidad

    RLCF LATD,F              ; Rota LEDs a la izquierda
    MOVF LATD,W
    ANDLW 0x0F               ; Mantiene solo 4 bits
    BNZ S0_OK

    MOVLW 0x01               ; Si se apagaron todos reinicia
    MOVWF LATD
S0_OK:
    GOTO MAIN

;========================================================
; SECUENCIA 1 - PING PONG
;========================================================

SEQ1:
    CALL RETARDO_INT

    MOVF Direccion,W
    BZ LEFT                  ; Si Dirección=0 -> izquierda

RIGHT:
    RRCF LATD,F              ; Rota derecha
    BTFSC LATD,0             ; Si llegó al extremo
    CLRF Direccion           ; Cambia dirección
    GOTO MAIN

LEFT:
    RLCF LATD,F              ; Rota izquierda
    BTFSC LATD,3             ; Si llegó al extremo
    MOVLW 1
    MOVWF Direccion
    GOTO MAIN

;========================================================
; SECUENCIA 2 - ACUMULATIVA
;========================================================

SEQ2:
    CALL RETARDO_INT

    INCF LATD,F              ; Incrementa valor binario
    MOVF LATD,W
    ANDLW 0x0F
    MOVWF LATD

    MOVF LATD,W
    BNZ S2_OK
    CLRF LATD                ; Reinicia si pasa de 1111
S2_OK:
    GOTO MAIN

;========================================================
; SECUENCIA 3 - ALTERNADA
;========================================================

SEQ3:
    CALL RETARDO_INT

    MOVF LATD,W
    XORLW 0x09               ; Compara con 1001
    BZ ALT2

ALT1:
    MOVLW 0x09               ; 1001
    MOVWF LATD
    GOTO MAIN

ALT2:
    MOVLW 0x06               ; 0110
    MOVWF LATD
    GOTO MAIN

;========================================================
; INTERRUPCIÓN EXTERNA RB0 (CAMBIO SECUENCIA)
;========================================================

ISR:

    BTFSS INTCON,1           ; Verifica bandera INT0
    RETFIE

    CALL DEBOUNCE_DELAY      ; Anti-rebote

    BTFSC PORTB,0            ; Si botón liberado salir
    GOTO CLEAR_INT

    INCF Secuencia,F         ; Cambia secuencia

    CLRF LATD
    MOVLW 0x01               ; Reinicia LEDs
    MOVWF LATD

CLEAR_INT:
    BCF INTCON,1             ; Limpia bandera INT0
    RETFIE                   ; Regresa de interrupción

;========================================================
; BOTÓN VELOCIDAD (RB1)
;========================================================

CHECK_VEL:

    BTFSC PORTB,1            ; Si está en 1 (no presionado)
    GOTO RELEASE

    CALL DEBOUNCE_DELAY

    BTFSC PORTB,1
    RETURN

    MOVF BtnState,W
    BZ END_CHECK

    CLRF BtnState
    INCF Velocidad,F         ; Incrementa velocidad

    MOVLW 3
    CPFSEQ Velocidad
    GOTO END_CHECK

    CLRF Velocidad           ; Si llega a 3 reinicia a 0

END_CHECK:
    RETURN

RELEASE:
    MOVLW 1
    MOVWF BtnState
    RETURN

;========================================================
; RETARDO DEPENDIENTE DE VELOCIDAD (INTERRUMPIBLE)
;========================================================

RETARDO_INT:

    MOVF Secuencia,W
    MOVWF SecTmp             ; Guarda secuencia actual

    MOVF Velocidad,W
    BZ LENTA

    MOVLW 1
    CPFSEQ Velocidad
    GOTO RAPIDA

MEDIA:
    MOVLW 4
    GOTO SETVEL

RAPIDA:
    MOVLW 1
    GOTO SETVEL

LENTA:
    MOVLW 8

SETVEL:
    MOVWF Delay1

D1:
    MOVLW 200
    MOVWF Delay2
D2:
    MOVLW 200
    MOVWF Delay3
D3:

    CALL CHECK_VEL           ; Permite cambiar velocidad

    MOVF Secuencia,W
    CPFSEQ SecTmp            ; Si cambia secuencia
    RETURN                   ; Sale del retardo

    DECFSZ Delay3,F
    GOTO D3
    DECFSZ Delay2,F
    GOTO D2
    DECFSZ Delay1,F
    GOTO D1
    RETURN

;========================================================
; RETARDO ANTI-REBOTE
;========================================================

DEBOUNCE_DELAY:

    MOVLW 100
    MOVWF Debounce
DB1:
    MOVLW 200
    MOVWF Delay2
DB2:
    DECFSZ Delay2,F
    GOTO DB2

    DECFSZ Debounce,F
    GOTO DB1

    RETURN

END