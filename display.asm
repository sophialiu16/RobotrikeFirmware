NAME DISPLAY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Display                                  ;
;                              LED Display Functions                         ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: Display.asm
; Description: This file contains functions for displaying strings and decimal
;              and hex numbers to multiplexed LEDs.
; Public functions: DisplayInit- Initializes the display by clearing LEDs and
;                       initializing variables.
;                   Display (str)- Outputs a null-terminated ASCII string to
;                       the DigitBuffer, to be outputted by LEDMux to the display.
;                   DisplayNum(n)- Outputs a 16-bit signed decimal number to
;                       the display. Zero-padded, 5-6 digits with a negative
;                       sign.
;                   DisplayHex(n)- Outputs a 16-bit value to the display in hex.
;                       Outputs 4 digits.
;                   LEDMux- Displays the string in the DigitBuffer by displaying
;                       one digit from the buffer every time it is called. It
;                       is called through a timer interrupt.
; Local functions: None.
; Input:          None.
; Output:         None.
; Error Handling: None.
; Algorithms:     None.
; Data Structures: Arrays with 16-bit elements are used to store segment patterns
;                  for the digit buffer and to store the ASCII string for
;                  DisplayNum and DisplayHex.
; Known Bugs:     None.
; Limitations:    None.
; Revision History: 10/28/16   Sophia Liu       initial revision
;                   10/30/16   Sophia Liu       updated comments
;                   12/03/16   Sophia Liu      Changed to 14 seg display

$INCLUDE(display.inc) ; local include file for display constants and addresses

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP

; External function calls
EXTRN   Dec2String:NEAR
EXTRN   Hex2String:NEAR
EXTRN   ASCIISegTable:WORD

; DisplayInit
;
;
; Description: Initializes the LED display. Clears the display by looping through
;     all the digits and setting them to the blank LED pattern. Initializes
;     other shared variables. Must be called before displaying any strings to
;     the LEDs.
;
; Operation: Sets all digits in buffer to the blank LED pattern. First gets the
;     blank segment pattern from the table, then stores it in the DigitBuffer
;     one digit at a time. Sets CurDigitInd to 0.
;
; Arguments:        None.
; Return Values:    None.
; Local Variables:  BufferPointer (DI) - 16-bit address, current index of DigitBuffer.
; Shared Variables: CurDigitInd  - 16-bit unsigned value containing the
;                       index of digit in DisplayBuffer being multiplexed.
;                       DisplayInit writes to this value.
;                   DigitBuffer - 16-bit array of words. Buffer containing
;                       segment patterns to be displayed to the LED display.
;                       DisplayInit writes to this array.
;
; Global Variables: None.
; Input:            None.
; Output:           Blanks LED display.
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  ASCII Seg Table- table used to get the blank LED character
;                   pattern.
; Known Bugs:       None.
; Limitations:      None.
; Registers used:   DI, AX, BX
;
; Revision History: 10/24/16   Sophia Liu      initial revision
;                   10/29/16   Sophia Liu      Fixed bugs
;                   10/30/16   Sophia Liu      Updated comments
;                   12/03/16   Sophia Liu      Changed to 14 seg display

DisplayInit       PROC        NEAR
                  PUBLIC      DisplayInit

ClearDisplay:
MOV DI, 0                ; set BufferPointer to first DigitBuffer element
MOV AL, ' '              ; get blank character
MOV BL, AL               ; move character to access table
XOR BH, BH
SHL BX, 1                ; multiply baud table index by 2 to access word table
MOV AX, CS:ASCIISegTable[BX] ; get the baud rate divisor from BaudTable

ClearDigitLoop:
SHL DI, 1
MOV DigitBuffer[DI], AX ; store blank pattern in DigitBuffer element
SHR DI, 1
INC DI                  ; increment BufferPointer to loop through DigitBuffer

CMP DI, DISPLAY_SIZE
;JE EndDisplayInit ; if BufferPointer points past last element in DigitBuffer,
                   ;     exit loop
JNE ClearDigitLoop ; else, continue going through DigitBuffer elements


EndDisplayInit:
MOV CurDigitInd, 0    ; initialize index of digit being multiplexed

RET
DisplayInit  ENDP


; Display
;
;
; Description: Outputs the digit patterns of a null terminated string (ES:SI)
;              to the DigitBuffer. These are outputted periodically in LEDMux.
;              It truncates strings after the 8th digit.
;
; Operation: Goes through each digit of str, by incrementing ES:SI. For each
;            character, it converts the character to a 7-segment pattern with
;            the ASCIISegTable and stores it in the next DigitBuffer address.
;
; Arguments: str (ES:SI)- 16-bit value containing address of a null-terminated
;                         string to output to the display.
;
; Return Values:    None.
;
; Local Variables:  BufferPointer (DI)- 16-bit address, current index of DigitBuffer.

; Shared Variables: DigitBuffer - 16-bit array of words. Buffer containing
;                       segment patterns to be displayed to the LED display.
;                       Display writes to this array.
;
; Global Variables: None.
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  ASCII Seg Table- table used to convert from ASCII characters
;                   to LED digit patterns.
; Known Bugs:       Truncated string past 8 digits.
; Limitations:      Can only display up to 8 digits at one time.
; Registers used:   DI, AX, SI, BX,
;
; Revision History: 10/24/16   Sophia Liu      initial revision
;                   10/30/16   Sophia Liu      Updated comments
Display       PROC        NEAR
              PUBLIC      Display

DisplayStart:
MOV DI, 0     ; Set BufferPointer to beginning of digit buffer

CheckNull:     ; look for end of string by looking for the null character
CMP BYTE PTR ES:[SI], ASCII_NULL
JE GetBlankDigit    ; if digit == ascii_null character, reached end of string,
                    ;     get blank digit
;JNE GetCharDigit   ; else, get the character at that address

GetCharDigit:
MOV AL, ES:[SI]    ; store the ASCII character at that address
INC SI             ; go to the next string address
JMP StoreDigit     ; go on to get the digit segment pattern

GetBlankDigit:
MOV AL, ' '       ; get blank character if the end of the string has been reached
;JMP StoreDigit   ; go on to get the digit segment pattern

StoreDigit:
MOV BL, AL               ; move baud table index to access table
XOR BH, BH
SHL BX, 1                ; multiply baud table index by 2 to access word table
MOV AX, CS:ASCIISegTable[BX] ; get the baud rate divisor from BaudTable
SHL DI, 1                     ; multiply by 2 word array access
MOV DigitBuffer[DI], AX       ; store character pattern in the digit buffer
SHR DI, 1                     ; restore non-modified index
INC DI                        ; go to the next digit buffer element
CMP DI, DISPLAY_SIZE
JNE CheckNull                 ; while BufferPointer has not reached the end of
                              ;     the DigitBuffer, go back to beginning of loop
;JE EndDisplay                ; If it has, all digits have been stored, done

EndDisplay:
RET
Display  ENDP

; DisplayNum
;
;
; Description: Outputs a 16-bit signed value n (AX) in decimal to the LED display.
;              Zero-padded, 5-6 digits with the negative sign.
;
; Operation: Calls Dec2String to convert the value n (AX) to a null-terminated
;            string. Dec2String returns to DS:SI, which is changed to ES:SI for
;            Display. Then calls Display to output the string to the DigitBuffer.
;
; Arguments: n (AX)- 16-bit signed value to output in decimal to the LED
;                display.
;
; Return Values:    None.
; Local Variables:  None.
; Shared Variables: DigitBuffer - 16-bit array of words. Buffer containing
;                       segment patterns to be displayed to the LED display.
;                       DisplayNum writes to this array.
;                   ASCIIString - 16-bit array of words. Buffer containing
;                       an ASCII string to be stored as character patterns in
;                       DigitBuffer. DisplayNum writes to this array.
; Global Variables: None.
;
; Input:            None.
; Output:           Outputs the value in decimal to the display. Zero-padded,
;                   5-6 digits with the negative sign.
;
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers used:   DS:SI, ES:SI
;
; Revision History: 10/24/16   Sophia Liu      initial revision
;                   10/29/16   Sophia Liu      fixed ES/DS related bugs
;                   10/30/16   Sophia Liu      Updated comments

DisplayNum       PROC        NEAR
                 PUBLIC      DisplayNum

MOV SI, OFFSET(ASCIIString) ; store ASCIIString in DS:SI to pass to Dec2String
CALL Dec2String             ; convert decimal to ASCII string and store in DS:SI
PUSH DS
POP ES                      ; change to ES for Display
MOV SI, OFFSET(ASCIIString) ; store ASCIIString in ES:SI for Display
CALL Display                ; write string character patterns to DigitBuffer
PUSH ES                     ; change back to DS, balance push/pops
POP DS

RET
DisplayNum  ENDP

; DisplayHex
;
;
; Description: Outputs a 16-bit unsigned value n (AX) in hexadecimal to the LED
;              display. 4 digits.
;
; Operation: Calls HexToString to convert the value n (AX) to a null-terminated
;            string. Hex2String returns to DS:SI, which is changed to ES:SI for
;            Display. Then calls Display to output the string to the DigitBuffer.
;
; Arguments: n (AX)- 16-bit signed value to output in hexadecimal to the LED
;                       display.
;
; Return Values:    None.
; Local Variables:  None.
; Shared Variables: DigitBuffer - 16-bit array of words. Buffer containing
;                       segment patterns to be displayed to the LED display.
;                       DisplayHex writes to this array.
;                   ASCIIString - 16-bit array of words. Buffer containing
;                       an ASCII string to be stored as character patterns in
;                       DigitBuffer. DisplayHex writes to this array.
; Global Variables: None.
;
; Input:            None.
; Output:           Outputs the value in hexadecimal to the display. 4 digits long.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers used:   DS:SI, ES:SI
;
; Revision History: 10/24/16   Sophia Liu      initial revision
;                   10/29/16   Sophia Liu      fixed ES/DS related bugs
;                   10/30/16   Sophia Liu      Updated comments
DisplayHex       PROC        NEAR
                 PUBLIC      DisplayHex

MOV SI, OFFSET(ASCIIString) ; store ASCIIString in DS:SI to pass to Hex2String
CALL Hex2String             ; convert decimal to ASCII string and store in DS:SI
PUSH DS                     ; change to ES for Display
POP ES
MOV SI, OFFSET(ASCIIString) ; store ASCIIString in ES:SI for Display
CALL Display                ; write string character patterns to DigitBuffer
PUSH ES                     ; change back to DS, balance push/pops
POP DS
RET
DisplayHex  ENDP

; LEDMux
;
;
; Description: Multiplexes the LED display under interrupt control. Each time
;              it is called through the timer event handler, it displays the next
;              digit in DigitBuffer.
;
; Operation: Outputs the next digit from the DigitBuffer each time it is called.
;            To do this, it updates CurDigitInd to the next index, gets the
;            segment pattern from the buffer, and outputs it to the LED display.
;
; Arguments: str (ES:SI)- 16-bit value containing address of a null-terminated
;                         string to output to the display.
;
; Return Values:    None.
; Local Variables:  None.
; Shared Variables: CurDigitInd  - 16-bit unsigned value containing the
;                       index of digit in DisplayBuffer being multiplexed.
;                       DisplayInit writes to this value.
;                   DigitBuffer - 16-bit array of words. Buffer containing
;                       segment patterns to be displayed to the LED display.
;                       DisplayInit writes to this array.
; Global Variables: None.
;
; Input:            None.
; Output:           Outputs the next digit to the LED display.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
; Registers used:   DX, BX, AX
;
; Revision History: 10/24/16   Sophia Liu      initial revision
;                   10/30/16   Sophia Liu      Updated comments
;                   12/03/16   Sophia Liu      Updated for 14 seg display

LEDMux    PROC        NEAR
          PUBLIC      LEDMux

NextDigit:
INC CurDigitInd  ; go to next index in DigitBuffer
CMP CurDigitInd, DISPLAY_SIZE
JNE UpdateDisplay ; if CurDigitInd has not reached the end of the buffer, update
                  ;     the display with the new index value
;JE WrapDigit     ; else is past end of buffer, wrap index around
                  ;     to beginning

WrapDigit:
MOV CurDigitInd, 0 ; wrap index around to the beginning by setting index to
                   ;    first index in DigitBuffer (0)
;JMP UpdateDisplay ; can now display new index value

UpdateDisplay:
MOV BX, CurDigitInd ; prepare to access display buffer
SHL BX, 1           ; multiply by 2 for word array access
MOV AX, DigitBuffer[BX] ; get segment pattern of current digit
SHR BX, 1           ; restore non-modified index

MOV DX, LED_DISPLAY_HIGH_BIT
XCHG AH, AL
OUT DX, AL          ; output the high bit of the pattern to the LED display

MOV DX, LED_DISPLAY  ; prepare to output to LED display by getting display address
ADD DX, BX           ; get address of next digit in display
XCHG AH, AL
OUT DX, AL           ; output the low bit of the pattern to the LED display



RET
LEDMux	ENDP


CODE    ENDS

;the data segment
DATA    SEGMENT PUBLIC  'DATA'

DigitBuffer    DW    DISPLAY_SIZE DUP (?) ; buffer holding segment patterns of
                         ; LED digits currently displayed
ASCIIString    DB    DISPLAY_SIZE DUP (?) ; string used to hold ASCII characters
                         ; to store in DigitBuffer

CurDigitInd    DW    ? ; current digit number being multiplexed


DATA    ENDS

        END
