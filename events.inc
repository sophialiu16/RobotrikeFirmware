
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Events.inc                                ;
;                         Event constant include file                        ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: events.inc
; Description: Include file for event constants.
;
; Revision History: 11/17/16 Sophia Liu       initial revision
;                   12/02/16 Sophia Liu       added additional event constants

; AH value
OVERRUN_ERROR       EQU 0         ; event value for overrun error
PARITY_ERROR        EQU 2         ; event value for parity error
FRAMING_ERROR       EQU 4         ; event value for framing error
BREAK_ERROR         EQU 6         ; event value for break error
PARSER_ERROR        EQU 8         ; event value for parser error
MOTOR_SERIAL_ERROR  EQU 10        ; event value for motor unit serial error
SERIAL_OUTPUT_ERROR EQU 12        ; output serial char error
KEY_EVENT           EQU 14        ; constant value for key pressed event
SERIAL_RX_EVENT     EQU 16        ; event value for serial receive event

NO_EVENT           EQU 0FFFFH     ; event value for no event (if event queue is empty)
