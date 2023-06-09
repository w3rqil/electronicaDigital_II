# Eectrónica Digital II
Trabajo práctico final de la materia Electrónica Digital II.

El trabajo consiste en un sistema de control de acceso, implementado principalmente con el PIC16f877.

A continuación un diagrama de flujos intuitivo:


 ```mermaid
flowchart TD
init{{INICIO}}-->A
A[CONT1<- D'7'] --> B[CALL TECLADO]
    B --> C[CALL DECO]
    C --> D[CALL MOVER]
    D --> E[CALL MOSTRAR]
    E-->B
    ISR{{ISR}}-->F{T0IF=1}
    F-->|Si|G(ISR TMR0)
    F-->|No|H{INTF =1}
    H-->|Si|ASD(ISR R0)
    H-->|No|RET[RETFIE]
    
 ```
 
  ```mermaid
  flowchart TD
 ISRR0(ISR R0)-->J[CALL COMPARAR]
    J{ES IGUAL}-->|Si|K[CALL PRENDER LED VERDE]
    K-->CONT1[CONT1<- D'3']
    J-->|No|ROJO[CALL PRENDER LED ROJO]
    ROJO-->L[CONT1--]
    L-->M{CONT1=0}
    M-->|Si|N[CALL ALARMA]-->R[SET TMR0]
    R-->S[BAJAR FLAG]
    M-->|No|S
    CONT1-->S
    S-->T[RETURN]
    
    A(TMR0 ISR) --> B[CONT1--]
    B-->C{CONT1=0}-->|No|D[TMR0<-- .61]-->ret[RETFIE]
    C-->|Si|E[CONT2--]
    E-->F{CONT2=0}-->|No|CI[CONT1<-- .256]
    CI-->GI[TMR0<-- .61]-->RETU[RETFIE]
    F-->|Si|G[T0IF=0]
    G-->H[CONT1<--.256]
    H-->I[CONT2<-- .2]
    I-->RETUR[RETFIE]
   
  ```

