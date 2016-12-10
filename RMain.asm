NAME RMAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 Remote Main                                ;
;                         RoboTrike Remote Unit Main Loop                    ;
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
; Global Variables: None.
; Inputs: Input is entered through an unlabeled 4x4 16 key keypad.
;     Through this keypad, the user can increase or decrease the speed, turn
; Outputs: An 8-digit display consisting of 14 segments with right hand decimal
;     point per digit is used to display messages while the system in running.
;     These include status updates and error messages.
;
;     A serial interface is used to control the motor unit, and sends commands
;     to the motor unit. The motor unit outputs its current status
;     (speed, angle, turret position, etc) to the serial interface whenever it
;     changes. The serial interface also receives commands from and sends status
;     to the keypad and display unit.
;
;     There is also a turret “laser” which can be fired, or an LED that can be
;     turned on. It is controlled via one bit of parallel output of an 8255.
; User Interface:
;    __________________________________________________________
;   |Increase speed |	Decrease speed	| Laser on |	Laser off |
;   ___________________________________________________________
;   |Left           |	Forward         |  Reverse |	Right     |
;   ___________________________________________________________
;   |Increase angle |Decrease angle   | Stop     |	          |
;   ___________________________________________________________
;   |Show speed     |Show angle       |          |	          |
;   ___________________________________________________________

;  Command	         Action
; Increase Speed-	  Increases the RoboTrike speed by a set amount
; Decrease Speed-		Decreases the RoboTrike speed by a set amount
; Laser On-	        Turns the turret laser on
; Laser Off-      	Turns the turret laser off
; Left- 	          Turns the RoboTrike direction left 90 degrees
; Right- 	          Turns the RoboTrike direction right 90 degrees
; Forward- 	        Moves the RoboTrike forward at half speed.
; Reverse-     	    Sets the RoboTrike direction to 180 degrees
;                       (reverses the RoboTrike direction)
; Increase angle -  Increases angle by 30 degrees (right)
; Decrease angle -  Decreases angle by 30 degrees (left)

; Command         	Display
; Increase Speed- 	XXXX (new speed in hexadecimal)
; Decrease Speed- 	XXXX (new speed in hexadecimal)
; Laser On- 	      00001
; Laser Off- 	      00000
; Left-           	00XXX (new RoboTrike direction angle, 0 to 359)
; Right-          	00XXX (new RoboTrike direction angle, 0 to 359)
; Forward-          7FFF  (speed in hexadecimal)
; Reverse-        	00XXX (new RoboTrike direction angle, 0 to 359)

;     The user moves the RoboTrike manually using the keypad, shown above.
;     These are sent via the serial interface to the motor unit, which sends back
;     status information which is displayed along with the current information about
;     the RoboTrike movement.
;     Commands for the robot on the keypad are: Increase speed, decrease speed,
;     laser on, laser off, left, right, forward, and reverse.
;     The display will show the current command being executed, and information
;     such as the current speed and direction. It will also show various errors from
;     the serial interface or motor unit.
;
; Error Handling:
;     The display also will show errors that occur,
;     such as a serial error, character received error, or parser error.
;
; Algorithms: None.
; Data Structures:
;     Queues - FIFO structure used throughout
; Limitations:
;     Memory: There are 32K bytes of RAM and 32K bytes of ROM available.
;     Serial EEROM can also store small amounts of data.
; Known Bugs: None
; Special Notes: None
; Revision History:
;     12/04/16    Sophia Liu    Initial revision


; include file for constants
$INCLUDE(RMain.inc)
$INCLUDE(Events.inc)
$INCLUDE(Converts.inc)
$INCLUDE(Motors.inc)

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

ASSUME  CS:CGROUP, DS:DGROUP

;external function declarations
EXTRN   InitCS:NEAR
EXTRN   ClrIRQVectors:NEAR

EXTRN   InstallDKHandler:NEAR
EXTRN   InitDKTimer:NEAR
EXTRN   KeypadInit:NEAR
EXTRN   DisplayInit:NEAR

EXTRN   InstallSerialHandler:NEAR
EXTRN   InitSerialInt:NEAR
EXTRN   InitSerial:NEAR
EXTRN   SerialPutString:NEAR

EXTRN   InitEvent:NEAR

EXTRN   EnqueueEvent:NEAR
EXTRN   DequeueEvent:NEAR
EXTRN   CheckCriticalErrorFlag:NEAR

EXTRN   Display:NEAR
EXTRN   DisplayNum:NEAR
EXTRN   DisplayHex:NEAR

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

CALL    InstallDKHandler        ; install the keypad and display event handler
CALL    InitDKTimer             ; initialize the keypad and display timer
CALL    DisplayInit             ; initialize the display
CALL    KeypadInit              ; initialize the keypad

CALL    InstallSerialHandler    ; install the motor event handler
CALL    InitSerialInt           ; initialize the serial interrupt
MOV     BX, NO_PARITY           ; store parity index to initialize serial
MOV     CX, BAUD_9600           ; store baud rate index to initialize serial
CALL    InitSerial              ; initialize serial

CALL    InitEvent               ; initialize event queue
CALL    InitRMain               ; initialize remote main loop

STI                             ; allow interrupts

EventLoop:                  ; infinite loop for running events
CALL DequeueEvent           ; attempt to dequeue an event from the event queue
CMP AX, NO_EVENT            ; check if anything was dequeued
JE EventLoopEnd             ; if the no event value is returned, no event to do, end
;JNE ProcessEvent           ; else, process the dequeued event

ProcessEvent:
MOV BL, AH                  ; store event constant
XOR BH, BH                  ; clear high nibble to use only event constant
MOV CX, CS:EventTable[BX]   ; get function from call table for current event
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
; Description: Handler for received characters from the serial port. One arg,
;     Character c received (AL). Characters expected to be in order
;     'E', [error const] for error and 'S', [speed high bit], [speed low bit],
;     [direction high bit], [direction low bit], [laser bit] for status. It
;     enqueues the error if an error has been received, and updates the speed,
;     direction, or laser shared status variables, expecting that only one
;     has been updated, and displays the last updated one.
;
; Operation: Stores the state in ReceivedState. Checks for error or status char,
;     then proceeds without error checking.
;     Enqueues the error if an error has been received, and updates the speed,
;     direction, or laser shared status variables, expecting that only one
;     has been updated, and displays the last updated one.
;
; Arguments:         Character c received (AL). Characters expected to be in order
;                    'E', [error const] for error and 'S', [speed high bit],
;                    [speed low bit], [direction high bit], [direction low bit],
;                    [laser bit] for status.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;    StatusString (R/W) - string containing updated status (speed, angle, laser)
;    StatusStringPos (R/W) - word containing index into status string
;    ReceivedState (R/W)- byte containing state for received char
;    Speed (R/W) - 16-bit unsigned value for speed of RoboTrike
;    Angle (R/W)- 16-bit signed value for angle of RoboTrike
;    Laser (R/W)- 8-bit value for laser status of RoboTrike
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
; Registers changed: AX, SI
; Stack depth:       0 words.
;
; Revision History: 11/29/16   Sophia Liu      initial revision
;                   12/04/16   Sophia Liu      updated comments

HandleReceivedChar       PROC        NEAR

CMP ReceivedState, ERROR_RX_STATE ; check if currently receiving an error from serial
JNE CheckStatusState              ; if not at this state, check next state
;JE ErrorState                    ; otherwise, handle character

ErrorState:
MOV AH, AL                     ; move error constant to AH to enqueue
CALL EnqueueEvent              ; enqueue the error
MOV ReceivedState, IDLE_STATE  ; move back to idle state
JMP EndHandleReceivedChar      ; done with this character

CheckStatusState:
CMP ReceivedState, STATUS_STATE ; check if currently receiving status update
JNE CheckOtherState             ; if not in this state, in idle state; check for
                                ;     error or status chars
;JE StatusState                 ; else in status state, get status bits

StatusState:
MOV SI, OFFSET(StatusString)
ADD SI, StatusStringPos
MOV BYTE PTR [SI], AL       ; save the character
INC StatusStringPos         ; increment character in status
CMP StatusStringPos, STATUS_NUM
JNE EndHandleReceivedChar   ; if have not received all status characters, end
;JE ReceivedStatus

ReceivedStatus:            ; received all status chars
MOV SI, OFFSET(StatusString)
ADD SI, StatusStringPos
MOV BYTE PTR [SI], ASCII_NULL
MOV StatusStringPos, 0
MOV ReceivedState, IDLE_STATE
MOV SI, OFFSET(StatusString)

; update speed
MOV AX, [SI]
XCHG AH, AL
MOV Speed, AX

; update angle
ADD SI, 2
MOV AX, [SI]
XCHG AH, AL
MOV Angle, AX

; update laser
ADD SI, 2 ; 
MOV AL, [SI]
MOV Laser, AL 
JMP EndHandleReceivedChar

CheckOtherState: ; check for S and E keywords
CMP AL, 'E'
JNE CheckOtherStateStatus ; if have not received an error character, check status
;JE ReceivedErrorChar ; else received an error character, go to error "state"

ReceivedErrorChar:
MOV ReceivedState, ERROR_RX_STATE
JMP EndHandleReceivedChar

CheckOtherStateStatus:
CMP AL, 'S'
JNE EndHandleReceivedChar
; JE ReceivedStatusChar

ReceivedStatusChar:
MOV ReceivedState, STATUS_STATE
;JMP EndHandleReceivedChar

EndHandleReceivedChar:
RET
HandleReceivedChar	ENDP

; HandleSerialError
;
;
; Description: Outputs a string with the corresponding error (serial port
;     error, key entry error, etc) to the display for the user. Takes the
;     error event constant (AH) as an argument.
;
; Operation: Gets the correct string for the error from a table of strings using
;     the error event constant as the table index. Calls Display with the error
;     string to display it on the LED display.
;
; Arguments:         Error event constant (AH) of error to display.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None (assumes valid event constant).
; Algorithms:        None.
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       None.
; Registers changed: BX, ES, DI, SI
; Stack depth:       1 word.
;
; Revision History: 11/29/16   Sophia Liu      initial revision
;                   12/04/16   Sophia Liu      updated comments

HandleSerialError       PROC        NEAR
                        PUBLIC      HandleSerialError
MOV BL, AH     ; save the error constant
XOR BH, BH     ; clear high nibble to use BX as AH

PUSH CS        ; save ES as CS for calling Display
POP ES

MOV DI, OFFSET(ErrorStringTable) ; get the error string table address
ADD DI, BX                       ; use error constant as table index
MOV SI, CS:[DI]                  ; get string from error table
CALL Display                     ; display string on LED display

RET
HandleSerialError	ENDP

; InitRMain
;
;
; Description: Initializes the remote main loop for receiving characters.
;     Sets the status string position to 0 (0 status chars received), the state
;     to the idle state, and sets the speed, angle, and laser variables to
;     no speed, straight ahead, and laser off respectively. Should be called
;     before running the remote main loop.
;
; Operation: Initializes the remote main loop for receiving characters.
;     Sets the status string position to 0 (0 status chars received), the state
;     to the idle state, and sets the speed, angle, and laser variables to
;     no speed, straight ahead, and laser off respectively.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;    StatusString (W) - string containing updated status (speed, angle, laser)
;    StatusStringPos (W) - word containing index into status string
;    ReceivedState (W)- byte containing state for received char
;    Speed (W) - 16-bit unsigned value for speed of RoboTrike
;    Angle (W)- 16-bit signed value for angle of RoboTrike
;    Laser (W)- 8-bit value for laser status of RoboTrike
;
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
; Stack depth:       0 words.
;
; Revision History: 12/02/16   Sophia Liu      initial revision
;                   12/04/16   Sophia Liu      updated comments
InitRMain       PROC        NEAR

MOV StatusStringPos, 0        ; set to 0 status chars received
MOV ReceivedState, IDLE_STATE ; set received char state to idle
MOV Speed, 0                  ; set speed var to 0
MOV Angle, STRAIGHT           ; set angle to straight ahead
MOV Laser, LASER_OFF ; set laser to off

RET
InitRMain	ENDP


; HandleKeyPress
;
;
; Description: Outputs a string with the corresponding command
;     from the keypad to the serial port.
;     Takes the keypad key pressed value (AL) as an argument.
;
; Operation: Gets the command string for the keypress from a table of strings.
;     and if it is a valid string, it calls SerialPutString(str) to output it
;     to the serial port.
;
; Arguments:         key pressed (AL)
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
; Registers changed: DI, ES, SI
; Stack depth:       0 words.
;
; Revision History: 11/29/16   Sophia Liu      initial revision
;                   12/04/16   Sophia Liu      updated comments
HandleKeyPress       PROC        NEAR
                     PUBLIC      HandleKeyPress
; check for show speed and show angle 


InitScanKeyLookup:                      ;setup for the table lookup
MOV DI, OFFSET(ScanCodeTable)           ;ES:DI points at table
PUSH CS                                             ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;?
POP ES
MOV CX, NO_SCAN_CODES                   ;CX is the number of table entries

ScanKeyLookup:                          ;look up the scan codes
REPNE   SCASB
                                        ;now get the keycode
MOV DI, NO_SCAN_CODES - 1               ;last table value index
SHL DI, 1                               ;multiply by 2 for word table
ADD DI, OFFSET(CommandStringTable)      ;start at end of table
SHL CX, 1                               ;multiply by 2 for word table
SUB DI, CX                              ;backup however many keys are left
MOV SI, CS:[DI]                         ;get the command
;JMP EndKeyLookup                       ;done looking up the keycode

EndKeyLookup:                           ; done getting the keycode
CMP BYTE PTR [SI], 0                    ; if invalid key press, return
JE EndHandleKeyPress
; JNE SendComand

SendCommand:
CALL SerialPutString        ;send command over serial

EndHandleKeyPress:
SUB DI, OFFSET(CommandStringTable) ; modify previous address for display string table
ADD DI, OFFSET(DisplayStringTable)
MOV SI, CS:[DI]             ; get address for si
PUSH CS                     ; change to ES for Display
POP ES
CALL Display

RET
HandleKeyPress	ENDP


; Tables

; EventTable
;
; Description: This is the call table for handling events. It returns the
;              function address for the appropriate function to call to handle
;              the event.
;
; Author:           Sophia Liu
; Last Modified:    Dec 4, 2016

EventTable    LABEL    WORD
  ; DW    Address of function, IP
    DW    OFFSET(HandleSerialError)  ; overrun error
    DW    OFFSET(HandleSerialError)  ; parity error (from remote unit)
    DW    OFFSET(HandleSerialError)  ; framing error (from remote unit)
    DW    OFFSET(HandleSerialError)  ; break error (from remote unit)
  	DW    OFFSET(HandleSerialError)  ; parser error (from remote unit)
    DW    OFFSET(HandleSerialError)  ; motor serial error (from motor unit)
    DW    OFFSET(HandleSerialError)  ; serial output error
  	DW    OFFSET(HandleKeyPress)     ; key event
    DW    OFFSET(HandleReceivedChar) ; serial received event

; KeyScanTables
;
; Description:      These are the tables for converting valid scan codes into a
;                   command string.  The individual column scans each appear as a
;                   nibble in the scan codes with the row in the high nibble
;                   and key press combo in the right. Only valid key press
;                   combinations appear in the table.  The last entry in the
;                   table is an illegal entry.  Macros are used to define the actual
;                   tables.
;
; Author:           Sophia Liu
; Last Modified:    Dec 9, 2016

%*DEFINE(TABLE)  (
        %SET(EntryNo, 0)		           ;first string is string #0
        %TABENT(0E0H, 'V5000', 13)     ;increase speed
        %TABENT(0D0H, 'V-5000', 13)    ;decrease speed
        %TABENT(0B0H, 'F', 13)         ;laser on
        %TABENT(070H, 'O', 13)         ;laser off
        %TABENT(0E1H, 'D-90', 13)      ;turn left
        %TABENT(0D1H, 'S32767', 13)    ;forward at half speed
        %TABENT(0B1H, 'D180', 13)      ;reverse at half speed
        %TABENT(071H, 'D90', 13)       ;turn right
        %TABENT(0E2H, 'D30', 13)       ;increase angle (right 30 degrees)
        %TABENT(0D2H, 'D-30', 13)      ;decrease angle (left 30 degrees)
        %TABENT(0B2H, 'S0', 13)        ;stap robot
        %TABENT(00H, 0)                ;illegal key combination
)

; scan code table - uses first byte of macro table entry
%*DEFINE(TABENT(scancode, string))  (
        DB      %scancode
)

ScanCodeTable   LABEL   BYTE
        %TABLE

NO_SCAN_CODES   EQU     ($ - ScanCodeTable)

; this macro defines the strings
%*DEFINE(TABENT(scancode, string))  (
Str%EntryNo	LABEL	BYTE
	DB      %string, 0			%' define the string '
	%SET(EntryNo, %EntryNo + 1)		%' update string number '
)

; create the table of strings
	%TABLE


; this macro defines the table of string pointers
%*DEFINE(TABENT(scancode, string))  (
	DW      OFFSET(Str%EntryNo)		%' define the string pointer '
	%SET(EntryNo, %EntryNo + 1)		%' update string number '
)

; create the table of string pointers
CommandStringTable  LABEL	BYTE
	%TABLE


; DisplayTable
;
; Description:      Display table for key commands
;
; Author:           Sophia Liu
; Last Modified:    Dec 9, 2016
%*DEFINE(DISTABLE) (
  %SET(EntryNo, 0)
  %TABENT('INC SP')         ;increase speed
  %TABENT('DEC SP')         ;decrease speed
  %TABENT('LASER ON')       ;laser on
  %TABENT('LASEROFF')       ;laser off
  %TABENT('LEFT')           ;turn left
  %TABENT('FORWARD')        ;forward at half speed
  %TABENT('REVERSE')        ;reverse at half speed
  %TABENT('RIGHT')          ;turn right
  %TABENT('RIGHT 30')       ;increase angle (right 30 degrees)
  %TABENT('LEFT 30')        ;decrease angle (left 30 degrees)
  %TABENT('STOP')           ;stap robot
  %TABENT('BAD KEY')        ;illegal key combination
)

%*DEFINE(TABENT(string))    (
DisStr%EntryNo	LABEL	BYTE
	DB      %string, 0			%' define the string '
	%SET(EntryNo, %EntryNo + 1)		%' update string number '
)
; create the table of strings
	%DISTABLE

; this macro defines the table of string pointers
%*DEFINE(TABENT(string))  (
	DW      OFFSET(DisStr%EntryNo)		%' define the string pointer '
	%SET(EntryNo, %EntryNo + 1)		%' update string number '
)

; create the table of string pointers
DisplayStringTable  LABEL	BYTE
	%DISTABLE

; ErrorTables
;
; Description:      Tables for getting the error string.
;
; Author:           Sophia Liu
; Last Modified:    Dec 9, 2016
%*DEFINE(ERRTABLE) (
  %SET(EntryNo, 0)
	%TABENT('OVER ERR')
  %TABENT('PART ERR')
  %TABENT('FRM ERR')
  %TABENT('BRK ERR')
	%TABENT('PARS ERR')
	%TABENT('MS ERR')
	%TABENT('OC ERR')
)

%*DEFINE(TABENT(string))    (
ErrStr%EntryNo	LABEL	BYTE
	DB      %string, 0			%' define the string '
	%SET(EntryNo, %EntryNo + 1)		%' update string number '
)
; create the table of strings
	%ERRTABLE

; this macro defines the table of string pointers
%*DEFINE(TABENT(string))  (
	DW      OFFSET(ErrStr%EntryNo)		%' define the string pointer '
	%SET(EntryNo, %EntryNo + 1)		%' update string number '
)

; create the table of string pointers
ErrorStringTable  LABEL	BYTE
	%ERRTABLE


CODE    ENDS

DATA    SEGMENT PUBLIC  'DATA'

StatusString    DB STATUS_NUM DUP (?) ; string containing updated status (speed, angle)
StatusStringPos DW ? ; word containing index into status string
ReceivedState   DB ? ; byte containing state for received char
Speed           DW ? ; 16-bit unsigned value for speed of RoboTrike
Angle           DW ? ; 16-bit signed value for angle of RoboTrike
Laser DB ? ; 8-bit value for laser status of RoboTrike

DATA    ENDS

;the stack
STACK   SEGMENT STACK  'STACK'

        DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS

        END    START
