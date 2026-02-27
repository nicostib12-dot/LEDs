;========================================================
; PROGRAMA: LED 1s ENCENDIDO - 2s APAGADO
; MICRO: PIC18F4550
; MÉTODO: Timer0 modo 16 bits (Polling)
; SOLO SE CONFIGURA RB0 COMO SALIDA
;========================================================

        LIST P=18F4550
        #include <p18f4550.inc>

;========================================================
; VARIABLES EN RAM
;========================================================

CBLOCK 0x20
    CONTADOR        ; Cuenta los desbordamientos (cada 50ms)
    ESTADO          ; 0 = LED apagado, 1 = LED encendido
ENDC

;========================================================
; VECTOR DE RESET
;========================================================

        ORG 0x00
        GOTO START

;========================================================
; INICIO DEL PROGRAMA
;========================================================

START:

    ;--------------------------------------------
    ; Configurar SOLO RB0 como salida
    ;--------------------------------------------

    BCF TRISB, 0        ; Bit 0 de TRISB = 0 ? RB0 como salida
    BCF LATB, 0         ; Inicializar RB0 en 0 ? LED apagado

    ;--------------------------------------------
    ; Inicializar variables
    ;--------------------------------------------

    CLRF CONTADOR
    CLRF ESTADO         ; Comenzamos con LED apagado

    ;--------------------------------------------
    ; Configurar Timer0
    ;--------------------------------------------
    ; T0CON = 10000111
    ; Bit 7 = 1 ? Encender Timer0
    ; Bit 6 = 0 ? Modo 16 bits
    ; Bit 5 = 0 ? Fuente interna (Fosc/4)
    ; Bit 2-0 = 111 ? Prescaler 1:256
    ;--------------------------------------------

    MOVLW b'10000111'
    MOVWF T0CON

    ;--------------------------------------------
    ; Precargar Timer0 para 50 ms
    ; Valor calculado: 0xFE7A
    ;--------------------------------------------

    MOVLW 0xFE
    MOVWF TMR0H
    MOVLW 0x7A
    MOVWF TMR0L

;========================================================
; BUCLE PRINCIPAL
;========================================================




