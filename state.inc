;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  STATE.INC                                 ;
;                         State machine include file                         ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: state.inc
; Description: This file includes the constants used for the parser state
;     machine, including the state and token definitions and constants used
;     in the action routines.
;
; Revision History: 11/25/16 Sophia Liu       initial revision
;                   11/27/16 Sophia Liu       updated comments

; State definitions
ST_INITIAL          EQU 0     ; initial state
ST_ABSSPEED         EQU 1     ; have set absolute speed command
ST_SPEEDSIGN        EQU 2     ; speed command has a sign
ST_SPEEDDIGIT       EQU 3     ; speed command digits
ST_RELSPEED         EQU 4     ; have set relative speed command
ST_DIRECTION        EQU 5     ; have set direction command
ST_DIRECTIONSIGN    EQU 6     ; direction command has a sign
ST_DIRECTIONDIGIT   EQU 7     ; direction command digits
ST_ROTATETURRET     EQU 8     ; have rotate turret angle command
ST_TURRETANGLESIGN  EQU 9     ; turret angle command has a sign
ST_TURRETANGLEDIGIT EQU 10    ; turret angle command digits
ST_TURRETANGLERELDIGIT EQU 11 ; relative turret angle digits
ST_TURRETELV        EQU 12    ; have set turret elevation command
ST_TURRETELVSIGN    EQU 13    ; turret elevation command has a sign
ST_TURRETELVDIGIT   EQU 14    ; turret elevation command digits
ST_SETLASER         EQU 15    ; have command to turn laser on or off
ST_END              EQU 16    ; ending state, done with command
ST_ERROR            EQU 17    ; received an error

NUM_STATES          EQU 18    ; number of states

; Token type definitions

TOKEN_S             EQU 0   ; token is character S or s
TOKEN_V             EQU 1   ; token is character V or v
TOKEN_D             EQU 2   ; token is character D or d
TOKEN_T             EQU 3   ; token is character T or t
TOKEN_E             EQU 4   ; token is character E or e
TOKEN_F             EQU 5   ; token is character F or f
TOKEN_O             EQU 6   ; token is character O or o
TOKEN_POS           EQU 7   ; token is positive sign: +
TOKEN_NEG           EQU 8   ; token is negative sign: -
TOKEN_DIGIT         EQU 9   ; token is a digit 0 to 9
TOKEN_CR            EQU 10  ; token is carriage return: CR
TOKEN_OTHER         EQU 11  ; token is any invalid character
TOKEN_IGNORE        EQU 12  ; token is whitespace

NUM_TOKEN_TYPES     EQU 13  ; number of token types

TOKEN_MASK	   EQU	01111111B	;mask high bit of token

; other constants
STATE_ERROR_VAL      EQU 1     ; return value for ParseSerialChar if there is a parsing error
STATE_NO_ERROR       EQU 0     ; return value for ParseSerialChar if no parsing error
