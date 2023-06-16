    LIST P=16F887
    include <p16f887.inc>
; CONFIG1
    ; __config 0x3FE6
 __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
__CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
; __config 0xFFFF

CONT3VECES EQU 0X20 ; CUENTA LA CANTIDAD DE VECES QUE SE INTRODUJO MAL EL CODIGO
TEC EQU 0X21 ; GUARDA LA VARIABLE DEL TECLADO 
CONTRA EQU 0X2E
CLAVE EQU 0X22 
CONTTMR1 EQU 0X23 
CONTTMR2 EQU 0X24
AUXTECLADO EQU 0X25
WTEMP EQU 0X26
STATUSTEMP EQU 0X27
AUXMOVER EQU 0X28
REG0 EQU 0X29
REG1 EQU 0X2A
REG2 EQU 0X2B
REG3 EQU 0X2C
CONTD EQU 0X2D
CLAV0 EQU 0X30
CLAV1 EQU 0X31
CLAV2 EQU 0X32
CLAV3 EQU 0X33
CONTCHAR EQU 0X34
FINCHAR EQU .17
AUXILIAR EQU .11
	ORG 0X00
	GOTO INICIO
 
	ORG 0X04
	GOTO ISR
	
	
; ----------------- INICIO --------------------------	
INICIO	
	BANKSEL TRISB
	MOVLW 0XFF ; 00000001
	MOVWF TRISB
	CLRF TRISA
	CLRF TRISC
	BSF TRISC, 7
	;CLRF TRISD
	BANKSEL ANSELH
	CLRF ANSELH
	CLRF ANSEL
	BANKSEL PORTB
	CLRF PORTA
	CLRF PORTB
	CLRF PORTC
	;CLRF PORTD
	MOVLW .3
	MOVWF CONT3VECES ; ESTA EN EL MISMO BANCO QUE EL PORTB
	MOVLW .256
	MOVWF CONTTMR1
	MOVLW .2
	MOVWF CONTTMR2
	MOVLW AUXILIAR
	MOVWF CONTCHAR
	MOVLW .1
	MOVWF CLAV0
	MOVLW .2
	MOVWF CLAV1
	MOVLW .3
	MOVWF CLAV2
	MOVLW .4
	MOVWF CLAV3
	
;-----------------------CFG PUERTO SERIE ------------------------------------------------
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
;-----------------------------CFG PUERTO SERIE------------------------------
	BANKSEL OPTION_REG
	MOVLW 0X07 ; 00000111 REVISAR RBPU
	MOVWF OPTION_REG
	MOVLW 0X90 ; 10010000
	MOVWF INTCON
	
LOOP	CALL TECLADO
	MOVF CONTRA, 0
	CALL MOVER
	
;-------------------------------------------------------------------------------	
	;BTFSS   TXSTA, TRMT ; Espera hasta que el registro de transmisión esté vacío
	;GOTO    $-1
	;BANKSEL TXREG
	;MOVWF   TXREG ; Transmite el valor del ADC por Bluetooth
	;CALL    DELAY
	GOTO LOOP
;-------------------------------------------------------------------------------	
;	CALL TEC7SEG	;----- PROB NO LO USEMOS -----
;	CALL MOVER	;----- PROB NO LO USEMOS -----
;	CALL MOSTRAR	;----- PROB NO LO USEMOS -----
;	GOTO LOOP	;----- PROB NO LO USEMOS -----
;-------------------------------------------------------------------------------
;-----------------------------------ISR-----------------------------------------
;-------------------------------------------------------------------------------
ISR	
	MOVWF WTEMP
	SWAPF STATUS, W
	MOVWF STATUSTEMP
	;BTFSC INTCON, T0IF
	;GOTO ISRTMR0 ; COMO HACEMOS SI NO QUEREMOS QUE PREGUNTE LO SIGUIENTE 
	BTFSC INTCON, INTF
	GOTO ISRRBO
RET	SWAPF STATUSTEMP, W
	MOVWF STATUS
	SWAPF WTEMP, F
	SWAPF WTEMP, W
	RETFIE
	
ISRRBO	
;-------------------------------------------------------------------------------
;---------------------------MOSTRAMOS LOS 4 CARACTERES--------------------------
	BANKSEL PORTA
	BSF PORTA,2
	movf REG3, W
	CALL CARACTERES
	MOVWF TXREG ;CADENA EN TX
	BSF STATUS, RP0
	BTFSS TXSTA, TRMT ;CHECKEO EMPTY
	GOTO $-1
	BCF STATUS, RP0
	movf REG2, W
	CALL CARACTERES
	MOVWF TXREG ;CADENA EN TX
	BSF STATUS, RP0
	BTFSS TXSTA, TRMT ;CHECKEO EMPTY
	GOTO $-1
	BCF STATUS, RP0
	movf REG1, W
	CALL CARACTERES
	MOVWF TXREG ;CADENA EN TX
	BSF STATUS, RP0
	BTFSS TXSTA, TRMT ;CHECKEO EMPTY
	GOTO $-1
	BCF STATUS, RP0
	movf REG0, W
	CALL CARACTERES
	MOVWF TXREG ;CADENA EN TX
	BSF STATUS, RP0
	BTFSS TXSTA, TRMT ;CHECKEO EMPTY
	GOTO $-1
	BCF STATUS, RP0
	MOVLW FINCHAR
	CALL CARACTERES
	MOVWF TXREG ;CADENA EN TX
	BSF STATUS, RP0
	BTFSS TXSTA, TRMT ;CHECKEO EMPTY
	GOTO $-1
	BCF STATUS, RP0
;-------------------------------------------------------------------------------
	BANKSEL PORTB
	MOVLW REG0
	SUBWF CLAV0, 0
	BTFSS STATUS, Z
	GOTO INCORR
	MOVLW REG1
	SUBWF CLAV1, 0
	BTFSS STATUS, Z
	GOTO INCORR
	MOVLW REG2
	SUBWF CLAV2, 0
	BTFSS STATUS, Z
	GOTO INCORR
	MOVLW REG3
	SUBWF CLAV3, 0
	BTFSS STATUS, Z
	GOTO INCORR
	GOTO LEDVER
INCORR	GOTO LEDROJ
VOLVER	BCF INTCON, INTF
	GOTO RET
	
ISRTMR0	DECFSZ CONTTMR1
	GOTO SETTMR0 ; HAY QUE HACERLA
	DECFSZ CONTTMR2
	GOTO RCONT
	GOTO SETTMR0
	
	
;----------------------- SUBRUTINAS -----------------------------
	
	
LEDVER	
;------------------- Imprimimos contraseña correcta ----------------------------
BACKCV	movf CONTCHAR,W; recorro la cadena de texto en la tabla
	sublw AUXILIAR
	call CORRECTO
	movwf TXREG ;pone un caracter de la cadena en TXREG
	bsf STATUS, RP0 ;bank 1
	btfss TXSTA, TRMT ;checkea si TRMT esta vacio por polling
	goto $-1 
	bcf STATUS, RP0 ;bank 0, si TRMT esta vacio luego el caracter a sido transmitido 
	decfsz CONTCHAR, F; chequeo si fue transmitida toda la cadena
	goto BACKCV
	movlw AUXILIAR
	movwf CONTCHAR; vuelvo a transmitir la cadena
;-------------------------------------------------------------------------------
	BANKSEL PORTA
	BSF PORTA, 0 ; DEFINIR PUERTO DEL LED VERDE
	MOVLW .3
	MOVWF CONT3VECES
	GOTO VOLVER

LEDROJ	
;------------------- Imprimimos contraseña incorrecta --------------------------
BACKC	movf CONTCHAR,W; recorro la cadena de texto en la tabla
	sublw AUXILIAR
	call INCORRECTO
	movwf TXREG ;pone un caracter de la cadena en TXREG
	bsf STATUS, RP0 ;bank 1
	btfss TXSTA, TRMT ;checkea si TRMT esta vacio por polling
	goto $-1 
	bcf STATUS, RP0 ;bank 0, si TRMT esta vacio luego el caracter a sido transmitido 
	decfsz CONTCHAR, F; chequeo si fue transmitida toda la cadena
	goto BACKC
	movlw AUXILIAR
	movwf CONTCHAR; vuelvo a transmitir la cadena
;-------------------------------------------------------------------------------
	BANKSEL PORTA
	BSF PORTA, 1 ; DEFINIR PUERTO DEL LED ROJO
	DECFSZ CONT3VECES, 1
	GOTO VOLVER
	CALL ALARMA ; HAY QUE HACERLO
	BANKSEL TMR0 
	GOTO VOLVER

ALARMA	
	BANKSEL PORTA
	BSF PORTA, 2 ; DEJO BITS 0 Y 1 PARA LOS LEDS
	CALL DELAY
	CALL DELAY  ; Porq si no se va a quedar haciendo ruido xd
	CALL DELAY
	BCF PORTA, 2
	RETURN
	
	
RCONT	MOVLW .256
	MOVWF CONTTMR1   ;delay de 12.8 seg
	MOVLW .2
	MOVWF CONTTMR2 ; 12,8 * 2 = 25.6 seg
	
	
SETTMR0
	BANKSEL TMR0 
	MOVLW .61 ;  TMR0 Interrumpe cada 50ms
	MOVWF TMR0
	RETURN
	
DELAY 
	BANKSEL PORTA ;PARA IR AL BANCO 0
	MOVLW  .5 ;EL PERIODO DE INSTRUCCION ES DE 1 MICROSEG
	MOVWF CONTD ;ENTONCES HAGO UN DELAY AL REDEDOR DE 5MICROSEG(ES MAYOR)
	DECFSZ CONTD,1
	GOTO $-1
	RETURN
	

TECLADO 
	BANKSEL TRISD
	MOVLW 0X0F		;
	MOVWF TRISD		;
	BANKSEL PORTD
	CLRF TEC
BETA	
	BANKSEL PORTD		;
	MOVLW 0X0F		;
	MOVWF PORTD		;
BACK	MOVLW 0X0F		;
	SUBWF PORTD, 0		;TODO ESTO SE EVITA CON INTERRUPCIONES
	BTFSC STATUS, Z		; SI PONERMOS EL TECLADO EN EL PORTB
	GOTO BACK		; 
	CALL DELAY              ; A CFG DESPUES
	CLRF TEC
	MOVLW 0XEE
	MOVWF AUXTECLADO
ALFA	MOVF AUXTECLADO, 0
	BTFSS W, 0
	GOTO GAMMA
	INCF TEC
	BTFSS W, 1
	GOTO GAMMA
	INCF TEC
	BTFSS W, 2
	GOTO GAMMA
	INCF TEC
	BTFSS W, 3
	GOTO GAMMA
	INCF TEC
	RLF AUXTECLADO
	BTFSS STATUS, C
	GOTO BETA
	GOTO ALFA
GAMMA	MOVF TEC,0
	MOVWF CONTRA
BACK2	MOVF PORTD, 0
	ANDLW 0X0F
	SUBLW 0X0F
	BTFSC STATUS, Z
	GOTO BACK2
	RETURN
	;GOTO BETA

;TEC7SEG	ADDWF PCL,1 ; asumiendo que el display es catodo comun
;	RETLW 0X3F
;	RETLW 0X06
;	RETLW 0X5B
;	RETLW 0X4F
;	RETLW 0X66
;	RETLW 0X6D
;	RETLW 0X7D
;	RETLW 0X07
;	RETLW 0X7F
;	RETLW 0X67

MOVER	
	BANKSEL PORTA
	CLRF AUXMOVER
	MOVWF AUXMOVER
	MOVLW REG2
	MOVWF REG3
	MOVLW REG1
	MOVFW REG2
	MOVLW REG0
	MOVWF REG1
	MOVLW AUXMOVER
	MOVWF REG0
	RETURN
;----------------------------TABLAS TRANSMISION---------------------------------
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
CARACTERES
    ADDWF PCL, F
    retlw '0'
    retlw '1'
    retlw '2'
    retlw '3'
    retlw '4'
    retlw '5'
    retlw '6'
    retlw '7'
    retlw '8'
    retlw '9'
    retlw 'A'
    retlw 'B'
    retlw 'C'
    retlw 'D'
    retlw 'E'
    retlw 'F'
    retlw .18
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;MOSTRAR	MOVLW 0X00 ;----- PROB NO LO USEMOS -----;----- PROB NO LO USEMOS -----;----- PROB NO LO USEMOS -----
;	BANKSEL TRISC
;	MOVWF TRISC ;?????????????????????????????????????????
;	MOVWF TRISB ;?????????????????????????????????????????
;LOOP1	MOVLW REG3
;	BANKSEL PORTC
;	MOVWF PORTC
;	BSF PORTD, 0
;	CALL DELAY ; HAY QUE HACERLO
;	CLRF PORTD
;	MOVLW REG2
;	MOVWF PORTC
;	BSF PORTD, 1
;	CALL DELAY
;	CLRF PORTD
;	MOVLW REG1
;	MOVWF PORTC
;	BSF PORTD, 2
;	CALL DELAY
;	CLRF PORTD
;	MOVLW REG0
;	MOVWF PORTC
;	BSF PORTD, 3
;	CALL DELAY
;	CLRF PORTD
;	GOTO LOOP1
    END