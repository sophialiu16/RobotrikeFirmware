NAME MUMAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                Motor Unit Main                             ;
;                         RoboTrike Motor Unit Main Loop                     ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: This system allows an operator to control a three-wheeled
;     robotic car (the RoboTrike) via a keypad and display over a serial
;     interface. The system consists of two separate components, a remote unit
;     with a keypad and display through which the user interacts with the system
;     and the three-wheeled motor unit that can move around under user control.
;     The keypad consists of various commands that allow the robot to move and
;     fire a turret “laser.” The display shows current runtime information and
;     errors. The motor unit can also send back status to be displayed. The two
;     units communicate over a serial interface using a defined protocol.
;
; Global Variables: None.
;
; Inputs: Input for the motor unit is through the serial port. These include
;     commands to set the motor speed, direction, laser, and turret.
;
; Outputs: Three DC motors are used to move the RoboTrike via PWM
;     (Pulse Width Modulation). These motor drivers are connected to port B of
;     an 8255 chip. Each motor may be run clockwise or counterclockwise as
;     determined by one bit of Port B for each motor. This is used to determine
;     the direction of motion. One stepper motor is used to rotate the turret
;     which is connected to port C of an 8255. It is configured as a unipolar
;     drive and has four bits controlling it. The motor has a maximum step rate
;     of 50 half-steps/sec. One servomotor is used to set the angle of elevation
;     of the “laser.” This is controlled by a single bit of port C. All motors
;     are controlled via 11 bits of parallel output of an 8255.
;     A serial interface is used to control the motor unit, and sends commands
;     to the motor unit. The motor unit outputs its current status
;     (speed, angle, and laser status) to the serial interface upon receiving
;     a command. The serial interface also receives commands from and sends
;     status to the keypad and display unit.
;     There is also a turret “laser” which can be fired, or an LED that can be
;     turned on. It is controlled via one bit of parallel output of an 8255.
;
; User Interface:No real user interface for the motor unit; all communication
;     through the serial interface.
;
; Algorithms:
;     Movement: An algorithm is used to move the vehicle in any angle.
;       There are three wheels on the RoboTrike situated 120° from each other.
;       They are controlled by three motors which can each run clockwise and
;       counterclockwise. Varying direction and power given to each motor will
;       allow the robot to maneuver directly in any direction without turning.
;       Similarly, this allows the robot to travel at varying speeds.
;     Finite State Machine: A state machine is used to parse the serial input.
;
; Data Structures: Queues are used throughout.
;
; Limitations:
;    Memory: There are 32K bytes of RAM and 32K bytes of ROM available.
;      Serial EEROM can also store small amounts of data.
;
; Known Bugs: None
; Special Notes: None
;
; Revision History:
;     12/08/16    Sophia Liu    Initial revision
;     12/10/16    Sophia Liu    Updated comments

; include file for constants
$INCLUDE(Main.inc)
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
;     Calls the parser to handle the character, and sends a status update over
;     the serial port with the motor speed, direction, and laser status if
;     there are no parser errors. Takes the character as a constant (AL).
;
; Operation: Calls ParseSerialChar(c) for the character. Enqueues and error from
;    the parser if necessary. If there are no parser errors, a status update is
;    send over the serial port in the format 'S', high bit speed, low bit speed,
;    high bit direction, low bit direction, laser status bit.
;
; Arguments:         Character c received (AL)
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
; Registers changed: AX, SI, CX
; Stack depth:       0 words.
;
; Revision History: 11/29/16   Sophia Liu      initial revision
;                   12/10/16   Sophia Liu      updated comments
HandleReceivedChar       PROC        NEAR

CALL ParseSerialChar     ; call parser to deal with received characters
CMP AX, ERROR_VAL        ; check if returned an error state in parser
JE HaveStateError        ; if in error state, enqueue parser error event
;JNE sendStatus          ; else no error, send status over to remote side

sendStatus:
MOV BYTE PTR CS:[SI], 'S'  ; send motor status over serial to remote

CALL GetMotorSpeed         ; get current motor speed
MOV CS:[SI + 1], AH        ; send high bit of motor speed
MOV CS:[SI + 2], AL        ; send low bit of motor speed

CALL GetMotorDirection     ; get current motor direction
MOV CS:[SI + 3], AH        ; send high bit of direction
MOV CS:[SI + 4], AL        ; send low bit of direction

CALL GetLaser              ; get current laser status
MOV CS:[SI + 5], AL        ; send bit of laser status

MOV BYTE PTR CS:[SI + 6], CARRIAGE_RETURN ; end with carriage return
MOV CX, STATUS_CHAR_NUM                   ; send over that number of characters
CALL SerialPutStringNum                   ; send characters over serial

JMP EndHandleReceivedChar                 ; done with status

HaveStateError:
MOV AH, PARSER_ERROR       ; store event constant to enqeue error event
CALL EnqueueEvent          ; enqueue parser error
;JMP EndHandleReceivedChar ; can end now

EndHandleReceivedChar:
RET
HandleReceivedChar	ENDP

; HandleRemoteError
;
;
; Description: Handler if a serial port error occurs. Takes a constant
;     for the error in AH, and sends over the error in the form
;     'E', error constant bit, carriage return.
;
; Operation: Puts together a string to send over for the error, and sends it
;     over the serial port.
;
; Arguments:         Error constant, AH
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
; Registers changed: SI, CX
; Stack depth:       0 words.
;
; Revision History: 11/29/16   Sophia Liu      initial revision
;                   12/10/16   Sophia Liu      updated comments

HandleRemoteError       PROC        NEAR

MOV BYTE PTR CS:[SI], 'E'                   ; send error over
MOV BYTE PTR CS:[SI + 1], AH                ; send error constant
MOV BYTE PTR CS:[SI + 2], CARRIAGE_RETURN   ; carriage return for parser
MOV CX, ERROR_CHAR_NUM                      ; number of characters to send
CALL SerialPutStringNum            ; send error string over serial

RET
HandleRemoteError	ENDP

; BadEvent
;
;
; Description: Invalid event occured - ignore and do nothing.
;
; Operation: Does nothing and returns.
;
; Arguments:         None.
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
; Registers changed: None.
; Stack depth:       0 words
;
; Revision History: 12/10/16   Sophia Liu      initial revision
;
BadEvent       PROC        NEAR

RET
BadEvent	ENDP

; Motor Unit EventTable
;
; Description: This is the call table for handling events for the motor unit.
;    It returns the function address for the appropriate function to call to
;    handle the event.
;
; Author:           Sophia Liu
; Last Modified:    12/0/16

MUEventTable    LABEL    WORD
  ; DW    Address of function, IP
    DW    OFFSET(HandleRemoteError)  ; overrun error
    DW    OFFSET(HandleRemoteError)  ; parity error
    DW    OFFSET(HandleRemoteError)  ; framing error
    DW    OFFSET(HandleRemoteError)  ; break error
  	DW    OFFSET(HandleRemoteError)  ; parser error
    DW    OFFSET(HandleRemoteError)  ; motor serial error
    DW    OFFSET(HandleRemoteError)  ; serial output error
  	DW    OFFSET(BadEvent)           ; key event
    DW    OFFSET(HandleReceivedChar) ; serial received event


CODE    ENDS

;set up data segment
DATA    SEGMENT PUBLIC  'DATA'

DATA    ENDS

;the stack
STACK   SEGMENT STACK  'STACK'

        DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS

        END    START
