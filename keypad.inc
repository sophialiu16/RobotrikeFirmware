
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 Keypad.inc                                 ;
;                            HW #5 Keypad Routines                           ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: keypad.inc
; Description: This file contains constants for scanning and debouncing the
;     keypad.
; Revision History: 11/04/16 Sophia Liu       initial revision
;                   12/02/16 Sophia Liu       removed event constant

; key constants
NUM_ROWS     EQU 4         ; number of rows on the keypad
EMPTY_ROW    EQU 11110000B ; modified value read if no keys are pressed in the keypad row
EMPTY_KEY    EQU 11111111B ; null value for pressed key

; debouncing constants
DEBOUNCE_TIME       EQU 85 ; number of timer interrupts for key to be debounced
REPEAT_RATE         EQU 80 ; number of timer interrupts for key to auto-repeat
                           ;     after being debounced

; addresses
KEYPAD_ADDRESS  EQU 80H    ; I/O address of first row on keypad
