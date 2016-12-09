;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Motors.inc                                ;
;                         Include file for motor functions                   ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: motors.inc
; Description: This file contains constants for running and setting the motor
;              and laser.
; Revision History: 11/11/16 Sophia Liu       initial revision
;                   11/12/16 Sophia Liu       updated comments


NUM_MOTORS         EQU 3  ; number of motors/wheels on the RoboTrike

; laser constants
LASER_OFF          EQU 0    ; laser status of off
LASER_ON           EQU 1    ; laser status of on
LASER_ON_OUTPUT    EQU 10000000B ; output value for parallel port for laser on

; speed constants
IGNORE_SPEED       EQU 65535  ; speed value indicating to ignore speed argument

; angle constants
STRAIGHT           EQU 0      ; angle for straight ahead relative to the RoboTrike
IGNORE_ANGLE       EQU -32768 ; angle value indicating to ignore angle argument
MAX_ANGLE          EQU 360    ; maximum allowed angle value (range from 0 to max_angle)

; PWM constants
MOTOR_OFF          EQU 0         ; pulse width value for motors to be off
MOTOR_EMPTY        EQU 00000000B ; initial value for outputting to the
                                 ; parallel port, assumes motors forwards and off
                                 ; and laser off

MAX_COUNTER        EQU 128       ; max count for PWM counter

; port constants
PORT_INIT          EQU 10000000B ; initialization value for parallel port,
                                 ; sets Port B to output and mode active

; addresses
MOTOR_ADDRESS      EQU 181H      ; output address for motors/laser (Port B)
PARALLEL_PORT      EQU 183H      ; address for parallel port control
