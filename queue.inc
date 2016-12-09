;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   QUEUE.INC                                ;
;                                Queue Constants                             ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: This file contains the definitions for various queue constants
;     and for the queue structure.
;
; Revision History:
;     10/21/2016 Sophia Liu    initial revision
;     10/22/2016 Sophia Liu    updated comments
;     11/20/2016 Sophia Liu    updated

ARRAYLENGTH     EQU 256              ; fixed length of array (queue + hole)
QUEUELENGTH     EQU ARRAYLENGTH - 1  ; fixed length of queue
HEAD_INIT       EQU 0                ; initial head value (beginning of queue)
TAIL_INIT       EQU 0                ; initial tail value (beginning of queue)
BYTE_SIZE       EQU 1                ; size of byte-sized element (1 byte)
WORD_SIZE       EQU 2                ; size of word-sized element (2 bytes)

BYTE_ELEMENTS   EQU 0                ; argument for byte-sized elements
WORD_ELEMENTS   EQU 1                ; argument for word-sized elements 

; Structure for queue
QUEUESTRUC       STRUC
    head         DW      ?    ; contains first occupied position
    tail         DW      ?    ; contains last occupied position
    element      DB      ?    ; element size (1 or 2 bytes)
    array        DB ARRAYLENGTH DUP (?)
QUEUESTRUC    ENDS
