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
 
COL_HAB   EQU	    0x35    ; Registros auxiliares para el polling de
COL_HAB_AUX   EQU   0x36    ; filas y columnas.
COLUMN   EQU	    0x37
ROW   EQU	    0x38
MAX_COL   EQU	    0x39   ; Registros con la cantidad de filas y
MAX_ROW   EQU	    0x3A    ; columnas del teclado para limitar la
			      ; decodificación al pulsar una tecla.
FINCHAR EQU .17
AUXILIAR EQU .11
	ORG 0X00
	GOTO INICIO
 
	ORG 0X04
	GOTO ISR
	
	
; ----------------- INICIO --------------------------	
INICIO	
	MOVLW   .4		    ; Cargo 4 como al cantidad de filas y de
	MOVWF   MAX_ROW	    ; columnas del teclado.
	MOVWF   MAX_COL
	
	BANKSEL ANSELH
	CLRF ANSELH
	CLRF ANSEL
	BANKSEL TRISB
	MOVLW 0XFF ; 00000001
	MOVWF TRISB
	BANKSEL TRISD	    ; Seteo RB<0:3> como inputs y RB<4:7> como
	MOVLW   0x0F	    ; outputs.
	CLRF TRISA
	CLRF TRISC
	BSF TRISC, 7
	;CLRF TRISD
	
	BANKSEL PORTB
	CLRF PORTA
	CLRF PORTB
	CLRF PORTC
	BSF PORTC, 7
	CLRF PORTD
	CLRF REG0
	CLRF REG1
	CLRF REG2
	CLRF REG3
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
	BANKSEL PORTA
	BCF PORTA,2
	GOTO LOOP
LOOP	
	;CALL TECLADO
	CALL KEY_POLL
	GOTO $-1
;	GOTO MOVER
;ATRASMOV
;	GOTO LOOP
	
	

KEY_POLL    
	    
	    MOVFW   PORTD	    ; Leo el nibble inferior de PORTB, y hago
	    ANDLW   0x0F	    ; 0x0F - W. Si la resta da 0 significa que
	    MOVWF   COL_HAB	    ; ninguna tecla fue presionada así que en
	    MOVWF   COL_HAB_AUX	    ; ese caso vuelvo a KEY_POLL.
	    SUBLW   0x0F	    ; Si no da cero significa que alguna tecla
	    BTFSC   STATUS,Z	    ; fue presionada y allí comienzo la
	    GOTO    KEY_POLL	    ; decodificación de la fila y columna.
	    GOTO    COL_DEC

COL_DEC	    
	    BANKSEL PORTA
	    BSF PORTA, 3
	    RRF	    COL_HAB,F	    ; Roto COL_HAB hacia la derecha hasta que el
	    BTFSS   STATUS,C	    ; 0 llegue al carry. A medida que roto, voy
	    GOTO    ROW_DEC	    ; incrementando una variable que cuenta las
	    INCF    COLUMN,F	    ; columnas (siempre verificando no pasar el
	    MOVFW   COLUMN	    ; límite de columnas del teclado). Cuando el
	    SUBWF   MAX_COL,W	    ; 0 llega al carry significa que encontré la
	    BTFSC   STATUS,Z	    ; columna y voy a buscar la fila.
	    GOTO    FINISH
	    GOTO    COL_DEC
	    
ROW_DEC	    MOVFW   ROW		    ; Envío por PORTB de a uno los valores de la
	    CALL    ROWS_TEST	    ; tabla ROWS_TEST. Chequeo el nibble
	    MOVWF   PORTD	    ; inferior del resultado de la resta entre
	    MOVF   COL_HAB_AUX,W	    ; PORTB y COL_HAB_AUX hasta encontrar el
	    SUBWF   PORTD,W	    ; mismo valor de fila (la resta daría 0).
	    ANDLW   0x0F	    ; A medida que mando valores incremento la
	    BTFSC   STATUS,Z	    ; variable contadora ROW. Cuando encuentro
	    GOTO    SHOW_RES	    ; el valor de fila, voy a mostrar el
	    INCF    ROW		    ; resultado por PORTD.
	    MOVFW   ROW
	    SUBWF   MAX_ROW,W
	    BTFSC   STATUS,Z
	    GOTO    FINISH
	    GOTO    ROW_DEC
	    
SHOW_RES    BCF	    STATUS,C	    ; Limpio el bit de carry.
	    RLF	    ROW,F	    ; La posición de la tecla viene dada por la
	    RLF	    ROW,W	    ; ecuación KEY = 4*ROW + COLUMN. Para esto,
	    ADDWF   COLUMN,W	    ; roto dos veces hacia la izquierda a ROW
	    
	    ;CLRF    AUXMOVER
	    CALL    TEC2DEC
	    
;-------------------------------------------------------------------------------
;	    MOVWF AUXMOVER
;	    BTFSC REG0,Z
;	    MOVWF REG0
;	    BTFSC REG1,Z
;	    MOVWF REG1
;	    BTFSC REG2,Z
;	    MOVWF REG2
;	    MOVWF REG3
;-------------------------------------------------------------------------------
	    
	    CALL    MOVER
	    GOTO    FINISH
FINISH    
	    CLRF    PORTD	    ; Limpio PORTB y reseteo los valores de
	    CLRF    ROW		    ; fila y columna para la próxima búsqueda.
	    CLRF    COLUMN
	    return
	

;-------------------------------------------------------------------------------
;-----------------------------------ISR-----------------------------------------
;-------------------------------------------------------------------------------
ISR	
	MOVWF WTEMP
	SWAPF STATUS, W
	MOVWF STATUSTEMP
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
;	movf REG0, W
;	CALL CARACTERES
;	MOVWF TXREG ;CADENA EN TX
;	BSF STATUS, RP0
;	BTFSS TXSTA, TRMT ;CHECKEO EMPTY
;	GOTO $-1
;	BCF STATUS, RP0
;	movf REG2, W
;	CALL CARACTERES
;	MOVWF TXREG ;CADENA EN TX
;	BSF STATUS, RP0
;	BTFSS TXSTA, TRMT ;CHECKEO EMPTY
;	GOTO $-1
;	BCF STATUS, RP0
;	movf REG1, W
;	CALL CARACTERES
;	MOVWF TXREG ;CADENA EN TX
;	BSF STATUS, RP0
;	BTFSS TXSTA, TRMT ;CHECKEO EMPTY
;	GOTO $-1
;	BCF STATUS, RP0
;	movf REG0, W
;	CALL CARACTERES
;	MOVWF TXREG ;CADENA EN TX
;	BSF STATUS, RP0
;	BTFSS TXSTA, TRMT ;CHECKEO EMPTY
;	GOTO $-1
;	BCF STATUS, RP0
;	MOVLW FINCHAR
;	CALL CARACTERES
;	MOVWF TXREG ;CADENA EN TX
;	BSF STATUS, RP0
;	BTFSS TXSTA, TRMT ;CHECKEO EMPTY
;	GOTO $-1
;	BCF STATUS, RP0
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
	BANKSEL TMR0 
	GOTO VOLVER

	
	
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
	

;TECLADO 
;	    RETURN
	
TEC2DEC  ADDWF   PCL,F	    ; Retorno el valor en decimal para comparar.
	    RETLW   .7	    ; (0,0) = 7
	    RETLW   .8	    ; (0,1) = 8
	    RETLW   .9	    ; (0,2) = 9
	    RETLW   .10	    ; (0,3) = A
	    RETLW   .4	    ; (1,0) = 4
	    RETLW   .5	    ; (1,1) = 5
	    RETLW   .6	    ; (1,2) = 6
	    RETLW   .11	    ; (1,3) = B
	    RETLW   .1	    ; (2,0) = 1
	    RETLW   .2	    ; (2,1) = 2
	    RETLW   .3	    ; (2,2) = 3
	    RETLW   .12	    ; (2,3) = C
	    RETLW   .14	    ; (3,0) = E
	    RETLW   .0	    ; (3,1) = 0
	    RETLW   .15	    ; (3,2) = F
	    RETLW   .13	    ; (3,3) = D

	    
ROWS_TEST   
	    ADDWF   PCL,F	    ; Sumo al PC el valor de fila y retorno el
	    RETLW   0xEF	    ; número binario a mostrar por PORTB para
	    RETLW   0xDF	    ; testear cada fila (mando un '0' en RB4 con
	    RETLW   0xBF	    ; 0xEF, un '0' por RB5 con 0xDF y así)
	    RETLW   0x7F	    ; mientras el resto de pines queda en '1'.

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

    
    
    END
