NAME TIMER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    TIMER                                   ;
;                          Timer initialization and functions                ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: timer.asm
; Description: Contains functions for initializing the timer (timer2), which
;                   is used to run the LED display and scan the keypad.
; Public functions: TimerEventHandler-Event handler for the timer interrupt.
;                       Calls the function to multiplex the LEDs.

;                   InitTimer -Initialize the 80188 Timer.
; Local functions:
; Input:           None.
; Output:          None.
; Error Handling:  None.
; Algorithms:      None.
; Data Structures: None.
; Known Bugs:      None.
; Limitations:     None.
; Revision History: 10/28/16 Sophia Liu       initial revision
;                   10/30/16 Sophia Liu       updated comments
;                   11/06/16 Sophia Liu       moved functions

$INCLUDE(timer.inc)

CGROUP  GROUP   CODE

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP


; InitDKTimer
;
; Description:       Initialize the 80188 Timer. Timer #2 is initialized
;                    to generate interrupts at a 1 KHz rate.
;                    The interrupt controller is also initialized to allow the
;                    timer interrupts.
;
; Operation:         The appropriate values are written to the timer control
;                    registers in the PCB.  Also, the timer count registers
;                    are reset to zero and the max count is set up.
;                    Finally, the interrupt controller is
;                    setup to accept timer interrupts and any pending
;                    interrupts are cleared by sending a TimerEOI to the
;                    interrupt controller.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: AX, DX
; Stack Depth:       0 words
;
; Revision History: 10/29/97 Glen George
;                   11/05/16 Sophia Liu       updated timers

InitDKTimer       PROC    NEAR
                  PUBLIC  InitDKTimer

                                ;initialize Timer #0 for 1HZ interrupts
        MOV     DX, Tmr0Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr0MaxCntA ;setup max count
        MOV     AX, Tmr0MaxCntAVal
        OUT     DX, AX

        MOV     DX, Tmr0Ctrl    ;setup the control register, interrupts on
        MOV     AX, Tmr0CtrlVal
        OUT     DX, AL

                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


InitDKTimer       ENDP


CODE    ENDS

        END
