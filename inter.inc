;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 interrupt.inc                              ;
;                             interrupt include file                         ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: inter.inc
; Description: Contains constants and addresses used to initialize and run 
;              interrupts.
;
; Revision History:    10/28/16    Sophia Liu    Initial revision
;                      11/06/16    Sophia Liu    Updated constants
;                      11/20/16    Sophia Liu    Updated 

; Interrupt Controller Definitions

; Addresses
INTCtrlBase     EQU     0FF00H            ; base address for interrupt controllers

INTCtrlrCtrl    EQU     INTCtrlBase + 32H ;address of interrupt controller for timer
INTCtrlrEOI     EQU     INTCtrlBase + 22H ;address of interrupt controller EOI register
INT2CtrlrCtrl   EQU     INTCtrlBase + 3CH ; address of interrupt controller for int 2

; Register Values
INTCtrlrCVal    EQU     00001H          ;set priority for timers to 1 and enable
                                        ;000000000000----  reserved
                                        ;------------0---  enable timer interrupt
                                        ;-------------001  timer priority

INT2CtrlrCVal   EQU     00001H          ;00000000000-----  reserved
                                        ;-----------0----  edge triggering
                                        ;------------0---  enable interrupts
                                        ;-------------001  int2 priority


TimerEOI        EQU     00008H          ;Timer EOI command (same for all timers)
NonSpecEOI      EQU     08000H          ;Non-specific EOI command
Int2EOI         EQU      14             ;Int2 EOI command

Tmr2Vec         EQU     19               ;interrupt vector for Timer 2
Int2Vec         EQU     14               ;interrupt vector for Int2
