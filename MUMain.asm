NAME MUMAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                Motor Unit Main                             ;
;                         RoboTrike Motor Unit Main Loop                     ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; func spec
;
;
;
;
; Revision History:
;     12/08/16    Sophia Liu    Initial revision

; include file for constants - check if needed!
$INCLUDE(RMain.inc)
$INCLUDE(Events.inc)
$INCLUDE(Converts.inc)
$INCLUDE(Motors.inc)

$INCLUDE(state.inc)

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

ASSUME  CS:CGROUP, DS:DGROUP

;external function declarations
EXTRN   InitCS:NEAR
EXTRN   ClrIRQVectors:NEAR

EXTRN   InstallMotorHandler:NEAR
EXTRN   InitMotorTimer:NEAR
EXTRN   MotorInit:NEAR

EXTRN   ResetStateValues:NEAR
EXTRN   ParseSerialChar:NEAR

EXTRN   InstallSerialHandler:NEAR
EXTRN   InitSerialInt:NEAR
EXTRN   InitSerial:NEAR
EXTRN   SerialPutString:NEAR
EXTRN   SerialPutStringNum:NEAR

EXTRN   InitEvent:NEAR

EXTRN   EnqueueEvent:NEAR
EXTRN   DequeueEvent:NEAR
EXTRN   CheckCriticalErrorFlag:NEAR

EXTRN   GetMotorSpeed:NEAR
EXTRN   GetMotorDirection:NEAR
EXTRN   GetLaser:NEAR

 

START:

MAIN:

MOV     AX, DGROUP              ;initialize the stack pointer
MOV     SS, AX
MOV     SP, OFFSET(DGROUP:TopOfStack)

MOV     AX, DGROUP              ;initialize the data segment
MOV     DS, AX

CLI                             ; disable interrupts during initialization

CALL    InitCS                  ; initialize the 80188 chip selects
                                ;   assumes LCS and UCS already setup
CALL    ClrIRQVectors           ; clear (initialize) interrupt vector table

CALL    InstallMotorHandler     ; install motor event handler
CALL    InitMotorTimer          ; initialize motor timer
CALL    MotorInit               ; initialize motors

CALL    ResetStateValues        ; reset state values to initialize parser

CALL    InstallSerialHandler    ; install the motor event handler
CALL    InitSerialInt           ; initialize the serial interrupt
MOV     BX, NO_PARITY           ; store parity index to initialize serial
MOV     CX, BAUD_9600           ; store baud rate index to initialize serial
CALL    InitSerial              ; initialize serial

CALL    InitEvent               ; initialize event queue
;CALL    InitMUMain              ; initialize remote main loop

STI                             ; allow interrupts


EventLoop:                  ; infinite loop for running events
CALL DequeueEvent           ; attempt to dequeue an event from the event queue
CMP AX, NO_EVENT            ; check if anything was dequeued
JE EventLoopEnd             ; if the no event value is returned, no event to do, end
;JNE ProcessEvent           ; else, process the dequeued event

ProcessEvent:
MOV BL, AH                  ; store event constant
XOR BH, BH                  ; clear high nibble to use only event constant
MOV CX, CS:MUEventTable[BX] ; get function from call table for current event
CALL CX                     ; call correct function to deal with event

CheckCriticalError:
CALL CheckCriticalErrorFlag ; check for a critical error
JNC EventLoopEnd            ; if the carry flag is not set, no critical error, loop
;JC CriticalError           ; if the carry flag is set, there is a critical error

CriticalError:
JMP Main                    ; if there is a critical error, restart everything

EventLoopEnd:
JMP EventLoop               ; loop back to top to try to dequeue next event

HLT                         ; never executed (hopefully)


; HandleReceivedChar
;
;
; Description: Handler for received characters from the serial port.
;     Calls the parser to handle the character.
;
; Operation: Calls ParseSerialChar(c) for the character.
;
; Arguments:         character c received (AL)
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
; Algorithms:        None.
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       None.
; Registers changed:
; Stack depth:
;
; Revision History: 11/29/16   Sophia Liu      initial revision

HandleReceivedChar       PROC        NEAR

CALL ParseSerialChar     ; call parser to deal with received characters
CMP AX, ERROR_VAL  ; check if returned an error state in parser
JE HaveStateError        ; if in error state, enqueue parser error event
;JNE sendStatus          ; else no error, send status over to remote side

;constantly send status over
sendStatus:
MOV BYTE PTR CS:[SI], 'S'         ; send motor status over serial to remote

CALL GetMotorSpeed    ; get current motor speed
MOV CS:[SI + 1], AH        ; send over 
MOV CS:[SI + 2], AL

CALL GetMotorDirection
MOV CS:[SI + 3], AH
MOV CS:[SI + 4], AL

CALL GetLaser
MOV CS:[SI + 5], AL

MOV BYTE PTR CS:[SI + 6], CARRIAGE_RETURN
MOV BYTE PTR CS:[SI + 7], ASCII_NULL
MOV CX, 7
CALL SerialPutStringNum

JMP EndHandleReceivedChar

HaveStateError:
MOV AH, PARSER_ERROR ; store event constant to enqeue error event
CALL EnqueueEvent    ; enqueue parser error
;JMP EndHandleReceivedChar

EndHandleReceivedChar:
RET
HandleReceivedChar	ENDP

; HandleRemoteError
;
;
; Description: Handler if a motor or serial port error occurs. Takes a constant
;     for the error in AH.
;
; Operation: Gets the corresponding string from a table and sends an error
;     string over the serial port by calling SerialPutString.
;
; Arguments:         error constant, AH
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
; Algorithms:        None.
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       None.
; Registers changed:
; Stack depth:
;
; Revision History: 11/29/16   Sophia Liu      initial revision

HandleRemoteError       PROC        NEAR

; send over the error
MOV BYTE PTR CS:[SI], 'E'                   ; send error over
MOV BYTE PTR CS:[SI + 1], AH                ; send error constant 
MOV BYTE PTR CS:[SI + 2], CARRIAGE_RETURN   ; carriage return for parser
MOV BYTE PTR CS:[SI + 3], ASCII_NULL        ; ascii_null to terminate string
MOV CX, 3
CALL SerialPutStringNum            ; send error string over serial

RET
HandleRemoteError	ENDP

; InitMUMain ?

; Bad event
; doesnt do anything? enqueue error?
BadEvent       PROC        NEAR

RET
BadEvent	ENDP

; MUEventTable
;
; Description: This is the call table for handling events. It returns the
;              function address for the appropriate function to call to handle
;              the event.
;
; Author:           Sophia Liu
; Last Modified:    12/08/16

MUEventTable    LABEL    WORD
  ; DW    Address of function, IP
  	DW    OFFSET(HandleRemoteError)  ; serial lsr error
    DW    OFFSET(HandleRemoteError)  ; parser error (from motor unit)
    DW    OFFSET(HandleRemoteError)  ; serial error (from motor unit)
    DW    OFFSET(HandleRemoteError)  ; serial output error
  	DW    OFFSET(BadEvent)           ; key event
    DW    OFFSET(HandleReceivedChar) ; serial received event


CODE    ENDS

DATA    SEGMENT PUBLIC  'DATA'


DATA    ENDS

;the stack
STACK   SEGMENT STACK  'STACK'

        DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS

        END    START
