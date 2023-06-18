;   Ejercicio 6.1: (LA CONSIGNA SE CAMBIÓ PARA SIMPLICIDAD)
;
;   Realizar un programa que obtenga el valor de la tecla que se pulsa en un
;   teclado estándar de 4x4 conectado al puerto B de un microcontrolador
;   PIC16F887. El valor de la tecla se mostrará en un display 7 segmentos de
;   cátodo común conectado a PORTD. A continuación se muestra el reemplazo de
;   valores en el teclado KEYPAD-SMALLCALC ofrecido por Proteus:
;
;   * TECLA '/' -> A
;   * TECLA 'X' -> B
;   * TECLA '-' -> C
;   * TECLA '+' -> D
;   * TECLA 'ON/C' -> E
;   * TECLA '=' -> F
;
;   Se pide resolución utilizando el método polling.

;-------------------LIBRERIAS---------------------------------------------------
    LIST P=16F887
    include <p16f887.inc>
; CONFIG1
    ; __config 0x3FE6
 __CONFIG _CONFIG1, _FOSC_INTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
__CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
; __config 0xFFFF

;-------------------DECLARACION DE VARIABLES------------------------------------

		    ORG	    0x00
		    GOTO CFG
		    ORG	    0X04
		    GOTO ISR
	
	  COL_HAB   EQU	    0x20    ; 1Registros auxiliares para el polling de
      COL_HAB_AUX   EQU	    0x21    ;1 filas y columnas.
	   COLUMN   EQU	    0x22
	      ROW   EQU	    0x23
	  MAX_COL   EQU	    0x24    ; Registros con la cantidad de filas y
	  MAX_ROW   EQU	    0x25    ; columnas del teclado para limitar la
				    ; decodificación al pulsar una tecla.
	    CONTD   EQU	    0X26
	    REG0    EQU	0X27
	    CONTTEC EQU 0X28
	    CONTDELAY2 EQU 0X29
CLAV0 EQU 0x2D
CLAV1 EQU 0x2A
CLAV2 EQU 0x2B
CLAV3 EQU 0x2C
;REG0 EQU 0X31
REG1 EQU 0X32
REG2 EQU 0X33
REG3 EQU 0X34
AUXMOVER EQU 0X30
WTEMP        EQU    0X70
STATUSTEMP   EQU    0X71

;-------------------CONFIGURACION DE REGISTROS----------------------------------
CFG
            MOVLW   .4		    ; Cargo 4 como al cantidad de filas y de
	    MOVWF   MAX_ROW	    ; columnas del teclado.
	    MOVWF   MAX_COL
	    MOVWF CONTTEC
	    MOVLW   .10
	    MOVWF   CONTDELAY2
	    MOVLW	.1
	    MOVWF	CLAV0
	    MOVLW	.2
	    MOVWF	CLAV1
	    MOVLW	.3
	    MOVWF	CLAV2
	    MOVLW	.4
	    MOVWF	CLAV3
	    MOVLW	.2
	    MOVWF	REG0
	    MOVLW	.2
	    MOVWF	REG1
	    MOVLW	.3
	    MOVWF	REG2
	    MOVLW	.4
	    MOVWF	REG3
	    CLRF AUXMOVER
	    BANKSEL TRISD	    ; Seteo PORTD como output.
	    CLRF    TRISD
	    BANKSEL TRISB	    ; Seteo RB<0:3> como inputs y RB<4:7> como
	    MOVLW   0x0F	    ; outputs.
	    MOVWF   TRISB
	    BANKSEL TRISA
	    CLRF    TRISA
	    BANKSEL ANSELH	    ; Seteo PORTB como puerto digital.
	    CLRF    ANSELH
	    BANKSEL OPTION_REG	    ; Habilito resistencias de pull-up en PORTB.
	    CLRF    OPTION_REG
	    BANKSEL WPUB	    ; Seteo las resistencias de pull-up.
	    MOVLW   0x0F
	    MOVWF   WPUB
	    BANKSEL INTCON
	    BSF     INTCON, GIE ; Habilita las interrupciones globales
	    BCF     INTCON, T0IE ; Deshabilita la interrupción del temporizador 0
	    BCF     INTCON, T0IF ; Limpia la bandera de interrupción del temporizador 0
	    BCF     INTCON, INTE ; Habilita la interrupción externa
	    BCF     INTCON, INTF ; Limpia la bandera de interrupción externa
	    
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
	    
	    BANKSEL PORTB	    ; Vuelvo al banco de PORTB para comenzar.
	    CLRF    PORTB	    ; Limpio los registros a utilizar para
	    CLRF    PORTD	    ; evitar basura de ejecuciones anteriores.
	    CLRF    PORTA
	    CLRF    COLUMN
	    CLRF    ROW
	    CLRW
	    GOTO MAIN

;-------------------INICIO DEL PROGRAMA-----------------------------------------
MAIN
	    CALL    KEY_POLL	    ; Hago polling indefinidamente.
	    GOTO    $-1

KEY_POLL    MOVFW   PORTB	    ; Leo el nibble inferior de PORTB, y hago
	    ANDLW   0x0F	    ; 0x0F - W. Si la resta da 0 significa que
	    MOVWF   COL_HAB	    ; ninguna tecla fue presionada así que en
	    MOVWF   COL_HAB_AUX	    ; ese caso vuelvo a KEY_POLL.
	    SUBLW   0x0F	    ; Si no da cero significa que alguna tecla
	    BTFSC   STATUS,Z	    ; fue presionada y allí comienzo la
	    GOTO    KEY_POLL	    ; decodificación de la fila y columna.
	    GOTO    COL_DEC

 COL_DEC    
	    CALL DELAY
	    RRF	    COL_HAB,F	    ; Roto COL_HAB hacia la derecha hasta que el
	    BTFSS   STATUS,C	    ; 0 llegue al carry. A medida que roto, voy
	    GOTO    ROW_DEC	    ; incrementando una variable que cuenta las
	    INCF    COLUMN,F	    ; columnas (siempre verificando no pasar el
	    MOVFW   COLUMN	    ; límite de columnas del teclado). Cuando el
	    SUBWF   MAX_COL,W	    ; 0 llega al carry significa que encontré la
	    BTFSC   STATUS,Z	    ; columna y voy a buscar la fila.
	    GOTO    FINISH
	    GOTO    COL_DEC
	    
 ROW_DEC    
	    MOVFW   ROW		    ; Envío por PORTB de a uno los valores de la
	    CALL    ROWS_TEST	    ; tabla ROWS_TEST. Chequeo el nibble
	    MOVWF   PORTB	    ; inferior del resultado de la resta entre
	    MOVFW   COL_HAB_AUX	    ; PORTB y COL_HAB_AUX hasta encontrar el
	    SUBWF   PORTB,W	    ; mismo valor de fila (la resta daría 0).
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
	    CALL    TEC2DEC	    ; (eso me da 4*ROW) y al resultado le sumo
	    MOVWF   AUXMOVER
	    
;	    
	    
	    BANKSEL PORTB
	    MOVF    REG2, W
	    MOVWF   REG3
	    MOVF    REG1,W
	    MOVWF   REG2
	    MOVF    REG0,W
	    MOVWF   REG1
	    MOVF    AUXMOVER,W
	    MOVWF   REG0
	    MOVF    AUXMOVER,W
	    CALL    CARACTERES
	    MOVWF TXREG ;CADENA EN TX
	    BSF STATUS, RP0
	    BTFSS TXSTA, TRMT ;CHECKEO EMPTY
	    GOTO $-1
	    BCF STATUS, RP0
	    CLRF PORTB 
	    GOTO    FINISH	    ; valor correspondiente a mostrar por PORTD.

  FINISH    
	    CLRF    PORTB	    ; Limpio PORTB y reseteo los valores de
	    CLRF    ROW		    ; fila y columna para la próxima búsqueda.
	    CLRF    COLUMN
	    CLRW
SOLTO
	    MOVFW   PORTB	    ; Leo el nibble inferior de PORTB, y hago
	    ANDLW   0x0F	    ; 0x0F - W. Si la resta da 0 significa que
	    SUBLW   0x0F	    ; Si no da cero significa que la tecla
	    BTFSS   STATUS,Z	    ; se soltó
	    GOTO SOLTO
	    
	    DECF  CONTTEC,1 ;CONT--
	    MOVF    CONTTEC,W;	TESTEO SI CONTTEC=0
	    BTFSC  STATUS,Z;	
	    CALL    SET_TMR;CONTTEC=0--> SETEO TMR
	    RETURN
SET_TMR
	BANKSEL INTCON
	BSF INTCON, T0IE ;Solo habilito tmr isr si se ingresaron 4 teclas
	BANKSEL TMR0 
	MOVLW .250 ;  TMR0 Interrumpe
	MOVWF TMR0
	RETURN
	
	
	DELAY2	
	DECFSZ CONTDELAY2
	GOTO	$-1
	RETURN
	
;-------------------------------INTERRUPCIONES----------------------------------
;-------------------------------INTERRUPCIONES----------------------------------
;-------------------------------INTERRUPCIONES----------------------------------
	
ISR
	BANKSEL PORTA
	BSF PORTA, RA3
	MOVWF WTEMP
	SWAPF STATUS, W
	MOVWF STATUSTEMP
	BTFSC INTCON, T0IF
	CALL ISR_TIMER
RET	
	SWAPF STATUSTEMP, W
	MOVWF STATUS
	SWAPF WTEMP, F
	SWAPF WTEMP, W
	RETFIE
	
ISR_TIMER
	
	BANKSEL PORTB
	clrf STATUS
	MOVF CLAV0,W
	SUBWF REG0,W
	BTFSS STATUS, Z
	GOTO LEDROJO
	MOVF REG1,W
	SUBWF CLAV1, W
	BTFSS STATUS, Z
	GOTO LEDROJO
	MOVF REG2,W
	SUBWF CLAV2, W
	BTFSS STATUS, Z
	GOTO LEDROJO
	MOVF REG3,W
	SUBWF CLAV3, W
	BTFSS STATUS, Z
	GOTO LEDROJO
	GOTO LEDVERDE
;-------
VOLVER
	BANKSEL INTCON
	BCF INTCON, T0IF
	BCF INTCON, T0IE; Desactivo interrup por tmr0
	RETURN
;;;;
LEDROJO
	BANKSEL PORTA
	BSF PORTA,RA1
	CALL DELAY2
	CALL DELAY2
	;BCF PORTA, RA1
	GOTO VOLVER
LEDVERDE
	BANKSEL PORTA
	BSF PORTA,RA0	
	CALL DELAY2
	CALL DELAY2
	;BCF PORTA, RA0
	GOTO VOLVER
;-------------------TABLAS------------------------------------------------------

ROWS_TEST   ADDWF   PCL,F	    ; Sumo al PC el valor de fila y retorno el
	    RETLW   0xEF	    ; número binario a mostrar por PORTB para
	    RETLW   0xDF	    ; testear cada fila (mando un '0' en RB4 con
	    RETLW   0xBF	    ; 0xEF, un '0' por RB5 con 0xDF y así)
	    RETLW   0x7F	    ; mientras el resto de pines queda en '1'.

TEC2DEC
	    ADDWF   PCL,F	    ; Retorno el valor a mostrar por el display.
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
	    
DELAY 
	BANKSEL PORTA ;PARA IR AL BANCO 0
	MOVLW  .5 ;EL PERIODO DE INSTRUCCION ES DE 1 MICROSEG
	MOVWF CONTD ;ENTONCES HAGO UN DELAY AL REDEDOR DE 5MICROSEG(ES MAYOR)
	DECFSZ CONTD,1
	GOTO $-1
	RETURN
	    
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
;89A4

