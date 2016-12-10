;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   RMain.inc                                ;
;                           Remote Main Loop Constants                       ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: This file contains constants used in the remote main loop.
;
; Revision History:
;     12/02/2016 Sophia Liu    initial revision
;     12/04/2016 Sophia Liu    updated comments

; constants for parsing received characters


ERROR_RX_STATE        EQU 0 ; state when receiving an error from the motor unit
STATUS_STATE          EQU 1 ; state when receiving a status update from the motor unit
IDLE_STATE            EQU 2 ; state when not receiving an error or status

STATUS_NUM            EQU 5 ; number of expected characters from motor unit
                            ;     status update

; other constants
BAUD_9600             EQU 14 ; baud rate table index for rate of 9600
NO_PARITY             EQU 0  ; parity table index for no parity
EVEN_PARITY           EQU 2
BAUD_110              EQU 2
BAUD_56000            EQU 17

CARRIAGE_RETURN       EQU 13 ; carriage return character
