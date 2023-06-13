    LIST P=16F887
    include <p16f887.inc>
; CONFIG1
    ; __config 0x3FE6
 __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
__CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
; __config 0xFFFF
	;AUXILIAR EQU 0X20
	CONTD EQU 0X20
	COUNT1 EQU 0X21
	
	ORG 0X00
	GOTO INICIO
	
INICIO
    bsf STATUS, RP0 ;bank 1
;---CONFIGURA SPBRG para el valor deseado de Baud rate
    movlw D'25' ;baud rate = 9600bps
    movwf SPBRG ;a 4MHZ
;---CONFIGURA TXSTA
    movlw B'00100100'
    movwf TXSTA
;Configuro TXSTA como 8 bit transmission, tx habilitado, modo async, high speed baud rate
    bcf STATUS, RP0 ;bank 0
    movlw B'10000000'
    movwf RCSTA ;habilita los pines para recepción por puerto serie
    movlw .11
    movwf COUNT1; cargo contador de cantidad de caracteres de cadena
    GOTO INIT
    
    
INIT
	MOVF COUNT1, W
	SUBLW .11
	CALL CORRECTO
	MOVWF TXREG ;CADENA EN TX
	BSF STATUS, RP0
	BTFSS TXSTA, TRMT ;CHECKEO EMPTY
	GOTO $-1
	BCF STATUS, RP0
	DECFSZ COUNT1, 1
	GOTO INIT
	MOVLW .11
	MOVWF COUNT1
	GOTO INIT

INCORRECTO
    addwf PCL, F
    retlw 'I'
    retlw 'N'
    retlw 'C'
    retlw 'O'
    retlw 'R'
    retlw 'R'
    retlw 'E'
    retlw 'C'
    retlw 'T'
    retlw 'O'
    retlw .13
CORRECTO
    addwf PCL, F   ; tengo q poner CHAR no int
    retlw ' '
    retlw ' '
    retlw 'C'
    retlw 'O'
    retlw 'R'
    retlw 'R'
    retlw 'E'
    retlw 'C'
    retlw 'T'
    retlw 'O'
    retlw .13 
	;BANKSEL TRISA
	;CLRF TRISA
	;BANKSEL TXSTA
	;BSF TXSTA,1
	;BANKSEL PORTA
	;BSF PORTA,0
	;BCF PORTA,0
	;MOVLW D'5'
	;MOVWF AUXILIAR
;LOOP	;MOVLW '5'
	
;	BTFSS   TXSTA, TRMT ; registro de transmisión en empty
;	GOTO    $-1
;	BSF PORTA,0
;	BANKSEL TXREG
;	MOVWF   TXREG ; Transmite 
;	CALL    DELAY
;	BCF PORTA,0
;	CALL DELAY
;	;BSF PORTA,0
;	DECFSZ AUXILIAR,0
;	;CALL TX_DATO
;	GOTO LOOP
;	GOTO FIN

DELAY 
	BANKSEL PORTA ;PARA IR AL BANCO 0
	MOVLW  .256 ;EL PERIODO DE INSTRUCCION ES DE 1 MICROSEG
	MOVWF CONTD ;ENTONCES HAGO UN DELAY AL REDEDOR DE 5MICROSEG(ES MAYOR)
	DECFSZ CONTD,1
	GOTO $-1
	RETURN
;TX_DATO
;	MOVWF TXREG1
;TXD	
;	BTFSS TXSTA1, TRMT
;	GOTO TXD
;	BCF PIR1, TX1IF
;	RETURN
	
	
;FIN	
END


