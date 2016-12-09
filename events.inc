
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
LSR_ERROR_EVENT    EQU 0         ; event value for LSR error
PARSER_ERROR       EQU 2         ; event value for parser error
MOTOR_SERIAL_ERROR EQU 4         ; event value for motor unit serial error
SERIAL_OUTPUT_ERROR EQU 6        ; output serial char error
KEY_EVENT          EQU 8         ; constant value for key pressed event
SERIAL_RX_EVENT    EQU 10        ; event value for serial receive event

NO_EVENT           EQU 0FFFFH     ; event value for no event (if event queue is empty)
