NAME DKTmrEH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                     DISPLAY AND KEYPAD TIMER EVENT HANDLER                 ;
;                         Timer event handler functions                      ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: DKTmrEH.asm
; Description: Contains functions for the timer event handler used to run
;     the LED display and scan the keypad.
; Public functions: TimerEventHandler-Event handler for the timer interrupt.
;                       Calls the function to multiplex the LEDs.
; Local functions: None.
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
;                   12/02/16 Sophia Liu       added event handler 


$INCLUDE(timer.inc)

CGROUP  GROUP   CODE

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP

EXTRN LEDMux:NEAR
EXTRN KeypadScan:NEAR

; InstallDKHandler
;
; Description:       Install the display and keypad event handler for the
;                    timer interrupt.
;
; Operation:         Writes the address of the timer event handler to the
;                    appropriate interrupt vector.
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
; Registers Changed: flags, AX, ES
; Stack Depth:       0 words
;
; Author:            Glen George
; Last Modified:     Jan. 28, 2002

InstallDKHandler  PROC    NEAR
                  PUBLIC  InstallDKHandler

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(TimerEventHandler)
        MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(TimerEventHandler)


        RET                     ;all done, return


InstallDKHandler  ENDP

; TimerEventHandler
;
;
; Description: Event handler for the display and keypad timer interrupt.
;     Calls LEDMux to multiplex the LEDs every timer interrupt.
;
; Operation: Saves registers, calls the LED multiplexing routine (LEDMux),
;            sends end of interrupt message, and restores registers.
;
; Arguments:        None.
;
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
; Limitations:      None.
; Registers used:   DX, AX
;
; Revision History: 10/24/16   Sophia Liu      initial revision
;                   10/30/16   Sophia Liu      Updated comments

TimerEventHandler      PROC        NEAR
                       PUBLIC      TimerEventHandler

PUSHA ; save registers

CALL LEDMux ; call to multiplex the LEDs
CALL KeyPadScan ; call to scan the keypad

MOV DX, INTCtrlrEOI   ; send EOI to interrupt controller
MOV AX, TimerEOI      ; get timer EOI value
OUT DX, AL            ; send timer EOI


POPA    ; restore registers

IRET
TimerEventHandler	ENDP

CODE ENDS
     END
