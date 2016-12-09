NAME MOTORS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Motors                                  ;
;                                Motor Functions                             ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: Motors.asm
; Description: This file contains functions for running the motors on the
;     RoboTrike, which controls how fast and in what direction it can move.
; Public functions:
;   SetMotorSpeed - The function sets the speed and angle of the RoboTrike. It is
;     passed two arguments, speed (AX) and angle (BX).
;
;   GetMotorSpeed - The function is called with no arguments and returns the current
;     speed setting for the RoboTrike in AX.
;
;   GetMotorDirection - The function is called with no arguments and returns the current
;     direction of movement setting for the RoboTrike as an angle in degrees
;     in AX. An angle of zero (0) indicates straight ahead relative to the
;     RoboTrike orientation and angles are measured clockwise.
;     The value returned will always be between 0 and 359 inclusively.
;
;   SetLaser - The function is passed a single argument (onoff) in AX that
;     indicates whether to turn the RoboTrike laser on or off. A zero (0) value
;     turns the laser off and a non-zero value turns it on.
;
;   GetLaser - The function is called with no arguments and returns the status
;     of the RoboTrike laser in AX. A value of zero (0) indicates the laser
;     is off and a non-zero value indicates the laser is on.
;
;   MotorInit - Initialize shared variables for motors. Initialize speed to
;     not moving, angle to straight ahead, laser to off, PWM counter to an
;     initial value, and the pulse width array such that all the motors are off.
;     Also initializes the parallel port used to output to the motors.
;     Must be called before running the motors.
;
; Local functions:
;
;   PWMEventHandler - Timer event handler for motors. Uses pulse width modulation,
;     turning the motors on for a fraction of the time, to set the speed and
;     direction of the RoboTrike.
;
; Revision History: 11/10/16 Sophia Liu       initial revision
;                   11/12/16 Sophia Liu       updated comments
;                   12/08/16 Sophia Liu       moved InstallMotorHandler here

; include files for motor and motor event handler constants
$INCLUDE(motors.inc)
$INCLUDE(inter.inc)

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

; include sin and cos tables
EXTRN   Sin_Table:WORD
EXTRN   Cos_Table:WORD


; InstallMotorHandler
;
; Description:       Install the motor event handler for the
;                    timer 2 interrupt.
;
; Operation:         Writes the address of the timer 2 event handler to the
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
; Author:            Liu
; Last Modified:     12/08/2018

InstallMotorHandler  PROC    NEAR
                     PUBLIC  InstallMotorHandler

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr2Vec), OFFSET(PWMEventHandler)
        MOV     ES: WORD PTR (4 * Tmr2Vec + 2), SEG(PWMEventHandler)


        RET                     ;all done, return


InstallMotorHandler  ENDP

; Name SetMotorSpeed
;
;
; Description: The function sets the speed and angle of the RoboTrike. It is
;     passed two arguments, speed (AX) and angle (BX). Speed ranges from 0 (no movement)
;     to 65534 (full speed), with a speed of 65535 indicating that the
;     speed argument should not be changed. Angle ranges from -32767 to 32767 in
;     degrees, with 0 degrees being straight adead relative to the RoboTrike orientation,
;     with -32768 indicating that the angle argument should not be changed.
;
; Operation: Calculates the dot product of the force and the speed for each of
;     the motors to determine the revolution rate for each motor. Fixed-point
;     arithmetic and several tables for force and trigonmetric calculations.
;     The results are stored in an array.
;
; Arguments:
;    Speed (AX) - 16-bit unsigned value, absolute speed at which the RoboTrike
;        is to run. Ranges from 0 to 65534 as the maximum speed, with a speed
;        argument of 65535 indicating that the current speed should not be
;        changed, effectively ignoring the speed argument.
;    Angle (BX) - 16-bit signed value, angle at which RoboTrike is to
;        move in degrees with 0 degrees being straight ahead relative to the
;        RoboTrike orientation. Ranges from -32767 to 32767, with an angle of
;        -32768 indicating that the current direction of travel should not be
;        changed, effectively ignoring the angle argument.
;
; Return Values:    None.
; Local Variables:  None.
;
; Shared Variables:
;     driveSpeed (R/W) - 16-bit unsigned value, absolute speed at which the
;         RoboTrikeis to run. Ranges from 0 (stopped) to 65534 (full speed).
;     driveAngle (R/W) - 16-bit signed value, angle at which RoboTrike is to move in
;         degrees, with 0 degrees being straight ahead relative to the RoboTrike
;         orientation. Ranges from 0 to 359 degrees, measured clockwise.
;     pulseWidths[] (W) - 1 byte array of length NUM_MOTORS, contains
;         calculated speed (revolutions/second) of motors
;
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:
;    The pulse width modulation calculation for each motor is
;        calculated by taking the dot product of the force and speed for each
;        motor, or by F . v = Fx * cos(angle) * v + Fy * sin(angle) * v.
;
; Data Structures:
;     Sin_Table and Cos_Table: Tables of words containing sin and cos values
;         for 0-360 degrees in Q0.15.
;     Fx_Table and Fy_Table: Table for the x and y components of force for each
;         motor in Q0.15.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers Changed: AX, BX, CX, DX, DI
; Stack Depth:       0 words
;
; Revision History: 11/07/16   Sophia Liu      initial revision
;                   11/11/16   Sophia Liu      debugging
;                   11/12/16   Sophia Liu      updated comments


SetMotorSpeed       PROC        NEAR
                    PUBLIC      SetMotorSpeed
CheckSpeed:
CMP AX, IGNORE_SPEED
JE CheckAngle        ; if speed arg is the ignore argument value, don't set
                     ;     speed arg, go on to angle arg

;JNE SetSpeed        ; else, set the speed shared variable

SetSpeed:
MOV driveSpeed, AX   ; set the speed variable to the given speed argument
;JMP CheckAngle      ; move on to check the angle

CheckAngle:
CMP BX, IGNORE_ANGLE
JE SetPulseWidths    ; if angle arg is the ignore argument value, don't set angle
;JNE ModAngle        ; else, modify angle to correct range then set the shared variable

modAngle:
MOV AX, BX         ; prepare to divide angle by maximum angle (to get remainder)
MOV BX, MAX_ANGLE  ; prepare to divide by max_angle
CWD                ; prepare to get remainder of angle (mod max_angle degrees)
IDIV BX            ; divide angle argument by max_angle to get remainder

CMP DX, 0         ; check if the remainder (now of range -max_angle to max_angle) is negative
JGE SetAngle      ; if it is not negative, can now set the angle shared variable
;JL NegativeAngle ; else, make angle positive

NegativeAngle:
ADD DX, MAX_ANGLE ; make angle positive (by adding one full revolution, MAX_ANGLE)
                  ; angle is now in correct range for trigonmetric tables
;JMP SetAngle     ; can now set angle

SetAngle:
MOV driveAngle, DX  ; store angle argument of range 0 to MAX_ANGLE in shared variable
;JMP SetPulseWidths ; continue on to set pulse widths for the motors

SetPulseWidths:
MOV DI, 0           ; initialize index for looping through pulse width array

SetPulseWidthsLoop:
MOV BX, DI               ; prepare to access element at index in fx table
SHL BX, 1                ; multiply by word size (2 bytes per word) to access word table
MOV AX, CS:Fx_Table[BX]  ; get element in fx table at index

MOV BX, driveAngle       ; prepare to get cos of driveAngle
SHL BX, 1                ; multiply by word size (2 bytes per word) to access word table
MOV CX, CS:Cos_Table[BX] ; get element in cos table at the angle (take cos(angle))

Mult1:
IMUL CX               ; multiply fx(i) by cos(angle) for dot product calculation
MOV AX, DX            ; prepare to multiply with product of fx and cos
MOV CX, driveSpeed    ; prepare to multiply by drive speed
SHR CX, 1             ; normalize drive speed for correct range
IMUL CX               ; multiply fx(i) with cos(angle) and speed for dot product calculation


MOV BX, DI               ; prepare to access element at index in fy table
SHL BX, 1                ; multiply by word size (2 bytes per word) to access word table
MOV AX, CS:Fy_Table[BX]  ; get element in fy table at index

MOV BX, driveAngle       ; prepare to get sin of driveAngle
SHL BX, 1                ; multiply by word size (2 bytes per word) to access word table
MOV CX, CS:Sin_Table[BX] ; get element in sin table at the angle (take sin(angle))

MOV BX, DX               ; store first half of pulse width in free register

Mult2:
IMUL CX               ; multiply fy(i) by sin(angle) for dot product calculation
MOV AX, DX            ; prepare to multiply with product of fy and sin
MOV CX, driveSpeed    ; prepare to multiply by drive speed
SHR CX, 1             ; normalize drive speed for correct range
IMUL CX               ; multiply fy(i) with sin(angle) and speed for dot product calculation

TotalPulseWidth:
ADD DX, BX            ; add two halves of the pulse width together
SAL DX, 2             ; remove extra sign bits from multiplying three values

MOV PulseWidths[DI], DH ; store pulse width in pulse width array

INC DI                  ; move on to next pulse width array index
CMP DI, NUM_MOTORS
JB SetPulseWidthsLoop   ; if index is less than the number of elements,
                        ;     keep looping through pulse widths

; JAE EndSetMotorSpeed  ; otherwise, have finished with pulse width calculations

EndSetMotorSpeed:
RET
SetMotorSpeed	ENDP


; Name PWMEventHandler
;
;
; Description: Timer event handler for motors. Uses pulse width modulation,
;     turning the motors on for a fraction of the time, to set the speed and
;     direction of the RoboTrike.
;
; Operation: Loops through the calculated speeds and checks if the corresponding
;     motor needs to be on (forwards/backwards) or off by comparing the pulse
;     width with a counter. Increments the counter each time it is called.
;     Outputs the result to the motor output parallel port (Port B, at MOTOR_ADDRESS).
;
; Arguments:        None.
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables:
;     pulseWidthCounter (R/W) - 8-bit counter used to determine when motors should
;         be on or off, ranges from 0 to MAX_COUNTER.
;     pulseWidths[] (R) - 1 byte array of length NUM_MOTORS, contains
;         calculated speed (revolutions/second) of motors
;     laser(R) - 16-bit value for the laser LED. 0 for off, 1 for on.
;
; Global Variables: None.
;
; Input:            None.
; Output:           Outputs 8 bits containing the laser status and the direction
;                   and status (on/off) for each motor, to the parallel port
;                   (Port B, at MOTOR_ADDRESS).
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:
;     Motor_On Table: Table containing 8-bit output values to set the motor on
;         for each motor on the RoboTrike.
;     Backwards_Motor Table: Table containing 8-bit output values to set the
;         motor to run backwards/in reverse for each motor on the RoboTrike.
;
; Known Bugs:        None.
; Limitations:       None.
; Registers changed: None.
; Stack Depth: 8 words
;
; Revision History: 11/07/16   Sophia Liu      initial revision
;                   11/11/16   Sophia Liu      debugging
;                   11/12/16   Sophia Liu      updated comments

PWMEventHandler       PROC        NEAR
PUSHA    ; save registers for event handler

PulseWidthModulation:
MOV DI, 0             ; set up index for looping through pulse width array
MOV AL, MOTOR_EMPTY   ; set up an empty output value with all motors forwards and off, laser off

GetPulseWidthLoop:
MOV BL, PulseWidths[DI] ; get pulse width for element

CheckBackwards:
CMP BL, 0        ; check if pulse width is negative, or if motor should run backwards
JGE CheckMotorOn ; if pulse width is not negative, motor forwards; continue on
;JL Backwards    ; else pulse width is negative, set backwards bit for motor

Backwards:
NEG BL                          ; make pulse width positive
MOV CL, CS:Backwards_Motor[DI]  ; get element in backwards motor table at index
OR AL, CL                       ; add backwards motor bit to port B output
;JMP CheckMotorOn       ; done with backwards bit, continue to check if the motor is on

CheckMotorOn:
CMP pulseWidthCounter, BL
;JB MotorOn  ; if the pulse width counter is less than the pulse width, the motor is on
JAE NextPulseWidthElement  ; else, the motor is off

MotorOn:
MOV CL, CS:Motor_On[DI]    ; get element in motor on table at index
OR AL, CL                  ; add motor on bit to output
;JMP NextPulseWidthElement ; move on to next pulse width element

NextPulseWidthElement:
INC DI                  ; move to next array index for pulse widths
CMP DI, NUM_MOTORS
JB GetPulseWidthLoop    ; if array index is less than pulse width array length,
                        ;     keep looping through array

;JAE GetLaserStatus     ; otherwise, continue on to get laser status to output

GetLaserStatus:
CMP Laser, LASER_OFF
JE OutputPWM            ; if laser is off, continue on to output to the motors
;JNE SetLaserOutputOn   ; else, set the laser bit on in the output

SetLaserOutputOn:
OR AL, LASER_ON_OUTPUT   ; set the laser bit on in the output
;JMP OutputPWM           ; continue on to output to the port

OutputPWM:
MOV DX, MOTOR_ADDRESS    ; get the motor/laser port address
OUT DX, AL               ; send the 8-bit output to the port

;JMP PulseWidthModulationEnd    ; finished outputting, can end

PulseWidthModulationEnd:
INC pulseWidthCounter           ; move on to the next counter value
CMP pulseWidthCounter, MAX_COUNTER
JB PulseWidthModulationDone    ; if counter is less than the max counter value,
                               ;     done with PWM

;JAE WrapCounter         ; otherwise, wrap the counter around to the beginning

WrapCounter:
MOV PulseWidthCounter, 0      ; wrap counter around to beginning
;JMP PulseWidthModulationDone ; done with PWM

PulseWidthModulationDone:
MOV DX, INTCtrlrEOI   ; send EOI to interrupt controller
MOV AX, TimerEOI      ; get timer EOI value
OUT DX, AL            ; send timer EOI

POPA     ; restore registers

IRET
PWMEventHandler	ENDP

; Name GetMotorSpeed
;
;
; Description: The function is called with no arguments and returns the current
;     speed setting for the RoboTrike in AX. A speed of 65534 indicates the
;     maximum speed and a value of 0 indicates the RoboTrike is stopped.
;     The value returned will always be between 0 and 65534 inclusively.
;
; Operation: Stores the speed shared variable in AX.
;
; Arguments:        None.
; Return Values:
;    Speed of RoboTrike (AX). A speed of 65534 indicates the
;        maximum speed and a value of 0 indicates the RoboTrike is stopped.
;        The value returned will always be between 0 and 65534 inclusively.
;
; Local Variables:  None.
; Shared Variables:
;    driveSpeed (R) - 16-bit unsigned value, absolute speed at which the
;         RoboTrikeis to run. Ranges from 0 (stopped) to 65534 (full speed).
;
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers changed: AX
; Stack Depth: 0 words
;
; Revision History: 11/07/16   Sophia Liu      initial revision
;                   11/12/16   Sophia Liu      updated comments

GetMotorSpeed       PROC        NEAR
                    PUBLIC      GetMotorSpeed
MOV AX, driveSpeed    ; store speed of vehicle into return register

RET
GetMotorSpeed	ENDP

; Name GetMotorDirection
;
;
; Description: The function is called with no arguments and returns the current
;     direction of movement setting for the RoboTrike as an angle in degrees
;     in AX. An angle of zero (0) indicates straight ahead relative to the
;     RoboTrike orientation and angles are measured clockwise.
;     The value returned will always be between 0 and 359 inclusively.
;
; Operation: Stores the angle shared variable in AX.
;
; Arguments:        None.
; Return Values:    Current angle of RoboTrike (AX). Between 0 and 359 inclusively
;                   in degrees, with 0 indicating straight ahead relative to the
;                   RoboTrike orientation, angles measured clockwise.
;
; Local Variables:  None.
; Shared Variables:
;     driveAngle (R) -  16-bit signed value, angle at which RoboTrike is to move in
;         degrees, with 0 degrees being straight ahead relative to the RoboTrike
;         orientation. Ranges from 0 to 359 degrees, measured clockwise.
;
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers changed: AX
; Stack Depth: 0 words
;
; Revision History: 11/07/16   Sophia Liu      initial revision
;                   11/12/16   Sophia Liu      updated comments

GetMotorDirection      PROC        NEAR
                       PUBLIC      GetMotorDirection

MOV AX, driveAngle    ; store angle of direction in return register

RET
GetMotorDirection	ENDP

; Name SetLaser
;
;
; Description: The function is passed a single argument (onoff) in AX that
;     indicates whether to turn the RoboTrike laser on or off. A zero (0) value
;     turns the laser off and a non-zero value turns it on.
;
; Operation: Updates the laser status shared variable.
;
; Arguments:        onoff(AX) - whether to turn the laser on or off. Zero (0)
;                       turns the laser off and a non-zero value turns it on.
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables:
;    laser (W) - 16-bit value for the laser LED. 0 for off, 1 for on.
;
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers changed: AX
; Stack Depth: 0 words
;
; Revision History: 11/07/16   Sophia Liu      initial revision
;                   11/12/16   Sophia Liu      updated comments


SetLaser       PROC        NEAR
               PUBLIC      SetLaser
CMP AX, LASER_OFF    ; test if onoff is off
JE SetLaserOff       ; if onoff is off, set the laser to off
; JNE SetLaserOn     ; otherwise, set the laser to on

SetLaserOn:
MOV Laser, LASER_ON  ; set laser to on
JMP EndSetLaser      ; done setting laser, can exit

SetLaserOff:
MOV Laser, LASER_OFF  ; set laser to off
;JMP EndSetLaser      ; done setting laser, can exit

EndSetLaser:
RET
SetLaser	ENDP

; Name GetLaser
;
;
; Description: The function is called with no arguments and returns the status
;     of the RoboTrike laser in AX. A value of zero (0) indicates the laser
;     is off and a non-zero value indicates the laser is on.
;
; Operation:        Store laser status in AX.
;
; Arguments:        None.
; Return Values:    laser status (AX) - zero (0) indicates the laser is off and
;                       a non-zero value indicates the laser is on.
;
; Local Variables:  None.
; Shared Variables:
;     laser (R) - 16-bit value for the laser LED. 0 for off, 1 for on.
;
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers changed: AX
; Stack Depth: 0 words

; Revision History: 11/07/16   Sophia Liu      initial revision

GetLaser       PROC        NEAR
               PUBLIC      GetLaser
MOV AX, laser     ; Store laser status into return register

RET
GetLaser	ENDP

; Name MotorInit
;
;
; Description: Initialize shared variables for motors. Initialize speed to
;     not moving, angle to straight ahead, laser to off, PWM counter to an
;     initial value, and the pulse width array such that all the motors are off.
;     Also initializes the parallel port used to output to the motors.
;     Must be called before running the motors.
;
; Operation: Initialize speed to not moving, angle to straight ahead,
;     laser to off, PWM counter to an initial value, and the pulse width array
;     such that all the motors are off. Initializes the parallel port used to
;     output to the motors by writing to the parallel port control register.
;
; Arguments:        None.
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables:
;     driveSpeed (W) - 16-bit unsigned value, absolute speed at which the
;         RoboTrikeis to run. Ranges from 0 (stopped) to 65534 (full speed).
;     driveAngle (W) - 16-bit signed value, angle at which RoboTrike is to move in
;         degrees, with 0 degrees being straight ahead relative to the RoboTrike
;         orientation. Ranges from 0 to 359 degrees, measured clockwise.
;     laser (W) - 16-bit value for the laser LED. 0 for off, 1 for on.
;     pulseWidthCounter (W) - 8-bit counter used to determine when motors should
;         be on or off, ranges from 0 to MAX_COUNTER.
;     pulseWidths[] (W) - 1 byte array of length NUM_MOTORS, contains
;         calculated speed (revolutions/second) of motors
;
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers changed: DI, AX, DX
; Stack Depth: 0 words
;
; Revision History: 11/07/16   Sophia Liu      initial revision
;

MotorInit      PROC        NEAR
               PUBLIC      MotorInit
SetVars:
MOV driveSpeed, 0          ; Set drive speed to 0 (not moving)
MOV driveAngle, STRAIGHT   ; Set drive angle to straight ahead
MOV laser, LASER_OFF       ; Set laser to off
MOV pulseWidthCounter, 0   ; Set pulseWithCounter to an intial value

InitPort:
MOV AL, PORT_INIT          ; initialize parallel port for motors to initial value
MOV DX, PARALLEL_PORT      ; port at address parallel_port
OUT DX, AL                 ; output initialization value to parallel port

MOV DI, 0              ; Loop through all pulse width elements, start with first element

PulseWidthLoop:
MOV PulseWidths[DI], MOTOR_OFF ; set pulse width element so that motor is always off
INC DI                         ; increment to next element index in array
CMP DI, NUM_MOTORS
JB PulseWidthLoop              ; if element index is less than to pulse width
                               ;    array length, continue looping through elements

;JAE DoneInit          ; else element is greater than or equal to pulse width
                       ;    array length, have looped through all the elements

DoneInit:
RET
MotorInit	ENDP

;To get rid of compiler warnings with hw6test, not implemented
SetRelTurretAngle     PROC    NEAR
                      PUBLIC  SetRelTurretAngle
RET
SetRelTurretAngle ENDP

SetTurretAngle     PROC    NEAR
                   PUBLIC  SetTurretAngle
RET
SetTurretAngle ENDP


; Backwards_Motor
;
; Description: Table for setting the backwards bits for the motor output.
;     It contains the 8-bit port outputs with the backward bit set for each motor.
;
; Revision History:    11/11/16    Sophia Liu    Initial revision
;                      11/12/16    Sophia Liu    Updated constants
Backwards_Motor       LABEL   BYTE
  ; DB    Port output value
    DB    00000001B     ; backwards bit set for motor 1
    DB    00000100B     ; backwards bit set for motor 2
    DB    00010000B     ; backwards bit set for motor 2

; Motor_On
;
; Description: Table for setting the motor on for the motor output.
;     It contains the 8-bit port outputs with the motor on bit set for each motor.
;
; Revision History:    11/11/16    Sophia Liu    Initial revision
;                      11/12/16    Sophia Liu    Updated constants
Motor_On              LABEL   BYTE
  ; DB Port output value
    DB    00000010B    ; motor 1 on bit set
    DB    00001000B    ; motor 2 on bit set
    DB    00100000B    ; motor 3 on bit set

; Fx_Table
;
; Description: Table for the x component of the force for each motor.
;     It contains the 16-bit fx value in Q0.15 for each motor. Used to calculate
;     the PWM for each motor.
;
; Revision History:    11/11/16    Sophia Liu    Initial revision
;                      11/12/16    Sophia Liu    Updated constants
Fx_Table              LABEL   WORD
  ; DW  FX Value (Q0.15)
    DW    7FFFH     ; F1x, Fx value for 1st motor, 1
    DW    0C000H    ; F2x, Fx value for 2nd motor, -1/2
    DW    0C000H    ; F3x, Fx value for 3rd motor, -1/2

; Fy_Table
;
; Description: Table for the y component of the force for each motor.
;     It contains the 16-bit fy value in Q0.15 for each motor. Used to calculate
;     the PWM for each motor.
;
; Revision History:    11/11/16    Sophia Liu    Initial revision
;                      11/12/16    Sophia Liu    Updated constants
Fy_Table              LABEL    WORD
  ; DW  FY Value (Q0.15)
    DW    0000H    ; F1y, Fy value for 1st motor, 0
    DW    9127H    ; F2y, Fy value for 2nd motor, -sqrt(3)/2
    DW    6ED9H    ; F3y, Fy value for 3rd motor, sqrt(3)/2

CODE    ENDS

;the data segment
DATA    SEGMENT PUBLIC  'DATA'

driveSpeed            DW    ? ; 16-bit unsigned value, absolute speed at which the
                              ; RoboTrikeis to run. Ranges from 0 (stopped) to 65534 (full speed).

driveAngle            DW    ? ; 16-bit signed value, angle at which RoboTrike is
                              ; to move in degrees, with 0 degrees being straight
                              ; ahead relative to the RoboTrike orientation.
                              ; Ranges from 0 to 359 degrees, measured clockwise.

laser                 DW    ? ; 16-bit value for the laser LED. 0 for off, 1 for on.

pulseWidthCounter     DB    ? ; 8-bit counter used to determine when motors should
                              ; be on or off, ranges from 0 to MAX_COUNTER

pulseWidths           DB    NUM_MOTORS DUP (?)
;    1 byte array of length NUM_MOTORS, contains calculated speed
;    (revolutions/second) of motors

DATA    ENDS

        END
