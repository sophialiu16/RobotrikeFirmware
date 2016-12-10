NAME SERIAL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Serial.asm                                ;
;                              Serial I/O Routines                           ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: Serial.asm
; Description: This file contains functions for running the serial I/O routines
;     for the robotrike. It enqueues errors and received data, and outputs to the
;     serial port via a transmit queue.
; Public functions:
;     SerialPutString        - Outputs a string to the transmit queue through
;                              SerialPutChar. Enqueues error if unable to.
;     SerialPutChar          - Outputs a character to the transmit queue and
;                                 resets CF. Sets CF if the queue is full.
;     SetSerialBaud          - Sets the serial baud rate.
;     SetSerialParity        - Sets the serial parity.
;     SerialInterruptHandler - Serial interrupt event handler. Enqueues errors
;                                  and data and outputs to the transmit register.
;     InitSerial             - Initializes the serial port and shared variables.
;
; Local functions:
;     ModemStatus      - Reads in the serial modem status register.
;     LineStatus       - Reads in the serial line status register and enqueues errors.
;     TransmitterEmpty - Outputs from the transmit queue into the serial
;                            transmit register, if possible
;     DataAvailable    - Reads and enqueues data from the serial receive register.
;
; Revision History: 11/17/16 Sophia Liu       initial revision
;                   11/19/16 Sophia Liu       updated comments
;                   12/02/16 Sophia Liu       fixed critical code
;                   12/04/16 Sophia Liu       added SerialPutString

; include files for constants and queue structure
$INCLUDE(serial.inc)
$INCLUDE(events.inc)
$INCLUDE(inter.inc)
$INCLUDE(queue.inc)
$INCLUDE(rmain.inc)
$INCLUDE(converts.inc)

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

; external function calls
EXTRN   QueueInit:NEAR
EXTRN   QueueFull:NEAR
EXTRN   QueueEmpty:NEAR
EXTRN   Dequeue:NEAR
EXTRN   Enqueue:NEAR
EXTRN   EnqueueEvent:NEAR

; SerialPutString
;
;
; Description: Sends a null-terminated command string to the serial port by
;     sending one character at a time. Takes a pointer to the string as an
;     argument.
;
; Operation: Loops through the string until a null character is reached and
;     calls SerialPutChar for each character. If SerialPutChar returns an error,
;     the character is retried up to ATTEMPT_OUTPUT_CHAR times until an
;     error is enqueued in the event queue.
;
; Arguments:         String (CS:SI) to be outputted to the serial port.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    Attempts to output a character uppt o ATTEMPT_OUTPUT_CHAR
;                    times if SerialPutChar returns an error.
; Algorithms:        None.
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       None.
; Registers changed: SI, BX, AX
; Stack depth:       1 word.
;
; Revision History: 11/29/16   Sophia Liu      initial revision
;                   12/04/16   Sophia Liu      updated comments

SerialPutString       PROC        NEAR
                      PUBLIC      SerialPutString
PutCharLoop:
CMP BYTE PTR CS:[SI], ASCII_NULL
JE SerialPutStringEnd         ; if the character is ascii null, done with string
;JNE PutCharLoopBody          ; otherwise, send character

PutCharLoopBody:
MOV BX, ATTEMPT_OUTPUT_CHAR   ; set counter for attempting to output char
MOV AL, BYTE PTR CS:[SI]      ; put char in AL as argument for SerialPutChar

PutChar:
PUSH SI                       ; save string address
CALL SerialPutChar            ; attempt to output character
POP SI                        ; restore string address
JC SerialPutCharError         ; if carry flag is set, queue is full and cannot output
;JNC NextChar                 ; if carry flag is not set, outputted, can move on

NextChar:
INC SI                        ; move on to next address for next char in string
JMP PutCharLoop               ; loop back to try to output next character

SerialPutCharError:
DEC BX                        ; count down output error counter
CMP BX, 0
JE EnqueueError               ; if have counted down to 0, give up and enqueue and error
JNE PutChar                   ; otherwise, try outputting the character again

EnqueueError:
MOV AH, SERIAL_OUTPUT_ERROR  ; store serial output error constant
CALL EnqueueEvent            ; enqueue a serial output error
;JMP SerialPutStringEnd      ; can end now

SerialPutStringEnd:
RET
SerialPutString	ENDP

; SerialPutStringNum
;
;
; Description: Sends a null-terminated command string to the serial port by
;     sending one character at a time. Takes a pointer to the string as an
;     argument.
;
; Operation: Loops through the string until a null character is reached and
;     calls SerialPutChar for each character. If SerialPutChar returns an error,
;     the character is retried up to ATTEMPT_OUTPUT_CHAR times until an
;     error is enqueued in the event queue.
;
; Arguments:         String (CS:SI) to be outputted to the serial port, 
;                    CX number of characters to output 
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    Attempts to output a character uppt o ATTEMPT_OUTPUT_CHAR
;                    times if SerialPutChar returns an error.
; Algorithms:        None.
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       None.
; Registers changed: SI, BX, AX, DI 
; Stack depth:       1 word.
;
; Revision History: 11/29/16   Sophia Liu      initial revision
;                   12/04/16   Sophia Liu      updated comments

SerialPutStringNum       PROC        NEAR
                      PUBLIC      SerialPutStringNum
MOV DI, 0
PutCharLoop2:
CMP DI, CX  
JGE SerialPutStringEnd2         ; if the character is ascii null, done with string
;JL PutCharLoopBody2          ; otherwise, send character

PutCharLoopBody2:
MOV BX, ATTEMPT_OUTPUT_CHAR   ; set counter for attempting to output char
MOV AL, BYTE PTR CS:[SI]      ; put char in AL as argument for SerialPutChar

PutChar2:
PUSH SI                       ; save string address
PUSH DI 
CALL SerialPutChar            ; attempt to output character
POP DI 
POP SI                        ; restore string address
JC SerialPutCharError2         ; if carry flag is set, queue is full and cannot output
;JNC NextChar2                 ; if carry flag is not set, outputted, can move on

NextChar2:
INC SI                        ; move on to next address for next char in string
INC DI                         
JMP PutCharLoop2               ; loop back to try to output next character

SerialPutCharError2:
DEC BX                        ; count down output error counter
CMP BX, 0
JE EnqueueError2               ; if have counted down to 0, give up and enqueue and error
JNE PutChar2                   ; otherwise, try outputting the character again

EnqueueError2:
MOV AH, SERIAL_OUTPUT_ERROR  ; store serial output error constant
CALL EnqueueEvent            ; enqueue a serial output error
;JMP SerialPutStringEnd2      ; can end now

SerialPutStringEnd2:
RET
SerialPutStringNum	ENDP

; SerialPutChar
;
;
; Description: The function outputs the passed character (c) to the transmit
;     queue, kickstarting if the kickstart flag is set.
;     It returns with the carry flag reset if the character has been put in
;     the transmit queue, and with the carry flag set if the queue is full.
;     The character (c) is passed by value in AL.
;
; Operation: Checks if the transmit queue is full. If it is not full, c is
;     enqueued and the carry flag is reset. If the kickstart flag is set,
;     serial transmit interrupts are kickstarted by clearing then setting
;     the transmit interrupt bit in the serial IER.
;     If the queue is full, the carry flag is set and the function returns.
;
; Arguments:        Character c to output to the serial channel (AL)
; Return Values:    Resets CF if character is outputted to queue, sets if
;                   queue is full.
;
; Local Variables:  None.
; Shared Variables:
;     TxQueue (R)- 8-bit queue containing the characters to output to the
;         serial port.
;     Kickstart (R/W) - 8-bit flag, set if a kickstart is needed to re-enable
;         the serial transmit interrupts.
;
; Global Variables:  None.
; Input:             Serial IER if kickstarting
; Output:            Serial IER if kickstarting
;
; Error Handling:    None.
; Algorithms:        None.
; Data Structures:   None.
; Known Bugs:        None.
; Limitations:       None.
; Registers changed: SI, DX, AX, flags
; Stack depth:       0 words
;
; Revision History: 11/14/16   Sophia Liu      initial revision
;                   11/19/16   Sophia Liu      updated comments
;                   12/02/16   Sophia Liu      handle critical code

SerialPutChar   PROC        NEAR
                PUBLIC      SerialPutChar

PUSHF                    ; save flags in order to disable interrupts
CLI                      ; disable interrupts for critical code

MOV SI, OFFSET(TxQueue) ; pass in TxQueue address of queue for queue functions
CALL QueueFull          ; check if TxQueue is full
JZ TxQueueFull          ; if ZF is set, queue is full, can't enqueue char
;JNE TxQueueNotFull     ; else, queue is not full, enqueue char

TxQueueNotFull:
CALL Enqueue          ; TxQueue is not full, enqueue character c (AL)

CMP Kickstart, KICKSTART_ON
JE KickstartSerial    ; if kickstart flag is enabled, kickstart the serial port
JNE TxQueueNotFullEnd ; otherwise, reset CF and return

KickstartSerial:
MOV DX, SERIAL_IER    ; read and write to serial IER
IN  AL, DX

AND AL, NOT(IER_THRE) ; clear the transmit bit in the serial IER
OUT DX, AL            ; output a cleared transmit bit to serial IER

OR  AL, IER_THRE      ; set the transmit bit in the serial IER
OUT DX, AL            ; output to serial IER, enable interrupts

MOV Kickstart, KICKSTART_OFF ; have kickstarted, reset kickstart flag

TxQueueNotFullEnd:
CLC                   ; reset the carry flag to 0
JMP SerialPutCharDone ; done with kickstarting, reset carry flag and finish

TxQueueFull:
STC                   ; TxQueue is full, set carry flag to 1


SerialPutCharDone:
POPF                      ; restore interrupt flag, end of critical code
RET
SerialPutChar	ENDP


; SetSerialBaud
;
;
; Description: Sets the baud rate for data transmission by outputting to the
;              baud rate generator divisor register. Takes an index to a
;              baud rate table as an argument (CX).
;
; Operation: Gets the baud rate divisor from the baud rate table with the
;            given index. Enables the DLAB bit for access to the baud rate
;            generator divisor. Outputs the baud rate divisor to the
;            divisor register, then disables the DLAB bit for access to Tx, Rx,
;            and IER.
;
; Arguments:        Baud_rate (CX) - 16-bit index for the baud rate table.
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            Reads from the serial LCR register
; Output:           Outputs the serial baud rate divisor to the divisor latches.
;
; Error Handling:   None. Assumes valid index to baud rate table.
; Algorithms:       None.
; Data Structures:  Baud table - 16-bit table containing the divisor values
;                   for allowed baud rates.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers changed: AX, DX, CX, BX
; Stack depth: flags, 9 words
;
; Revision History: 11/14/16   Sophia Liu      initial revision
;                   11/19/16   Sophia Liu      updated comments

SetSerialBaud   PROC        NEAR
                PUBLIC      SetSerialBaud
PUSHF                    ; save flags in order to disable interrupts
CLI                      ; disable interrupts for critical code


MOV DX, SERIAL_LCR       ; talk to baud rate divisor registers
IN AL, DX                ; get current value in LCR

OR AL, LCR_DLAB_EN       ; enable access to baud rate divisor
OUT DX, AL

XOR AH, AH               ; clear high byte of AX to save current LCR value
MOV SI, AX               ; store value of LCR

MOV DX, SERIAL_BRG_DIV   ; set the baud rate divisor

MOV BX, CX               ; move baud table index to access table
SHL BX, 1                ; multiply baud table index by 2 to access word table
MOV AX, CS:BaudTable[BX] ; get the baud rate divisor from BaudTable
OUT DX, AL               ; output first byte of divisor
INC DX                   ; get address to output next byte
MOV AL, AH               ; get next byte of divisor
OUT DX, AL               ; output second byte of baud rate divisor

MOV DX, SERIAL_LCR        ; access LCR
MOV AX, SI                ; get previous value in LCR
AND AL, NOT(LCR_DLAB_EN)  ; to get access to TX, RX, IER
OUT DX, AL

POPF                      ; restore interrupt flag, end of critical code

RET
SetSerialBaud	ENDP

; SetSerialParity
;
;
; Description: Sets the parity for the serial port by outputting to the parity
;              bits in the serial LCR. Takes an index to the parity table as
;              an argument (BX).
;
; Operation: Gets the current LCR value, and masks it with the desired parity
;            register values from the parity table using the parity index
;            argument. Outputs the new value to the serial LCR.
;
; Arguments:        Parity (BX) - 16-bit index for the parity table.
;
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            Reads in the current serial LCR value.
; Output:           Sets the serial LCR parity bits
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  Parity table - Byte table containing parity mask values
;                   for a given parity.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers changed: DX, AX
; Stack depth:       0 words.
;
; Revision History: 11/14/16   Sophia Liu      initial revision
;                   11/20/16   Sophia Liu      updated comments

SetSerialParity   PROC        NEAR
                  PUBLIC      SetSerialParity
MOV DX, SERIAL_LCR         ; access serial line control register
IN AL, DX                  ; get current value in serial LCR
AND AL, LCR_PARITY_MASK    ; mask current parity bits

MOV AH, CS:ParityTable[BX] ; get mask for new parity setting
OR AL, AH                  ; set bits for new parity setting
OUT DX, AL                 ; output new parity setting to serial LCR

RET
SetSerialParity	ENDP

; SerialInterruptHandler
;
;
; Description: Interrupt event handler for serial. Calls a function that gets
;     the status of the line and modem control registers, outputs data from the
;     buffer to the serial port if possible, reads in data from the serial port,
;     or enqueues received data and errors, depending on the interrupt
;
; Operation: Reads in the serial IIR register, and uses a call table to call
;      ModemStatus, LineStatus, TransmitterEmpty, or  DataAvailable. Loops while
;      there are still interrupts pending.
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
; Data Structures:   InitTable - 16-bit call table for interrupts, contains possible
;                    functions to call depending on the serial IIR value.
;
; Known Bugs:        None.
; Limitations:       None.
; Registers changed: None.
; Stack depth:       8 words.
;
; Revision History: 11/14/16   Sophia Liu      initial revision
;                   11/20/16   Sophia Liu      updated comments

SerialInterruptHandler  PROC        NEAR
                        PUBLIC     SerialInterruptHandler
PUSHA    ; save all registers for event handler

ReadIIR:
MOV DX, SERIAL_IIR      ; get current value in interrupt register at address
IN AL, DX               ; get the interrupt type
XOR AH, AH              ; clear AH - only want 8-bit value of interrupt in AX
MOV BX, AX              ; store current interrupt register value

CMP BX, NO_PENDING_INTS  ; check if there are still pending interrupts
JE DoneInt               ; if there are no more interrupts, then finished
;JNE CallTable           ; otherwise, look up interrupt in call table

CallTable:
MOV AX, CS:IntTable[BX] ; get function from call table for current interrupt
CALL AX                 ; call correct function to deal with interrupt

JMP ReadIIR             ; go back to check if there are more interrupts

DoneInt:
MOV DX, INTCtrlrEOI   ; send EOI to interrupt controller
MOV AX, Int2EOI       ; get Int2 EOI value
OUT DX, AL            ; send EOI

POPA     ; restore all registers

IRET
SerialInterruptHandler	ENDP

; ModemStatus
;
;
; Description: Reads in the serial modem status register value.
;
; Operation: Reads in the value in the modem status register to reset the modem
;            status interrupt.
;
; Arguments:        None.
; Return Values:    None.
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            Serial modem status register
; Output:           None.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers changed: DX, AX
; Stack depth:       0 words.
;
; Revision History: 11/14/16   Sophia Liu      initial revision
;                   11/20/16   Sophia Liu      updated comments

ModemStatus  PROC        NEAR

MOV DX, SERIAL_MSR
IN  AL, DX         ; read in the serial MSR

RET
ModemStatus	ENDP

; LineStatus
;
;
; Description: Reads in the line status register value. The errors are masked
;              and enqueued to the event buffer.
;
; Operation: Reads in the value in the line status register. Masks for the error
;     bits, stores the error event constant, and enqueues it in the event buffer.
;
; Arguments:        None.
; Return Values:    None.
; Local Variables:  None.
;
; Shared Variables: None.
; Global Variables: None.
;
; Input:            Reads in the serial line status register value
; Output:           None.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers changed: AX, DX
; Stack depth:       0 words.
;
; Revision History: 11/14/16   Sophia Liu      initial revision
;                   11/20/16   Sophia Liu      updated comments

LineStatus   PROC        NEAR

MOV DX, SERIAL_LSR         ; access serial line status register
IN AL, DX                  ; get serial line status register value

AND AL, LSR_ERROR_BIT_MASK ; mask error bits from LSR, value to be enqueued
MOV AH, LSR_ERROR_EVENT    ; store LSR error event constant to be enqueued
CALL EnqueueEvent          ; enqueue error event

RET
LineStatus	ENDP

; TransmitterEmpty
;
;
; Description: If the transmit queue is empty, a character is dequeued and
;     outputted to the serial transmit register. Otherwise, the kickstart flag
;     is set.
;
; Operation: Calls QueueEmpty ot check if the transmit queue is empty.
;     If the transmit queue is empty, a character is dequeued and
;     outputted to the serial transmit register. Otherwise, the kickstart flag
;     is set.
;
; Arguments:        None.
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables:
;     Kickstart (W) - The kickstart flag set indicates that a
;        kickstart is needed to re-enable serial transmit interrupts.
;     TxQueue (R/W)- 8-bit queue containing the characters to output to the
;         serial port.
;
; Global Variables: None.
;
; Input:            None.
; Output:           Outputs a character from the tx queue to the serial transmitter
;                   if possible.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers changed: SI, DX, AL
; Stack depth:      0 words.
;
; Revision History: 11/14/16   Sophia Liu      initial revision
;                   11/20/16   Sophia Liu      updated comments

TransmitterEmpty   PROC        NEAR

MOV SI, OFFSET(TxQueue) ; need to pass TxQueue address as argument to QueueEmpty
CALL QueueEmpty         ; check if transmit queue is empty
JZ TxQueueEmpty          ; if queue is empty, zero flag is set, cannot output value
;JNZ OutputChar         ; else queue is not empty, output to transmitter

Outputchar:
CALL Dequeue            ; dequeue char from TxQueue into AL

MOV DX, SERIAL_TX_REG   ; get serial transmit register
OUT DX, AL              ; output char to serial transmit register
JMP TransmitEnd         ; done outputting, can end

TxQueueEmpty:
MOV Kickstart, KICKSTART_ON ; queue is empty, need to set kickstart to
                            ;     re-enable interrupts

; JMP TransmitEnd           ; finished, can end

TransmitEnd:
RET
TransmitterEmpty	ENDP


; DataAvailable
;
;
; Description: Data is read in from the serial receive register and enqueued
;     with the receive event to the event queue.
;
; Operation: Data is read in from the serial receive register. The receive event
;     constant is stored and the data and constant are enqueued to the event queue.
;
; Arguments:        None.
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
; Input:            Reads in data from the serial receive register.
; Output:           None.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers changed: AX, DX
; Stack depth:       0 words
;
; Revision History: 11/14/16   Sophia Liu      initial revision
;                   11/20/16   Sophia Liu      updated comments

DataAvailable   PROC        NEAR

MOV DX, SERIAL_RX_REG   ; read from serial receive register
IN AL, DX               ; get data from serial receive register
MOV AH, SERIAL_RX_EVENT ; store event constant to enqueue to event queue
CALL EnqueueEvent       ; enqueue the data and event for serial receiving

RET
DataAvailable	ENDP

; InitSerial
;
;
; Description: Initialize the serial port to initial values, sets baud rate and
;              parity to the given arguments, initializes TxQueue to a byte
;              queue, and sets the kickstart flag to off.
;              Must be called before using the serial I/O routines.
;
; Operation: Initialize the serial LCR to initial values, enables all interrupts
;            in the serial IER, sets baud rate and parity to the given
;            arguments, initializes TxQueue to a byte queue, and sets the
;            kickstart flag to off.
;
; Arguments:        Parity (BX) - 16-bit index for the parity table.
;                   Baud_rate (CX) - 16-bit index for the baud rate table.
;
; Return Values:    None.
; Local Variables:  None.
; Shared Variables:
;     TxQueue(W) - 8-bit queue containing the characters to output to the
;         serial port.
;
; Global Variables: None.
; Input:            None.
; Output:           Outputs initial values to serial port control registers.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers changed: DX, AX
; Stack depth:       0 words.
;
; Revision History: 11/14/16   Sophia Liu      initial revision
;                   11/20/16   Sophia Liu      updated comments


InitSerial   PROC        NEAR
             PUBLIC      InitSerial

MOV     DX, SERIAL_LCR          ; set all parameters in LCR
MOV     AL, LCR_INIT
OUT     DX, AL                  ; set initial LCR value

MOV     DX, SERIAL_IER          ; turn on interrupts in IER
MOV     AL, IER_EN_IRQ
OUT     DX, AL

CALL SetSerialParity    ; set serial parity rate
CALL SetSerialBaud      ; set serial baud rate

MOV SI, OFFSET(TxQueue) ; pass in address of TxQueue as an initialization arg
MOV BL, BYTE_ELEMENTS   ; pass in argument indicating queue elements are bytes
CALL QueueInit          ; initialize TxQueue as byte queue

MOV Kickstart, KICKSTART_OFF  ; initialize as no kickstart needed

RET
InitSerial	ENDP

; IntTable
;
; Description: Call table for event handler. Takes the interrupt identification
;     register (IIR) as the table input and returns a 16-bit address (CS:IP)
;
; Revision History:    11/17/16    Sophia Liu    initial revision
;                      11/20/16    Sophia Liu    updated comments
IntTable    LABEL    WORD
  ; DW    Address of function (CS:IP)
    DW    OFFSET(ModemStatus)      ; Modem status interrupt
    DW    OFFSET(TransmitterEmpty) ; Transmitter holding register empty interrupt
    DW    OFFSET(DataAvailable)    ; Receiver data available interrupt
    DW    OFFSET(LineStatus)       ; Receiver line status interrupt


; BaudTable
;
; Description: Word table containing the divisor used to generated the desired
;     baud rate in the serial port for the RoboTrike. Baud rate ranges
;     from 50 to 56000, with 18 total rates.
;
; Revision History:    11/17/16    Sophia Liu    Initial revision
;                      11/20/16    Sophia Liu    updated comments
BaudTable    LABEL    WORD
    ; DW    Baud rate generator
    DW    11520 ; Divisor for baud rate of 50
    DW    7680 ; Divisor for baud rate of 75
    DW    5235 ; Divisor for baud rate of 110
    DW    4285 ; Divisor for baud rate of 134.5
    DW    3840 ; Divisor for baud rate of 150
    DW    1920 ; Divisor for baud rate of 300
    DW    960 ; Divisor for baud rate of 600
    DW    480 ; Divisor for baud rate of 1200
    DW    320 ; Divisor for baud rate of 1800
    DW    290 ; Divisor for baud rate of 2000
    DW    240 ; Divisor for baud rate of 2400
    DW    160 ; Divisor for baud rate of 3600
    DW    120 ; Divisor for baud rate of 4800
    DW    80 ; Divisor for baud rate of 7200
    DW    60 ; Divisor for baud rate of 9600
    DW    30 ; Divisor for baud rate of 19200
    DW    15 ; Divisor for baud rate of 38400
    DW    10 ; Divisor for baud rate of 56000

; ParityTable
;
; Description: Byte table containing masks for setting the parity values for
;     the serial LCR.
;
; Revision History:    11/17/16    Sophia Liu    Initial revision
ParityTable    LABEL    BYTE
  ; DB     Parity value mask for LCR
    DB    00000000B ; No parity (parity disabled)
    DB    00001000B ; Odd parity
    DB    00011000B ; Even parity selected
    DB    00111000B ; Parity bit transmitted and checked as cleared
    DB    00101000B ; Parity bit transmitted and checked as set

CODE    ENDS

DATA    SEGMENT PUBLIC  'DATA'

  TxQueue     QUEUESTRUC    <>   ; Byte queue containing characters to be
                                 ;     outputted to the serial transmit register.

  Kickstart   DB    ?            ; 8-bit flag. Set if a kickstart is needed to
                                 ;     re-enable transmit interrupts.

DATA    ENDS
        END
