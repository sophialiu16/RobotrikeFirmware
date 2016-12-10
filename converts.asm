        NAME    CONVERTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   CONVERTS                                 ;
;                             Conversion Functions                           ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Name: Sophia Liu 
; Name of program: Converts, conversion functions 
; Function of program: Converts contains functions for converting 16-bit 
;                      signed decimal values to a decimal value (Dec2String) 
;                      and a 16-bit unsigned decimal values to a hexadecimal 
;                      value (Hex2String) stored in a  
;                      null terminated ASCII string at a given address. 
; Table of Contents: 
;     Dec2String function - begins at line 39
;     Hex2String function - begins at line 126
; 
; Revision History:
;     1/26/06  Glen George      initial revision
;     10/14/16 Sophia Liu       added initial code
;     10/14/16 Sophia Liu       fixed bugs 
;     10/14/16 Sophia Liu       added inc file for constants
;     10/15/16 Sophia Liu       updated comments

$INCLUDE(converts.inc)    ; include file for constants 
CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

; Dec2String
;
;
; Description:      This function converts the 16-bit signed decimal value 
;                   passed to it to decimal (at most 5 digits plus sign). 
;                   The decimal is stored in a <null> terminated ASCII string, 
;                   includes a '-' sign if negative and no sign if positive, 
;                   and is not 0-padded. The string is stored starting at the 
;                   memory location indicated by the passed address.
;
; Operation:        The function first checks for a negative value. If it is
;                   negative, a negative sign is stored in the result and the
;                   value is negated. Next, beginning with the highest power
;                   possible (10^4) it loops and divides the number by the power
;                   of 10. The quotient is a digit and the remainder is used in
;                   the next iteration of the loop. The digit is then converted
;                   to ASCII and stored. Each loop iteration divides the power
;                   of 10 by 10 until it is 0. At that point a null character
;                   is stored to finish the ASCII string.
;
; Arguments:        n (AX) - 16-bit signed decimal value to convert to 
;                            decimal string.
;                   a (SI) - 16-bit address the ASCII string will be stored in.
;
; Return Values:    None.
;
; Local Variables:  pwr10 (BX) - 16-bit unsigned decimal value that holds the
;                                current power of 10 being computed.
;
; Shared Variables: None.
; Global Variables: None.
; Input:            None.
; Output:           None.
; Error Handling:   None.
;
; Algorithms:       Repeatedly divide by powers of 10 to get the highest
;                   decimal digits.
;
; Data Structures:  None.
; Known Bugs:       None.
; Limitations:      Assumes a valid address (a).
;
; Revision History: 10/10/2016    Sophia Liu    initial revision with pseudo
;                                               code.
;                   10/14/2016    Sophia Liu    Outline revision
;                   10/14/2016    Sophia Liu    Fixed bugs- use of [SI]
;                   10/15/2016    Sophia Liu    Added comments 

Dec2String      PROC        NEAR
                PUBLIC      Dec2String

Dec2StringInit:            ; initialize variables
MOV BX, 10000              ; BX is pwr10

Dec2StringNegative:        ; checks for negative value
CMP AX, 0
JGE Dec2StringDigitLoop    ; if AX is not negative, go to main loop
NEG AX                     ; else negate AX and store negative sign 
MOV BYTE PTR [SI], '-'     ; store negative sign 
INC SI                     ; go to next address for next digit

Dec2StringDigitLoop:       ; while pwr10 > 0, loop through digits of n 
CMP BX, 0
JLE Dec2StringHaveString   ; jump to end if pwr10 <= 0 (have all digits)

Dec2StringDigitLoopBody:   ; main body for while loop
MOV DX, 0                  ; clear DX to prepare for division 
DIV BX                     ; divide n by pwr10 to get next highest digit
ADD AX, '0'                ; convert quotient (digit) to ASCII character
MOV BYTE PTR [SI], AL      ; store ASCII character in next address
INC SI                     ; go to next address for next digit 
MOV CX, DX                 ; temp storage of remainder (remaining digits of n)
MOV AX, BX                 ; store pwr10 in AX to prepare for division of pwr10
MOV BX, 10                 ; store 10 in BX to prepare to divide pwr 10 by 10 
MOV DX, 0                  ; clear DX to prepare for division 
DIV BX                     ; divide pwr10 by 10 to get next highest power of 10
MOV BX, AX                 ; store quotient of pwr10/10 in pwr10 variable 
MOV AX, CX                 ; store the next/remaining digits of n in n
JMP Dec2StringDigitLoop    ; jump back to while loop header

Dec2StringHaveString:           ; have stored all  ASCII digits 
MOV BYTE PTR [SI], ASCII_NULL   ; store ASCII null character to terminate string
RET

Dec2String	ENDP


; Hex2String
;
;
; Description:      This function converts the 16-bit unsigned decimal value 
;                   passed to it to hexadecimal (at most 4 digits). 
;                   The hexadecimal is stored in a <null> terminated ASCII 
;                   string and is not 0-padded. The string is stored starting 
;                   at the memory location indicated by the passed address.
;
; Operation:        The function begins with the highest power of 16
;                   possible(16^3). It loops and divides the number by the power
;                   of 16. The quotient is a digit and the remainder is used in
;                   the next iteration of the loop. The digit is then converted
;                   to ASCII and stored. Each loop iteration divides the power
;                   of 16 by 16 until it is 0. At that point a null character
;                   is stored to terminate the ASCII string.
;
; Arguments:        n (AX) - 16-bit unsigned decimal value to convert to 
;                            a hexadecimal string
;                   a (SI) - 16-bit address the ASCII string will be stored in 
;
; Return Values:    None.
;
; Local Variables:  pwr16 (BX)  - 16-bit unsigned decimal value containing
;                                 current power of 16 being computed.
;
; Shared Variables: None.
; Global Variables: None.
; Input:            None.
; Output:           None.
; Error Handling:   None.
;
; Algorithms:       Repeatedly divide by powers of 16 to get the next highest
;                   hexadecimal digits.
;
; Data Structures:  None.
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History: 10/11/2016    Sophia Liu    initial revision with pseudo
;                                               code.
;                   10/14/2016    Sophia Liu    fixed bugs- offset for 'A'
;                   10/15/2016    Sophia Liu    added comments 

Hex2String      PROC        NEAR
                PUBLIC      Hex2String

Hex2StringInit:           ; initialize variables
MOV BX, 4096              ; BX is pwr16 (begins at 16^3)

Hex2StringDigitLoop:      ; while pwr16 > 0, loop through digits of n
CMP BX, 0
JLE Hex2StringHaveString  ; jump to end if pwr16 <= 0 (have all digits) 

Hex2StringDigitLoopBody:  ; loop through all the digits 
MOV DX, 0                 ; clear DX to prepare for division 
DIV BX                    ; divide n by pwr16 to get next highest digit 
CMP AX, 10
JGE Hex2StringLetterDigit ; if digit >= 10, convert to ASCII letter (A-F)

Hex2StringNumberDigit:    ; else, convert to ASCII number character(0-9)
ADD AX, '0'               ; convert digit to ASCII 
JMP Hex2StringHaveDigit   ; have digit, proceed to rest of while loop 

Hex2StringLetterDigit:    ; convert to ASCII letter (A-F)
ADD AX, 'A'               ; convert digit to ASCII
SUB AX, A_OFFSET          ; offset digit to correctly convert to ASCII 

Hex2StringHaveDigit:
MOV BYTE PTR [SI], AL     ; store ASCII digit in next address
INC SI                    ; go to next address for next digit 
MOV CX, DX                ; temp storage of remainder 
MOV AX, BX                ; store pwr16 in AX to prepare for division of pwr16
MOV BX, 16                ; store 16 in BX to prepare to divide pwr16 by 16
MOV DX, 0                 ; clear DX to prepare for division 
DIV BX                    ; divide pwr16 by 16 to get next highest power of 16
MOV BX, AX                ; store next highest power of 16 in pwr16 variable
MOV AX, CX                ; store the next/remaining digits of n in n 
JMP Hex2StringDigitLoop   ; go back to while loop header 

Hex2StringHaveString:           ; have stored all ASCII digits 
MOV BYTE PTR [SI], ASCII_NULL   ; store ASCII null character to terminate string
RET

Hex2String	ENDP



CODE    ENDS



        END
