 

    #include <xc.inc>   ; Incluir definiciones del ensamblador para PIC18F4550

    ; Configuración de bits de configuración (Fuses)
    CONFIG  FOSC = INTOSCIO_EC   ; Usa el oscilador interno a 8 MHz
    CONFIG  WDT = OFF            ; Deshabilitar el Watchdog Timer
    CONFIG  LVP = OFF            ; Deshabilitar la programación en bajo voltaje
    CONFIG  PBADEN = OFF         ; Configurar los pines de PORTB como digitales

    ;===============================================
    ; Vectores de Inicio
    ;===============================================

    PSECT  resetVec, class=CODE, reloc=2  ; Sección para el vector de reinicio
    ORG     0x00                          ; Dirección de inicio
    GOTO    Inicio                         ; Saltar a la rutina de inicio

    ;===============================================
    ; Código Principal
    ;===============================================
    
    PSECT  main_code, class=CODE, reloc=2  ; Sección de código principal

Inicio:
    CLRF    TRISB       ; Configurar PORTB como salida (0 = salida, 1 = entrada)
    CLRF    LATB        ; Apagar todos los pines de PORTB (LED apagado inicialmente)
    MOVLW 0x72
MOVWF OSCCON
MOVLW   0b10000111
MOVWF   T0CON
Loop:
    BSF     LATB,0
    CALL    retraso_1s

    BCF     LATB,0
    CALL    retraso_2s

    GOTO    Loop

;=========================
; 1 segundo
;=========================

retraso_1s:

    MOVLW   0xE1
    MOVWF   TMR0H
    MOVLW   0x6B
    MOVWF   TMR0L
    BCF     INTCON,2

Esperar1:
    BTFSS   INTCON,2
    GOTO    Esperar1

    RETURN

; 2 segundos
 retraso_2s:

    MOVLW   0xC2
    MOVWF   TMR0H
    MOVLW   0xF7
    MOVWF   TMR0L

    BCF     INTCON,2

Esperar2:
    BTFSS   INTCON,2
    GOTO    Esperar2
     RETURN
END
