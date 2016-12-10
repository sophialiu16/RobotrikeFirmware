;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 display.inc                                ;
;                       include file for display functions                   ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: display.inc
; Description: This file contains the definitions for various constants
;    used in display.asm and main.asm
; Revision History:    10/28/16    Sophia Liu    Initial revision
;                      10/30/16    Sophia Liu    Updated comments
;                      12/03/16    Sophia Liu    Added constant for 14 seg display

DISPLAY_SIZE    EQU 8    ; size of display (number of digits)
ASCII_NULL      EQU 0    ; ASCII NUL character

LED_DISPLAY      EQU     0000H  ; address of first LED digit
LED_DISPLAY_HIGH_BIT EQU   0008H  ; address for high bit of LED display 