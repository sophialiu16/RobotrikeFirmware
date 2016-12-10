NAME STATE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  State.asm                                 ;
;                           Serial Parser State Machine                      ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: State.asm
; Description: This file contains the functions for parsing serial RoboTrike
;     commands. A state table and token table is defined for parsing the
;     commands. One character at a time is passed to ParseSerialChar, which
;     finds the token, state, and action function. The action is performed,
;     and ParseSerialChar returns with an error or non-error value.
;
; Public functions:
;     ParseSerialChar(c) - Parses a character (c) presumed to be from the
;                          serial command, and returns the status of the parsing
;                          operation in AX.
;     ResetStateValues - Initializes and resets the shared state variables.
;                        Should be called before parsing.
;
; Local functions:
;     GetSerialToken(c) - Gets and Returns the token class and token value for
;                         the passed character.
;     GetRelSpeed - Gets and stores the current speed for setting a relative speed.
;     GetRelDirection - Gets and stores the current direction for setting a relative
;                       direction.
;     SetLaserOn - Stores the laser on value for firing the laser.
;     SetLaserOff - Stores the laser off value for firing the laser.
;     ValueNegSign - Sets the sign variable to negative to account for negative
;                    relative values in commands.
;     AddDigit (c) - Adds the next digit to the speed, direction, turret angle,
;                    or turret elevation value.
;     SetSpeed - Sets the relative or absolute RoboTrike speed given the serial
;                command values.
;     SetDirection - Sets the relative RoboTrike direction with the given command
;                    value.
;     SetRelRotateAngle - Sets the relative RoboTrike turret angle given the
;                         command values
;     SetAbsRotateAngle - Sets the absolute RoboTrike turret angle given the
;                         command values.
;     SetTurretElv - Sets the absolute RoboTrike turret elevation given the
;                    command values.
;     SetLaserVal - Sets the RoboTrike laser given the command values.
;     doNOP - Returns and does nothing; do nothing action for state machine.
;
; Input:          None.
; Output:         None.
;
; Revision History: 11/24/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments

$INCLUDE(state.inc)  ; include file for state machine
$INCLUDE(motors.inc) ; include file for constants

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

; external functions used
EXTRN   SetMotorSpeed:NEAR
EXTRN   GetMotorSpeed:NEAR
EXTRN   GetMotorDirection:NEAR
EXTRN   SetLaser:NEAR
EXTRN   SetTurretAngle:NEAR
EXTRN   SetRelTurretAngle:NEAR
EXTRN   SetTurretElevation:NEAR

; ParseSerialChar
;
;
; Description: Parses a character (c) which is presumed to be from the serial
;              input, parsed as a serial command. The character (c) is passed by
;              value in AL. The function returns the status of the parsing
;              operation in AX. Zero (0) is returned if there are no parsing errors
;              due to the passed character and a non-zero value is returned if
;              there is a parsing error due to the passed character.
;
; Operation: Uses a state machine to handle one character from the serial
;            command. Gets the transition and action function for the character,
;            does the action, and stores the next state, returning either an
;            error or non-error value
;
; Arguments:         AL- character (c) to be processed as a serial command
; Return Values:     AX- status of parsing operation; 0 is returned if there are
;                        no parsing errors due to the passed character and a
;                        non-zero value is returned if there is a parsing error
;                        due to the passed character.
;
; Local Variables:   BX - state_table, pointer to state transition table
; Shared Variables:
;     state (W) - 8-bit unsigned value containing the current state of the state machine.
;     value (W) - 16-bit signed number containing the currently computing number.
;         Used to compute the given argument for speed, direction, turret angle,
;         turret elevation, or laser status, depending  on the state.
;     offset_v (W) - 16-bit unsigned number containing the current value for speed,
;         direction, or turret angle for relative calculations. If an absolute
;         value is being calculated, offset_v is 0.
;
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
; Algorithms:        State Machine
; Data Structures:   State table containing states with transtion values and
;                    action routines.
;
; Known Bugs:        None.
; Limitations:       None.
; Registers changed: AX, DX, BX
; Stack depth:       0 words.
;
; Revision History: 11/21/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments

ParseSerialChar       PROC        NEAR
                      PUBLIC      ParseSerialChar
DoNextToken:
CALL GetSerialToken   ; get the token type and value with the given char arg
MOV DH, AH            ; save token type for character
MOV DL, AL            ; save character

ComputeTransition:      ; figure out what transition to do
MOV AL, NUM_TOKEN_TYPES ; find row in the table
MUL state               ; AX is the start of row for current state
ADD AL, DH              ; get the actual transition
ADC AH, 0               ; propagate low byte carry into high byte

IMUL BX, AX, SIZE TRANSITION_ENTRY  ; convert to table offset

DoTransition:
MOV CL, CS:StateTable[BX].NEXTSTATE ; go to next state
MOV state, CL                       ; store next state

DoAction:                     ; do the action
MOV AL, DL                    ; put token in AL for action

CALL CS:StateTable[BX].ACTION ; do action

CheckError:
CMP state, ST_ERROR
JNE NoError   ; if the state is not the error state, return non-error value
;JE HaveError ; otherwise, return error value

HaveError:
MOV AX, ERROR_VAL       ; return error value
CALL resetStateValues   ; reset values for error
JMP ParseSerialCharDone ; done with parsing character

NoError:
CMP state, ST_END
JNE finishNoError ; if not at end state, return non-error value and return
;JE endState      ; if at end state, reset values, then return

endState:
CALL resetStateValues

finishNoError:
MOV AX, NO_ERROR ; return non-error value of no error due to character

ParseSerialCharDone:
RET
ParseSerialChar	ENDP

; GetSerialToken
;
; Description:      This procedure returns the token class and token value for
;                   the passed character.  The character is truncated to
;                   7-bits.
;
; Operation:        Looks up the passed character in two tables, one for token
;                   types or classes, the other for token values.
;
; Arguments:        AL - character to look up.
; Return Value:     AL - token value for the character.
;                   AH - token type or class for the character.
;
; Local Variables:  BX - table pointer, points at lookup tables.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       Table lookup.
; Data Structures:  Two tables, one containing token values and the other
;                   containing token types.
;
; Registers Used:   AX, BX.
; Stack Depth:      0 words.
;
; Author:           Sophia Liu
; Last Modified:    Nov 25, 2016

GetSerialToken	PROC    NEAR

InitGetFPToken:			  	;setup for lookups
	AND	AL, TOKEN_MASK		;strip unused bits (high bit)
	MOV	AH, AL		       	;preserve value in AH


TokenTypeLookup:                    ;get the token type
  MOV   BX, OFFSET(TokenTypeTable)  ;BX points at table
	XLAT	CS:TokenTypeTable	;have token type in AL
	XCHG	AH, AL	       		;token type in AH, character in AL

TokenValueLookup:			                ;get the token value
  MOV    BX, OFFSET(TokenValueTable)  ;BX points at table
	XLAT	 CS:TokenValueTable	          ;have token value in AL


EndGetFPToken:                     	;done looking up type and value
        RET

GetSerialToken	ENDP

; resetStateValues
;
;
; Description: Resets the state values to initial values. Sets the state to
;     the initial state, the computing value and offset to zero, and the
;     sign to positive. Called when initializing and after the end and error states.
;
; Operation: Sets the state to the initial state, the computing value and
;     offset to zero, and the sign to positive.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     state (W) - 8-bit unsigned value containing the current state of the state machine.
;     value (W) - 16-bit signed number containing the currently computing number.
;         Used to compute the given argument for speed, direction, turret angle,
;         turret elevation, or laser status, depending  on the state.
;     offset_v (W) - 16-bit unsigned number containing the current value for speed,
;         direction, or turret angle for relative calculations. If an absolute
;         value is being calculated, offset_v is 0.
;     sign (W) -  8-bit signed value, -1 or 1. Multiplier for negative or positive
;         offsets; to be multiplied with the digit from the serial command
;         before adding it.
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
; Revision History: 11/25/16   Sophia Liu      initial revision
;                   11/26/16   Sophia Liu      updated comments

resetStateValues      PROC       NEAR
                      PUBLIC     resetStateValues

MOV state, ST_INITIAL ; set the state to the initial state
MOV value, 0          ; begin with no initial value and offset_v (values of 0)
MOV offset_v, 0
MOV sign, 1           ; assume a positive sign for the computing value

RET
resetStateValues ENDP

; GetRelSpeed
;
;
; Description: Gets and stores the current speed for setting a relative speed.
;
; Operation: Calls GetMotorSpeed and stores the speed in the offset_v shared
;            variable
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     offset_v (W) - 16-bit unsigned number containing the current value for speed,
;         direction, or turret angle for relative calculations. If an absolute
;         value is being calculated, offset_v is 0.
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
; Registers changed: AX
; Stack depth:       0 words.
;
; Revision History: 11/22/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments

GetRelSpeed           PROC        NEAR
CALL GetMotorSpeed    ; get current motor speed for relative calculations
MOV offset_v, AX      ; store current speed in offset_v

RET
GetRelSpeed	ENDP

; GetRelDirection
;
;
; Description: Gets and stores the current direction for setting a relative
;              direction.
;
; Operation: Calls GetMotorDirection and stores the current direction in
;            the offset_v shared variable.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     offset_v (W) - 16-bit unsigned number containing the current value for speed,
;         direction, or turret angle for relative calculations. If an absolute
;         value is being calculated, offset_v is 0.
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
; Registers changed: AX
; Stack depth:       0 words.
;
; Revision History: 11/22/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments
GetRelDirection       PROC        NEAR

CALL GetMotorDirection    ; get current motor direction for relative calculations
MOV offset_v, AX          ; store current speed in offset

RET
GetRelDirection	ENDP

; SetLaserOn
;
;
; Description: Stores the laser on value for firing the laser.
;
; Operation: Stores the laser on value in the shared variable value.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     value (W) - 16-bit signed number containing the currently computing number.
;         Used to compute the given argument for speed, direction, turret angle,
;         turret elevation, or laser status, depending  on the state.
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
; Registers changed: 0
; Stack depth:       0 words.
;
; Revision History: 11/22/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments

setLaserOn       PROC        NEAR

MOV value, LASER_ON    ; store laser on constant in value

RET
setLaserOn ENDP

; SetLaserOff
;
;
; Description: Stores the laser off value for firing the laser.
;
; Operation: Stores the laser off value in the shared variable value.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     value (W) - 16-bit signed number containing the currently computing number.
;         Used to compute the given argument for speed, direction, turret angle,
;         turret elevation, or laser status, depending  on the state.
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
; Revision History: 11/22/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments

setLaserOff      PROC        NEAR

MOV value, LASER_OFF    ; store laser off constant in value

RET
setLaserOff ENDP

; ValueNegSign
;
;
; Description: Sets the sign variable to negative to account for negative
;              relative values in commands.
;
; Operation: Stores -1 in the sign variable to multiply digits with to
;            maintain a negative computing value.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     sign (W) -  8-bit signed value, -1 or 1. Multiplier for negative or positive
;         offsets; to be multiplied with the digit from the serial command
;         before adding it.
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
; Revision History: 11/22/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments

ValueNegSign      PROC        NEAR

MOV sign, -1 ; relative offset is negative, store a negative number

RET
ValueNegSign ENDP

; AddDigit
;
;
; Description: Adds the next digit to the speed, direction, turret angle, or turret
;              elevation value.
;
; Operation: If the digit is not a leading zero, multiplies the computing value
;            by 10 and adds the digit (c). Returns with the error state if an
;            overflow occurs.
;
; Arguments:         AL- character (c) to be processed as a serial command
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     state (W) - 8-bit unsigned value containing the current state of the state machine.
;     value (R/W) - 16-bit signed number containing the currently computing number.
;         Used to compute the given argument for speed, direction, turret angle,
;         turret elevation, or laser status, depending  on the state.
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
; Registers changed: AX, BX, CX
; Stack depth:       0 words.
;
; Revision History: 11/22/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments

addDigit          PROC        NEAR

MOV BL, AL        ; store digit
MOV AX, value     ; prepare to multiply value
MOV CX, 10        ; store 10 to multiply for next digit
IMUL CX           ; multiply computing value by 10 for next digit
JO addDigitError  ; if signed overflow, throw error

MOV value, AX     ; store value back in shared variable

MOV AL, BL        ; store digit in AL to prepare to multiply
IMUL sign         ; multiply the digit by the sign for a + or - digit

ADD value, AX     ; add the next digit to the value
JO addDigitError  ; if signed overflow, throw error
JMP endAddDigit   ; otherwise, done with this digit

addDigitError:
MOV state, ST_ERROR ; return with error state if any carry or overflow errors
;JMP endAddDigit    ; done with adding digit

endAddDigit:
RET
addDigit ENDP


; SetSpeed
;
;
; Description: Sets the relative or absolute RoboTrike speed given the serial
;              command values.
;
; Operation: Adds the offset (current speed, if setting a relative speed) to
;            the computing value (the given speed). Sets negative speeds to 0
;            and overflowed speeds and IGNORE_SPEED values to the maximum
;            speed. Then calls SetMotorSpeed with the speed and ignore angle value.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     value (R/w) - 16-bit signed number containing the currently computing number.
;         Used to compute the given argument for speed, direction, turret angle,
;         turret elevation, or laser status, depending on the state.
;     offset_v (R) - 16-bit unsigned number containing the current value for speed,
;         direction, or turret angle for relative calculations. If an absolute
;         value is being calculated, offset_v is 0.
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
; Registers changed: AX, BX
; Stack depth:       0 words.
;
; Revision History: 11/22/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments

setSpeed          PROC        NEAR

addOffset:
CMP sign, -1         ; check if setting a negative relative angle
JE testSigned        ; if setting negative relative angle, continue with
                     ;     signed computations
;JNE testUnsigned    ; else, use unsigned computations

testUnsigned:
MOV BX, offset_v      ; store offset to add
ADD BX, value         ; add current speed to speed, which are both positive
JC setMaxSpeed        ; if the carry flag is set, the value is greater than the
                      ;     maximum speed- set speed to max
JNC haveSpeed         ; otherwise, continue with computed speed

testSigned:
MOV BX, offset_v      ; store current speed to add
AND BX, BX            ; test to see if high bit on current speed is set
JS highSpeedOffset    ; if it is, calculate the desired speed with the large
                      ;     current speed

;JNS noHighSpeedOffset    ; otherwise, high bit is not set, continue calculations

noHighSpeedOffset:
ADD BX, value         ; add current speed to speed

JO speedNeg           ; a signed overflow means went negative, set to 0

CMP BX, 0             ; test if speed is negative
JLE speedNeg          ; if have negative speed, set the speed to 0
JG haveSpeed          ; otherwise, this speed is fine

highSpeedOffset:
ADD BX, value         ; add current speed to speed

                      ; since the high bit on the current speed is set, the
                      ;     addition of the current speed with a negative
                      ;     given speed will always be positive

JMP haveSpeed         ; can continue with positive speed

speedNeg:
MOV value, 0         ; if relative speed is negative, set speed to 0 (halt vehicle)
JMP callSpeed        ; can now set the speed

haveSpeed:
MOV value, BX           ; store speed back in shared variable
CMP value, IGNORE_SPEED
JNE callSpeed           ; if speed is not ignore speed argument, continue on
;JE setMaxSpeed         ; otherwise, set speed to maximum allowed speed

setMaxSpeed:
MOV value, MAX_SPEED_ARG ; set the speed to the maximum speed
;JMP callSpeed           ; can now set the speed

callSpeed:
MOV AX, value        ; pass in speed argument
MOV BX, IGNORE_ANGLE ; pass in ignore angle argument (only setting speed)
CALL SetMotorSpeed   ; call function to set the speed
JMP endSpeed         ; set speed, can end now

endSpeed:
RET
setSpeed ENDP

; SetDirection
;
;
; Description: Sets the relative RoboTrike direction with the given command
;     value. First normalizes the angle and adds the current angle. Then checks
;     calls setMotorSpeed with the IGNORE_SPEED argument and the computed angle.
;
; Operation: Divides the given relative angle value with 360 to normalize the
;     value and prevent overflows. Then calls setMotorSpeed with the IGNORE_SPEED
;     argument and the computed angle.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     value (R/w) - 16-bit signed number containing the currently computing number.
;         Used to compute the given argument for speed, direction, turret angle,
;         turret elevation, or laser status, depending  on the state.
;     offset_v (R) - 16-bit unsigned number containing the current value for speed,
;         direction, or turret angle for relative calculations. If an absolute
;         value is being calculated, offset_v is 0.
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
; Registers changed: AX, BX, DX
; Stack depth:       0 words.
;
; Revision History: 11/22/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments
setDirection      PROC        NEAR

normalizeAngle:    ; normalize angle to prevent overflows
MOV AX, value      ; prepare to divide angle
MOV BX, 360        ; prepare to divide by degrees in circle (360)
CWD                ; prepare to get remainder of angle to normalize angle
IDIV BX            ; divide angle argument by degrees in circle to get remainder

MOV value, DX     ; store angle back in shared variable

addAngle:
MOV BX, offset_v           ; store the offset to add
ADD value, BX              ; add current angle to angle

callDirection:
MOV AX, IGNORE_SPEED ; pass in ignore speed arg, only care about direction
MOV BX, value        ; pass in computed angle for direction
CALL setMotorSpeed   ; set the motor direction

setDirectionEnd:
RET
setDirection ENDP

; SetRelRotateAngle
;
;
; Description: Sets the relative RoboTrike turret angle given the serial command value.
;
; Operation: Calls setRelTurretAngle with the relative serial command angle value,
;     which sets the relative turret angle.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     value (R) - 16-bit signed number containing the currently computing number.
;         Used to compute the given argument for speed, direction, turret angle,
;         turret elevation, or laser status, depending  on the state.
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
; Registers changed: AX
; Stack depth:       0 words.
;
; Revision History: 11/22/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments
SetRelRotateAngle      PROC        NEAR

MOV AX, value       ; pass in angle to set turret angle to relative angle
CALL setRelTurretAngle

setRelRotateEnd:
RET

SetRelRotateAngle ENDP

; SetAbsRotateAngle
;
;
; Description: Sets the absolute RoboTrike turret angle given the serial command value.
;
; Operation: Calls SetTurretAngle with the absolute angle argument, which sets
;     the absolute turret angle.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     value (R) - 16-bit signed number containing the currently computing number.
;         Used to compute the given argument for speed, direction, turret angle,
;         turret elevation, or laser status, depending  on the state.
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
; Registers changed: AX
; Stack depth:       0 words.
;
; Revision History: 11/22/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments

SetAbsRotateAngle      PROC        NEAR

MOV AX, value       ; pass in angle to set absolute turret angle to
CALL setTurretAngle

RET
SetAbsRotateAngle ENDP

; SetTurretElv
;
;
; Description: Checks if the elevation argument is within the allowed bounds.
;     If it is, it sets the absolute RoboTrike turret elevation to the command
;     value.
;
; Operation: Compares the elevation with the minimum and maximum allowed values.
;     Moves to error state if not within the allowed bounds. If it is an allowed
;     value, SetTurretElevation is called with the computed value.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     value (R) - 16-bit signed number containing the currently computing number.
;         Used to compute the given argument for speed, direction, turret angle,
;         turret elevation, or laser status, depending  on the state.
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
; Registers changed: AX
; Stack depth:       0 words.
;
; Revision History: 11/22/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments

SetTurretElv      PROC        NEAR

testMaxElv:
CMP value, MAX_TURRET_ELV ; make sure elevation is within allowed range
JG invalidElevation       ; if angle is greater than max allowed angle, throw error
; JLE testMinElv          ; otherwise, test lower bound

testMinElv:
CMP value, MIN_TURRET_ELV ; make sure elevation is within allowed range
JL invalidElevation       ; if angle is less than min allowed angle, throw error
; JGE setElevation        ; otherwise, set the turret elevation

setElevation:
MOV AX, value           ; pass in angle to set absolute turret elevation to
CALL setTurretElevation ; set absolute turret elevation
JMP endElevation

invalidElevation:
MOV state, ST_ERROR   ; if elevation is not within bounds, return an error
; JMP endElevation    ; end command

endElevation:
RET
SetTurretElv ENDP

; SetLaserVal
;
;
; Description: Sets the RoboTrike laser given the command values
;
; Operation: Calls SetLaser with value, which has either the laser on or off value.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:
;     value (R) - 16-bit signed number containing the currently computing number.
;         Used to compute the given argument for speed, direction, turret angle,
;         turret elevation, or laser status, depending  on the state.
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
; Registers changed: AX
; Stack depth:       0 words.
;
; Revision History: 11/22/16   Sophia Liu      initial revision
;                   11/27/16   Sophia Liu      updated comments

SetLaserVal      PROC        NEAR

MOV AX, value       ; pass in laser argument value
CALL setLaser       ; set the laser on or off

RET
SetLaserVal ENDP

; doNOP
;
;
; Description: Returns and does nothing; do nothing action for state machine.
;
; Operation: Immediately returns.
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
; Stack depth:       0 words.
;
; Revision History: 11/25/16   Sophia Liu      initial revision

doNOP      PROC        NEAR
; do nothing, return
RET
doNOP ENDP

; StateTable
;
; Description:      This is the state transition table for the state machine.
;                   Each entry consists of the next state and actions for that
;                   transition.  The rows are associated with the current
;                   state and the columns with the input type.
;
; Author:           Sophia Liu
; Last Modified:    Nov. 24, 2016


TRANSITION_ENTRY        STRUC           ;structure used to define table
    NEXTSTATE   DB      ?               ;the next state for the transition
    ACTION      DW      ?                ;action for the transition
TRANSITION_ENTRY      ENDS


;define a macro to make table a little more readable
;macro just does an offset of the action routine entries to build the STRUC
%*DEFINE(TRANSITION(nxtst, act))  (
    TRANSITION_ENTRY< %nxtst, OFFSET(%act) >
)


StateTable	LABEL	TRANSITION_ENTRY

	;Current State = ST_INITIAL             Input Token Type
	%TRANSITION(ST_ABSSPEED, doNOP)	        ;TOKEN_S
	%TRANSITION(ST_RELSPEED, getRelSpeed) 	;TOKEN_V
	%TRANSITION(ST_DIRECTION, getRelDirection)	;TOKEN_D
	%TRANSITION(ST_ROTATETURRET, doNOP)	  	;TOKEN_T
	%TRANSITION(ST_TURRETELV, doNOP)		    ;TOKEN_E
	%TRANSITION(ST_SETLASER, setLaserOn)		;TOKEN_F
  %TRANSITION(ST_SETLASER, setLaserOff) 	;TOKEN_O
  %TRANSITION(ST_ERROR, doNOP)		        ;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)	        	;TOKEN_NEG
  %TRANSITION(ST_ERROR, doNOP)     	    	;TOKEN_DIGIT
  %TRANSITION(ST_END, doNOP)	          	;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)	        	;TOKEN_OTHER
  %TRANSITION(ST_INITIAL, doNOP)	      	;TOKEN_IGNORE

  ;Current State = ST_ABSSPEED          Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_SPEEDSIGN, doNOP)    	;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)	      	;TOKEN_NEG
  %TRANSITION(ST_SPEEDDIGIT, addDigit)  ;TOKEN_DIGIT
  %TRANSITION(ST_ERROR, doNOP)		      ;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)	       	;TOKEN_OTHER
  %TRANSITION(ST_ABSSPEED, doNOP)    		;TOKEN_IGNORE

  ;Current State = ST_SPEEDSIGN          Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_NEG
  %TRANSITION(ST_SPEEDDIGIT, addDigit)		;TOKEN_DIGIT
  %TRANSITION(ST_ERROR, doNOP)	        	;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)	        	;TOKEN_OTHER
  %TRANSITION(ST_SPEEDSIGN, doNOP)	    	;TOKEN_IGNORE

  ;Current State = ST_SPEEDDIGIT          Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_NEG
  %TRANSITION(ST_SPEEDDIGIT, addDigit)		;TOKEN_DIGIT
  %TRANSITION(ST_END, setSpeed)	        	;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)	        	;TOKEN_OTHER
  %TRANSITION(ST_SPEEDDIGIT, doNOP)  		;TOKEN_IGNORE

  ;Current State = ST_RELSPEED          Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_SPEEDSIGN, doNOP)		    ;TOKEN_POS
  %TRANSITION(ST_SPEEDSIGN, valueNegSign) ;TOKEN_NEG
  %TRANSITION(ST_SPEEDDIGIT, addDigit)		;TOKEN_DIGIT
  %TRANSITION(ST_ERROR, doNOP)		        ;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)	        	;TOKEN_OTHER
  %TRANSITION(ST_RELSPEED, doNOP)	     	;TOKEN_IGNORE

  ;Current State = ST_DIRECTION         Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_DIRECTIONSIGN, doNOP)		;TOKEN_POS
  %TRANSITION(ST_DIRECTIONSIGN, valueNegSign)  ;TOKEN_NEG
  %TRANSITION(ST_DIRECTIONDIGIT, addDigit)		 ;TOKEN_DIGIT
 %TRANSITION(ST_ERROR, doNOP)		              ;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)	              ;TOKEN_OTHER
  %TRANSITION(ST_DIRECTION, doNOP)	          ;TOKEN_IGNORE

  ;Current State = ST_DIRECTIONSIGN          Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_NEG
  %TRANSITION(ST_DIRECTIONDIGIT, addDigit)		;TOKEN_DIGIT
  %TRANSITION(ST_ERROR, doNOP)	            	;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)	            	;TOKEN_OTHER
  %TRANSITION(ST_DIRECTIONSIGN, doNOP)	    	;TOKEN_IGNORE

  ;Current State = ST_DIRECTIONDIGIT          Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_NEG
  %TRANSITION(ST_DIRECTIONDIGIT, addDigit)		;TOKEN_DIGIT
  %TRANSITION(ST_END, setDirection)	       	  ;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)	            	;TOKEN_OTHER
  %TRANSITION(ST_DIRECTIONDIGIT, doNOP)		  ;TOKEN_IGNORE

  ;Current State = ST_ROTATETURRET      Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_TURRETANGLESIGN, doNOP)		;TOKEN_POS
  %TRANSITION(ST_TURRETANGLESIGN, valueNegSign) ;TOKEN_NEG
  %TRANSITION(ST_TURRETANGLEDIGIT, addDigit)		;TOKEN_DIGIT
  %TRANSITION(ST_ERROR, doNOP)	              	;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)	              	;TOKEN_OTHER
  %TRANSITION(ST_ROTATETURRET, doNOP)      		;TOKEN_IGNORE

  ;Current State = ST_TURRETANGLESIGN    Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_NEG
  %TRANSITION(ST_TURRETANGLERELDIGIT, addDigit)	;TOKEN_DIGIT
  %TRANSITION(ST_ERROR, doNOP)	 	;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_OTHER
  %TRANSITION(ST_TURRETANGLESIGN, doNOP)		;TOKEN_IGNORE

  ;Current State = ST_TURRETANGLEDIGIT         Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_NEG
  %TRANSITION(ST_TURRETANGLEDIGIT, addDigit)	;TOKEN_DIGIT
  %TRANSITION(ST_END, setAbsRotateAngle)	  	;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)		            ;TOKEN_OTHER
  %TRANSITION(ST_TURRETANGLEDIGIT, doNOP) 		;TOKEN_IGNORE

  ;Current State = ST_TURRETANGLERELDIGIT         Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_NEG
  %TRANSITION(ST_TURRETANGLERELDIGIT, addDigit);TOKEN_DIGIT
  %TRANSITION(ST_END, setRelRotateAngle)		;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)	          	;TOKEN_OTHER
  %TRANSITION(ST_TURRETANGLERELDIGIT, doNOP)		;TOKEN_IGNORE

  ;Current State = ST_TURRETELV          Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_TURRETELVSIGN, doNOP)		;TOKEN_POS
  %TRANSITION(ST_TURRETELVSIGN, valueNegSign);TOKEN_NEG
  %TRANSITION(ST_TURRETELVDIGIT, addDigit)		;TOKEN_DIGIT
  %TRANSITION(ST_ERROR, doNOP)		    ;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)	    	;TOKEN_OTHER
  %TRANSITION(ST_TURRETELV, doNOP)		;TOKEN_IGNORE

  ;Current State = ST_TURRETELVSIGN          Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_NEG
  %TRANSITION(ST_TURRETELVDIGIT, addDigit)		;TOKEN_DIGIT
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_OTHER
  %TRANSITION(ST_TURRETELVSIGN, doNOP)		;TOKEN_IGNORE

  ;Current State = ST_TURRETELVDIGIT          Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_NEG
  %TRANSITION(ST_TURRETELVDIGIT, addDigit)	;TOKEN_DIGIT
  %TRANSITION(ST_END, setTurretElv)		      ;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)		          ;TOKEN_OTHER
  %TRANSITION(ST_TURRETELVDIGIT, doNOP)	 	  ;TOKEN_IGNORE

  ;Current State = ST_SETLASER          Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_NEG
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_DIGIT
  %TRANSITION(ST_END, setLaserVal)		;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)	    	;TOKEN_OTHER
  %TRANSITION(ST_SETLASER, doNOP)		;TOKEN_IGNORE

  ;Current State = ST_END             Input Token Type
	%TRANSITION(ST_END, doNOP)	  ;TOKEN_S
	%TRANSITION(ST_END, doNOP)	  ;TOKEN_V
  %TRANSITION(ST_END, doNOP)	  ;TOKEN_D
	%TRANSITION(ST_END, doNOP)		;TOKEN_T
	%TRANSITION(ST_END, doNOP)		;TOKEN_E
  %TRANSITION(ST_END, doNOP)		;TOKEN_F
	%TRANSITION(ST_END, doNOP)		;TOKEN_O
	%TRANSITION(ST_END, doNOP)		;TOKEN_POS
  %TRANSITION(ST_END, doNOP)		;TOKEN_NEG
  %TRANSITION(ST_END, doNOP)		;TOKEN_DIGIT
  %TRANSITION(ST_END, doNOP)	  ;TOKEN_CR
  %TRANSITION(ST_END, doNOP)	  ;TOKEN_OTHER
  %TRANSITION(ST_END, doNOP)		;TOKEN_IGNORE

  ;Current State = ST_ERROR             Input Token Type
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_S
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_V
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_D
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_T
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_E
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_F
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_O
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_POS
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_NEG
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_DIGIT
  %TRANSITION(ST_ERROR, doNOP)	  ;TOKEN_CR
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_OTHER
  %TRANSITION(ST_ERROR, doNOP)		;TOKEN_IGNORE

; Token Tables
;
; Description:      This creates the tables of token types and token values.
;                   Each entry corresponds to the token type and the token
;                   value for a character.  Macros are used to actually build
;                   two separate tables - TokenTypeTable for token types and
;                   TokenValueTable for token values.
;
; Author:           Sophia Liu
; Last Modified:    Nov 25, 2016

%*DEFINE(TABLE)  (
        %TABENT(TOKEN_OTHER, 0)		;<null>  (end of string)
        %TABENT(TOKEN_OTHER, 1)		;SOH
        %TABENT(TOKEN_OTHER, 2)		;STX
        %TABENT(TOKEN_OTHER, 3)		;ETX
        %TABENT(TOKEN_OTHER, 4)		;EOT
        %TABENT(TOKEN_OTHER, 5)		;ENQ
        %TABENT(TOKEN_OTHER, 6)		;ACK
        %TABENT(TOKEN_OTHER, 7)		;BEL
        %TABENT(TOKEN_OTHER, 8)		;backspace
        %TABENT(TOKEN_IGNORE, 9)		;TAB
        %TABENT(TOKEN_OTHER, 10)	;new line
        %TABENT(TOKEN_OTHER, 11)	;vertical tab
        %TABENT(TOKEN_OTHER, 12)	;form feed
        %TABENT(TOKEN_CR, 13)	;carriage return
        %TABENT(TOKEN_OTHER, 14)	;SO
        %TABENT(TOKEN_OTHER, 15)	;SI
        %TABENT(TOKEN_OTHER, 16)	;DLE
        %TABENT(TOKEN_OTHER, 17)	;DC1
        %TABENT(TOKEN_OTHER, 18)	;DC2
        %TABENT(TOKEN_OTHER, 19)	;DC3
        %TABENT(TOKEN_OTHER, 20)	;DC4
        %TABENT(TOKEN_OTHER, 21)	;NAK
        %TABENT(TOKEN_OTHER, 22)	;SYN
        %TABENT(TOKEN_OTHER, 23)	;ETB
        %TABENT(TOKEN_OTHER, 24)	;CAN
        %TABENT(TOKEN_OTHER, 25)	;EM
        %TABENT(TOKEN_OTHER, 26)	;SUB
        %TABENT(TOKEN_OTHER, 27)	;escape
        %TABENT(TOKEN_OTHER, 28)	;FS
        %TABENT(TOKEN_OTHER, 29)	;GS
        %TABENT(TOKEN_OTHER, 30)	;AS
        %TABENT(TOKEN_OTHER, 31)	;US
        %TABENT(TOKEN_IGNORE, ' ')	;space
        %TABENT(TOKEN_OTHER, '!')	;!
        %TABENT(TOKEN_OTHER, '"')	;"
        %TABENT(TOKEN_OTHER, '#')	;#
        %TABENT(TOKEN_OTHER, '$')	;$
        %TABENT(TOKEN_OTHER, 37)	;percent
        %TABENT(TOKEN_OTHER, '&')	;&
        %TABENT(TOKEN_OTHER, 39)	;'
        %TABENT(TOKEN_OTHER, 40)	;open paren
        %TABENT(TOKEN_OTHER, 41)	;close paren
        %TABENT(TOKEN_OTHER, '*')	;*
        %TABENT(TOKEN_POS, +1)		;+  (positive sign)
        %TABENT(TOKEN_OTHER, 44)	;,
        %TABENT(TOKEN_NEG, -1)		;-  (negative sign)
        %TABENT(TOKEN_OTHER, 0)		;.  (decimal point)
        %TABENT(TOKEN_OTHER, '/')	;/
        %TABENT(TOKEN_DIGIT, 0)		;0  (digit)
        %TABENT(TOKEN_DIGIT, 1)		;1  (digit)
        %TABENT(TOKEN_DIGIT, 2)		;2  (digit)
        %TABENT(TOKEN_DIGIT, 3)		;3  (digit)
        %TABENT(TOKEN_DIGIT, 4)		;4  (digit)
        %TABENT(TOKEN_DIGIT, 5)		;5  (digit)
        %TABENT(TOKEN_DIGIT, 6)		;6  (digit)
        %TABENT(TOKEN_DIGIT, 7)		;7  (digit)
        %TABENT(TOKEN_DIGIT, 8)		;8  (digit)
        %TABENT(TOKEN_DIGIT, 9)		;9  (digit)
        %TABENT(TOKEN_OTHER, ':')	;:
        %TABENT(TOKEN_OTHER, ';')	;;
        %TABENT(TOKEN_OTHER, '<')	;<
        %TABENT(TOKEN_OTHER, '=')	;=
        %TABENT(TOKEN_OTHER, '>')	;>
        %TABENT(TOKEN_OTHER, '?')	;?
        %TABENT(TOKEN_OTHER, '@')	;@
        %TABENT(TOKEN_OTHER, 'A')	;A
        %TABENT(TOKEN_OTHER, 'B')	;B
        %TABENT(TOKEN_OTHER, 'C')	;C
        %TABENT(TOKEN_D, 'D')	;D
        %TABENT(TOKEN_E, 'E')	;E
        %TABENT(TOKEN_F, 'F')	;F
        %TABENT(TOKEN_OTHER, 'G')	;G
        %TABENT(TOKEN_OTHER, 'H')	;H
        %TABENT(TOKEN_OTHER, 'I')	;I
        %TABENT(TOKEN_OTHER, 'J')	;J
        %TABENT(TOKEN_OTHER, 'K')	;K
        %TABENT(TOKEN_OTHER, 'L')	;L
        %TABENT(TOKEN_OTHER, 'M')	;M
        %TABENT(TOKEN_OTHER, 'N')	;N
        %TABENT(TOKEN_O, 'O')	;O
        %TABENT(TOKEN_OTHER, 'P')	;P
        %TABENT(TOKEN_OTHER, 'Q')	;Q
        %TABENT(TOKEN_OTHER, 'R')	;R
        %TABENT(TOKEN_S, 'S')	;S
        %TABENT(TOKEN_T, 'T')	;T
        %TABENT(TOKEN_OTHER, 'U')	;U
        %TABENT(TOKEN_V, 'V')	;V
        %TABENT(TOKEN_OTHER, 'W')	;W
        %TABENT(TOKEN_OTHER, 'X')	;X
        %TABENT(TOKEN_OTHER, 'Y')	;Y
        %TABENT(TOKEN_OTHER, 'Z')	;Z
        %TABENT(TOKEN_OTHER, '[')	;[
        %TABENT(TOKEN_OTHER, '\')	;\
        %TABENT(TOKEN_OTHER, ']')	;]
        %TABENT(TOKEN_OTHER, '^')	;^
        %TABENT(TOKEN_OTHER, '_')	;_
        %TABENT(TOKEN_OTHER, '`')	;`
        %TABENT(TOKEN_OTHER, 'a')	;a
        %TABENT(TOKEN_OTHER, 'b')	;b
        %TABENT(TOKEN_OTHER, 'c')	;c
        %TABENT(TOKEN_D, 'd')	;d
        %TABENT(TOKEN_E, 'e')	;e
        %TABENT(TOKEN_F, 'f')	;f
        %TABENT(TOKEN_OTHER, 'g')	;g
        %TABENT(TOKEN_OTHER, 'h')	;h
        %TABENT(TOKEN_OTHER, 'i')	;i
        %TABENT(TOKEN_OTHER, 'j')	;j
        %TABENT(TOKEN_OTHER, 'k')	;k
        %TABENT(TOKEN_OTHER, 'l')	;l
        %TABENT(TOKEN_OTHER, 'm')	;m
        %TABENT(TOKEN_OTHER, 'n')	;n
        %TABENT(TOKEN_O, 'o')	;o
        %TABENT(TOKEN_OTHER, 'p')	;p
        %TABENT(TOKEN_OTHER, 'q')	;q
        %TABENT(TOKEN_OTHER, 'r')	;r
        %TABENT(TOKEN_S, 's')	;s
        %TABENT(TOKEN_T, 't')	;t
        %TABENT(TOKEN_OTHER, 'u')	;u
        %TABENT(TOKEN_V, 'v')	;v
        %TABENT(TOKEN_OTHER, 'w')	;w
        %TABENT(TOKEN_OTHER, 'x')	;x
        %TABENT(TOKEN_OTHER, 'y')	;y
        %TABENT(TOKEN_OTHER, 'z')	;z
        %TABENT(TOKEN_OTHER, '{')	;{
        %TABENT(TOKEN_OTHER, '|')	;|
        %TABENT(TOKEN_OTHER, '}')	;}
        %TABENT(TOKEN_OTHER, '~')	;~
        %TABENT(TOKEN_OTHER, 127)	;rubout
)

; token type table - uses first byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokentype
)

TokenTypeTable	LABEL   BYTE
        %TABLE

; token value table - uses second byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokenvalue
)

TokenValueTable	LABEL       BYTE
        %TABLE

CODE    ENDS

DATA    SEGMENT PUBLIC  'DATA'

state    DB ? ; 8-bit unsigned value containing the current state of the state machine.

value    DW ? ; 16-bit signed number containing the currently computing number.
              ;     Used to compute the given argument for speed, direction,
              ;     turret angle, turret elevation, or laser status, depending
              ;     on the state.

offset_v DW ? ; 16-bit unsigned number containing the current value for speed,
              ;     direction, or turret angle for relative calculations. If an
              ;     absolute value is being calculated, offset_v is 0.

sign     DB ? ; 8-bit signed value, -1 or 1. Multiplier for negative or positive
              ;     offsets; to be multiplied with the digit from the serial
              ;     command before adding it.

DATA    ENDS

        END
