# Eectrónica Digital II
Trabajo práctico final de la materia Electrónica Digital II.
El trabajo consiste en un sistema de control de acceso, implementado principalmente con el PIC16f877.
A continuación un diagrama de flujos intuitivo:

 ```mermaid
flowchart TD

A[CONT1<- D'7'] --> B[CALL TECLADO]
    B --> C[CALL DECO]
    C --> D[CALL MOVER]
    D --> E[CALL MOSTRAR]
 ```
 

