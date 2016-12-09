NAME SerialI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 Serial Interrupt                           ;
;                            Serial Int Initialization                       ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: SerialI.asm
; Description: Contains functions for initializing Int2, which is used to run
;              the serial port for the RoboTrike
; Public functions:
;     InstallSerialHandler - Install the serial event handler for the Int2
;         interrupt
;     InitSerialInt - Initialize the 80188 Int2 interrupt.
;
; Local functions: None.
;
; Revision History: 11/19/16 Sophia Liu       initial revision

$INCLUDE(inter.inc)

CGROUP  GROUP   CODE

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP


EXTRN SerialInterruptHandler:NEAR

; InstallSerialHandler
;
; Description:       Install the serial event handler for the
;                    Int2 interrupt to the Int2 interrupt vector.
;
; Operation:         Writes the address of the Int2 event handler to the
;                    Int2 interrupt vector.
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
; Author:            Sophia Liu
; Last Modified:     Nov. 19, 2016

InstallSerialHandler  PROC    NEAR
                     PUBLIC  InstallSerialHandler

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Int2Vec), OFFSET(SerialInterruptHandler)
        MOV     ES: WORD PTR (4 * Int2Vec + 2), SEG(SerialInterruptHandler)


        RET                     ;all done, return


InstallSerialHandler  ENDP

; InitSerialInt
;
; Description:       Initialize the 80188 Int2 interrupt to use the serial port
;                    on the RoboTrike.
;
; Operation:         The appropriate values are written to the int2 control
;                    register in the PCB. Any pending
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
;                   11/189/16 Sophia Liu       updated for the serial int

InitSerialInt       PROC    NEAR
                    PUBLIC  InitSerialInt

        MOV     DX, INT2CtrlrCtrl ;setup the int2 control register
        MOV     AX, INT2CtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send an int2 EOI (to clear out controller)
        MOV     AX, Int2EOI
        OUT     DX, AL


        RET                     ;done so return


InitSerialInt       ENDP


CODE    ENDS

        END
