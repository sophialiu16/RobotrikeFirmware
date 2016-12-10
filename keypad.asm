NAME KEYPAD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Keypad                                   ;
;                            HW5 Keypad Functions                            ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: Keypad.asm
; Description: This file contains functions for scanning and debouncing the
;     keypad.
; Public functions:
;     KeypadScan - Scans through the rows of the keypad one at a time upon
;         timer interrupt, called by timer event handler. Calls the debouncing
;         function if necessary.
;     KeypadInit - Initializes the shared variables used to scan and debounce,
;         called once before running the keypad.
; Local functions:
;     KeypadDebounce - Debounces a key press. Counts down a debounce time
;         when a key is pressed; if the key remains pressed after that time,
;         it is debounced and registered as a key press.
; Input:           Keypad.
; Output:          None.
; Error Handling:  None.
; Algorithms:      None.
; Data Structures: None.
; Known Bugs:      None.
; Limitations:     None.
; Revision History: 11/04/16 Sophia Liu       initial revision
;                   11/05/16 Sophia Liu       debugging
;                   11/06/16 Sophia Liu       updated comments

$INCLUDE(events.inc)
$INCLUDE(keypad.inc) ; include file for keypad constants

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

EXTRN   EnqueueEvent:NEAR

; KeypadScan
;
;
; Description: This function scans through the rows of the keypad, and is
;     called by the timer event handler. If a key is down, it is debounced
;     and the key event and key are enqueued by the debouncing function.
;
; Operation:  Scan through one row on the keypad when called by reading the
;     address of the key row with the row offset. If a key is pressed,
;     KeypadDebounce is called to debounce the key, and the function loops over
;     that row while the key is held. If no key is pressed, the function moves
;     on to scan the next row.
;
; Arguments:        None.
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables:
;     KeyPressedFlag (R/W) - 8-bit value, true (1) or false (0). True (1) if a key is
;         currently being pressed on the keypad, and false (0) if nothing is currently
;         pressed.
;     KeyRow (R/W)- 16-bit unsigned value, row currently being scanned on keypad.
;         Ranges from 0 to NUM_ROWS - 1.
;     PressedKey (W) - 8-bit value, key currently pressed or last key pressed.
;         The first byte is the row value (0-E), and the second byte is the
;         row value (0 to NUM_ROWS - 1).
;
; Global Variables: None.
;
; Input:            Keypad input.
; Output:           None.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      Only reads one row at a time, doesn't register multiple
;                   keypressed in multiple rows. Does not handle invalid
;                   key combinations, sends everything to enqueueing function.
;
; Registers used:   AX, DX
;
; Revision History: 11/05/16   Sophia Liu      initial revision
;                   11/06/16   Sophia Liu      updated comments

KeypadScan      PROC        NEAR
                PUBLIC      KeypadScan

CMP KeyPressedFlag, 0
JNE CheckRow      ; if keypressed is true, keep checking the row for the pressed key
;JE UpdateRow     ; else keypressed is false, no key is being pressed, check next row

UpdateRow:
INC KeyRow        ; move to next row
CMP KeyRow, NUM_ROWS
JL CheckRow       ; if key row has not reached max row number, proceed to check that row
;JGE WrapRow      ; else, wrap the row offset back to the beginning

WrapRow:
MOV KeyRow, 0     ; reset the row offset to the first row
; JMP CheckRow    ; Proceed to check the keypad row

CheckRow:
MOV DX, KEYPAD_ADDRESS ; prepare to get keypad row value at address
ADD DX, KeyRow    ; add key row offset to get correct keypad row
IN AX, DX         ; get row value at row address
SHL AL, 4         ; move key value to first four bits, pad with zeros
CMP AL, EMPTY_ROW ; check if modified row is empty
JE NoKeysPressed  ; if the row has the value of an empty row, no keys pressed,
                  ; move on
;JNE KeysPressed  ; else a key has been pressed, process and debounce key

KeysPressed:
MOV KeyPressedFlag, 1 ; a key is pressed, set key pressed flag to true
XOR AX, KeyRow     ; store the row in the second 4 bits of AL, AL now holds the
                   ;     new key value (key value, row value)
CMP AL, PressedKey ; check if the new key value is the same as the last pressed
                   ;     value
JE DebounceKey     ; if it is the same, keep debouncing key
;JNE ResetDebounce ; otherwise, reset debounce time and debounce new key

ResetDebounce:                     ; reset debouncing variables for new key
MOV PressedKey, AL                 ; store new pressed key
MOV DebounceCounter, DEBOUNCE_TIME ; reset time for key to be debounced
;JMP DebounceKey                   ; can now begin debouncing key

DebounceKey:
CALL KeypadDebounce  ; debounce row
JMP ScanEnd          ; finished scanning row

NoKeysPressed:
MOV KeyPressedFlag, 0 ; update the key pressed flag to false (no keys pressed)
MOV DebounceCounter, DEBOUNCE_TIME ; reset time for key to be debounced

; JMP ScanEnd         ; finished scanning row

ScanEnd:
RET
KeypadScan	ENDP

; KeypadDebounce
;
;
; Description: Debounces a key press. Called from KeypadScan if a key is pressed.
;     Given a pressed key, it counts down a debounce time. If the key is still
;     held after the debounce time, it is debounced, or considered pressed,
;     and the key and key event are enqueued.
;
; Operation: If a key is being pressed, it counts down until a debounce time
;     until they key is considered debounced. This means that one key press is
;     registered at this time. Next, EnqueueEvent is called with the key event
;     and key. Once a key is debounced, it begins the debounce time again while
;     the key is still pressed to auto-repeat the key.
;
; Arguments:        None.
; Return Values:    None.
;
; Local Variables:  If key is debounced, key event (AX) and pressed_key (AL)
;     for the key currently being pressed, are used.
;
; Shared Variables:
;     DebounceCounter (R/W)- 16-bit unsigned value, time key must be down to be
;         debounced.
;     PressedKey (R)- 8-bit value, key currently pressed or last key pressed.
;         The first byte is the row value (0-E), and the second byte is the
;         row value (0 to NUM_ROWS - 1).
;
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  Queues are used to hold the key event and pressed key.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers used:   AX
;
; Revision History: 10/31/16   Sophia Liu      initial revision

KeypadDebounce       PROC        NEAR

DEC DebounceCounter ; count down the time until debounced
;JZ KeyDebounced    ; if counter has reached zero, key is debounced
JNZ EndDebounce     ; else, key is not debounced, wait until called again

KeyDebounced:
MOV AH, KEY_EVENT   ; store key event constant for key event to be enqueued
MOV AL, PressedKey  ; store debounced, pressed key for key event to be enqueued
CALL EnqueueEvent   ; enqueue the key and key event now that the key is debounced
MOV DebounceCounter, REPEAT_RATE ; set the debounce counter for auto-repeating

EndDebounce:
RET
KeypadDebounce	ENDP

; KeypadInit
;
;
; Description: Initializes variables used while scanning and debouncing
;    keypad. Must be called before scanning the keypad.
;
; Operation: Resets keypress flag, initializes debounce counter to initial
;     debounce time, sets keypad row to the first row, and sets the pressed
;     key to an empty key.
;
; Arguments:        None.
; Return Values:    None.
; Local Variables:  None.
;
; Shared Variables:
;     DebounceCounter (W)- 16-bit unsigned value, time key must be down to be
;         debounced.
;     PressedKey (W)- 8-bit value, key currently pressed or last key pressed.
;         The first byte is the row value (0-E), and the second byte is the
;         row value (0 to NUM_ROWS - 1).
;     KeyPressedFlag (W) - 8-bit value, true (1) or false (0). True (1) if a key is
;         currently being pressed on the keypad, and false (0) if nothing is currently
;         pressed.
;     KeyRow (W)- 16-bit unsigned value, row currently being scanned on keypad.
;         Ranges from 0 to NUM_ROWS - 1.
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
; Registers used:   None.
;
; Revision History: 11/05/16   Sophia Liu      initial revision
;                   11/06/16   Sophia Liu      updated comments

KeypadInit       PROC        NEAR
                 PUBLIC      KeypadInit

MOV PressedKey, EMPTY_KEY          ; set pressed key to an empty key value
MOV DebounceCounter, DEBOUNCE_TIME ; set time for debounce to initial time
MOV KeyPressedFlag, 0              ; reset KeyPressedFlag to false (no keys pressed)
MOV KeyRow, 0                      ; begin scanning rows at initial row 0

RET
KeypadInit	ENDP

CODE    ENDS

;the data segment
DATA    SEGMENT PUBLIC  'DATA'

DebounceCounter  DW    ? ; time until key is debounced
KeyPressedFlag   DB    ? ; flag for pressed keys, true if a key is being pressed
KeyRow           DW    ? ; keypoad row currently being scanned
PressedKey       DB    ? ; key currently being pressed

DATA    ENDS

        END
