NAME MotorTmr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 Motor Timer                                ;
;                            Motor Timer Initialization                      ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: MotorTmr.asm
; Description: Contains functions for initializing the timer used to run the
;              motors on the RoboTrike (timer 2).
; Public functions:
;     InitMotorTimer - Initialize the 80188 timer 2.
;
; Local functions: None.
;
; Revision History: 11/11/16 Sophia Liu       initial revision

$INCLUDE(motortmr.inc)
$INCLUDE(inter.inc)

CGROUP  GROUP   CODE

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP

; InitMotorTimer
;
; Description:       Initialize the 80188 Timer to run the motors on the RoboTrike.
;                    Timer #2 is initialized to generate interrupts at a 4 KHz rate.
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
;                   11/12/16 Sophia Liu       updated for motor timer

InitMotorTimer       PROC    NEAR
                     PUBLIC  InitMotorTimer

                                ;initialize Timer #2 for 4KHZ interrupts
        MOV     DX, Tmr2Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr2MaxCnt ;setup max count
        MOV     AX, Tmr2MaxCntVal
        OUT     DX, AX

        MOV     DX, Tmr2Ctrl    ;setup the control register, interrupts on
        MOV     AX, Tmr2CtrlVal
        OUT     DX, AL

                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


InitMotorTimer       ENDP


CODE    ENDS

        END
