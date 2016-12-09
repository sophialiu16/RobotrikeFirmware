        NAME    QUEUE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     QUEUE                                  ;
;                                Queue Functions                             ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Name of file: queue.asm
; Description: This file contains the functions for implementing queues
; Public functions:
;     - QueueInit(a, l, s) - initializes the queue pointed to by a to be of
;         a fixed length (QUEUELENGTH), with elements of size s
;     - QueueEmpty(a) - returns whether or not the queue pointed to by a is empty
;     - QueueFull(a) - returns whether or not the queue pointed to by a is full
;     - Dequeue(a)- remove and return the value at the head of the queue
;         pointed to by a
;     - Enqueue(a, v) - add the value v to the queue pointed to by a
;
; Input:          None.
; Output:         None.
; User Interface: None.
; Error Handling: None.
; Algorithms:     None.
; Data Structures:  Queue - A first-in-first-out data structure that stores
;                           a list of bytes or words. Stores a maxumim of
;                           QUEUELENGTH (255 bytes).
;                           Has the following elements:
;                   - head: 16-bit unsigned value. Head of queue, contains the
;                           location of the first occupied position. Offset so
;                           that 0 is the beginning of the queue.
;                   - tail: 16-bit unsigned value. Tail of queue, contains
;                           the empty location after the last entry (the hole).
;                           Offset so that 0 is the beginning of the queue.
;                   - element: 8-bit value indicating size of elements
;                             (in bytes)in queue. Either BYTE_SIZE (1 byte) or
;                              WORD_SIZE (2 bytes).
;                   - array: Array with 1-byte values that contain values
;                            stored in queue. Has length ARRAYLENGTH
;                            (QUEUELENGTH + 1 for hole).
; Known Bugs:     None.
; Limitations:    None.
; Revision History:
;     10/21/2016 Sophia Liu       added initial code
;     10/22/2016 Sophia Liu       fixed bugs - overriding arguments
;                                          - incorrectly checking when full
;     10/21/2016 Sophia Liu       added comments

$INCLUDE(queue.inc) ; local include file for constants and queue structure

CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

; QueueInit
;
;
; Description: Initializes the queue pointed to by a to be of fixed length
;              QUEUELENGTH (255) elements, with elements of size s. Queue is
;              empty and ready to accept values after initializing.
;
; Operation: Initializes the head and tail elements of the queue to point to
;            the beginning of the queue. Initializes the element size to
;            either BYTE_SIZE or WORD_SIZE.
;
; Arguments: a (DS:SI) - 16-bit address queue will be initialized at
;            l (AX) - 16-bit value indicating the maximum number of items that
;                     can be stored in the queue
;            s (BL) - 8-bit value used to specify size of entries in queue. If
;                     s is true (non-zero), elements are words (16-bits). If
;                     s is false (zero), elements are bytes (8-bits).
;
; Return Values:    None.
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
; Input:            None.
; Output:           None.
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  Queue - A first-in-first-out data structure that stores
;                           a list of bytes or words. Stores a maxumim of
;                           QUEUELENGTH (255 bytes).
;                           Has the following elements:
;                   - head: 16-bit unsigned value. Head of queue, contains the
;                           location of the first occupied position. Offset so
;                           that 0 is the beginning of the queue.
;                   - tail: 16-bit unsigned value. Tail of queue, contains
;                           the empty location after the last entry (the hole).
;                           Offset so that 0 is the beginning of the queue.
;                   - element: 8-bit value indicating size of elements
;                             (in bytes)in queue. Either BYTE_SIZE (1 byte) or
;                              WORD_SIZE (2 bytes).
;                   - array: Array with 1-byte values that contain values
;                            stored in queue. Has length ARRAYLENGTH
;                            (QUEUELENGTH + 1 for hole).
; Known Bugs:       None.
; Limitations:      Assumes a valid address (a). Queue has a fixed length
;                   of QUEUELENGTH (255 bytes).
;
; Revision History: 10/20/2016    Sophia Liu    Initial revision with pseudo
;                                               code.
;                   10/22/2016    Sophia Liu    Added comments.

QueueInit       PROC        NEAR
                PUBLIC      QueueInit

InitializeQueue:
    MOV [SI].head, HEAD_INIT    ; initialize head and tail to beginning
    MOV [SI].tail, TAIL_INIT    ;     of queue
    CMP BL, 0                   ; determine if elements are words or bytes
    JE ByteQueue                ; if s is zero elements are bytes
    ;JNE WordQueue              ; otherwise elements are words

WordQueue:                      ; if queue elements are words
    MOV [SI].element, WORD_SIZE ; initialize queue.element as word (2 bytes)
    JMP EndInit

ByteQueue:                      ; if queue elements are qytes
    MOV [SI].element, BYTE_SIZE ;initialize queue.element as 1 (byte)
    ;JMP EndInit

EndInit:
RET
QueueInit	ENDP


; QueueEmpty
;
;
; Description: Checks if the queue is empty. Returns with the zero flag set if
;              the queue is empty and with the zero flag reset otherwise.
;
; Operation: Checks if the queue is empty by comparing the head and tail
;            pointers. If the head points to the same address as the tail,
;            the queue is empty and the zero flag is set. Otherwise, the zero
;            flag is reset.
;
; Arguments: a (DS:SI) - 16-bit address of queue to be checked
;
; Return Values:    None.
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
; Input:            None.
; Output:           None.
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  Queue - A first-in-first-out data structure that stores
;                           a list of bytes or words. Stores a maxumim of
;                           QUEUELENGTH (255 bytes).
;                           Has the following elements:
;                   - head: 16-bit unsigned value. Head of queue, contains the
;                           location of the first occupied position. Offset so
;                           that 0 is the beginning of the queue.
;                   - tail: 16-bit unsigned value. Tail of queue, contains
;                           the empty location after the last entry (the hole).
;                           Offset so that 0 is the beginning of the queue.
;                   - element: 8-bit value indicating size of elements
;                             (in bytes)in queue. Either BYTE_SIZE (1 byte) or
;                              WORD_SIZE (2 bytes).
;                   - array: Array with 1-byte values that contain values
;                            stored in queue. Has length ARRAYLENGTH
;                            (QUEUELENGTH + 1 for hole).
; Known Bugs:       None.
; Limitations:      Assumes a valid address (a) and an initialized queue at
;                   that address.
;
; Revision History: 10/21/2016    Sophia Liu    initial revision with pseudo
;                                               code.
;                   10/22/2016    Sophia Liu    Added comments.

QueueEmpty       PROC        NEAR
                PUBLIC      QueueEmpty

CheckQueueEmpty:
MOV BX, [SI].head ; prepare for compare operation
CMP BX, [SI].tail ; queue is empty if head == tail, CMP sets zero flag


RET
QueueEmpty	ENDP

; QueueFull
;
;
; Description: Checks if the queue is full. Returns with the zero flag set if
;              the queue is full and with the zero flag reset otherwise.
;
; Operation: Checks if the queue is full by comparing the head and tail.
;            Queue is full if adding another element would cause the
;            tail to point to the same position as the head, or if
;            head == (tail + 1 element) MOD queue length.
;
; Arguments: a (DS:SI) - 16-bit address of queue to be checked.
;
; Return Values:    None.
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
; Input:            None.
; Output:           None.
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  Queue - A first-in-first-out data structure that stores
;                           a list of bytes or words. Stores a maxumim of
;                           QUEUELENGTH (255 bytes).
;                           Has the following elements:
;                   - head: 16-bit unsigned value. Head of queue, contains the
;                           location of the first occupied position. Offset so
;                           that 0 is the beginning of the queue.
;                   - tail: 16-bit unsigned value. Tail of queue, contains
;                           the empty location after the last entry (the hole).
;                           Offset so that 0 is the beginning of the queue.
;                   - element: 8-bit value indicating size of elements
;                             (in bytes)in queue. Either BYTE_SIZE (1 byte) or
;                              WORD_SIZE (2 bytes).
;                   - array: Array with 1-byte values that contain values
;                            stored in queue. Has length ARRAYLENGTH
;                            (QUEUELENGTH + 1 for hole).
; Known Bugs:       None.
; Limitations:      Assumes a valid address (a) and an initialized queue at
;                   that address.
;
; Revision History: 10/21/2016    Sophia Liu    initial revision with pseudo
;                                               code.
;                   10/22/2016    Sophia Liu    Added comments.

QueueFull       PROC        NEAR
                PUBLIC      QueueFull

CheckQueueFull:
MOV BX, [SI].tail ; prepare for comparison of tail and head
INC BX            ; increment 1 byte to next tail position
CMP [SI].element, BYTE_SIZE
JE ModLength      ; if elements are 1 byte in size, move on to compare
;JNE wordElement  ; otherwise, have to move tail another byte

WordElement:
INC BX            ; increment tail again to get to second byte for word
;JMP ModLength

ModLength:
AND BX, QUEUELENGTH            ; mod (for powers of 2) to wrap around queue
CMP BX, [SI].head      ; check if next tail value == head, sets zero flag if so
                       ;     (means queue is full)

RET
QueueFull	ENDP

; Dequeue
;
;
; Description: Removes either an 8-bit or 16-bit value (depending on queue's
;              element size) from the head of the queue at the passed address
;              (a) and returns it in AL or AX. The value is returned in AL if
;              the element size is bytes and in AX if it is words. If the
;              queue is empty it waits until the queue has a value to be
;              removed and returned. It does not return until a value is taken
;              from the queue.
;
; Operation: Blocks until queue is not empty using a while loop. Once that
;            happens, it takes the byte located at the head of the queue
;            and stores it in AL. It increments the head and stores the byte
;            in that location in AH if the element is a word
;            (2 bytes- entire word located at AX). The head is then incremented
;            and the modulo is taken with the queue length to find the next
;            head position.
;
; Arguments: a (DS:SI) - 16-bit address of queue.
;
; Return Values: AX or AL (depending on element size) - 16-bit or 8-bit element
;                    dequeued from queue head.
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
; Input:            None.
; Output:           None.
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  Queue - A first-in-first-out data structure that stores
;                           a list of bytes or words. Stores a maxumim of
;                           QUEUELENGTH (255 bytes).
;                           Has the following elements:
;                   - head: 16-bit unsigned value. Head of queue, contains the
;                           location of the first occupied position. Offset so
;                           that 0 is the beginning of the queue.
;                   - tail: 16-bit unsigned value. Tail of queue, contains
;                           the empty location after the last entry (the hole).
;                           Offset so that 0 is the beginning of the queue.
;                   - element: 8-bit value indicating size of elements
;                             (in bytes)in queue. Either BYTE_SIZE (1 byte) or
;                              WORD_SIZE (2 bytes).
;                   - array: Array with 1-byte values that contain values
;                            stored in queue. Has length ARRAYLENGTH
;                            (QUEUELENGTH + 1 for hole).
; Known Bugs:       None.
; Limitations:      Assumes a valid address (a) and an initialized queue at
;                   that address.
;
; Revision History: 10/21/2016    Sophia Liu    initial revision with pseudo
;                                               code.
;                   10/22/2016    Sophia Liu    Added comments.

Dequeue       PROC        NEAR
              PUBLIC      Dequeue

WhileEmptyLoop:    ; block until queue is not empty
CALL QueueEmpty
JE WhileEmptyLoop  ; keep looping while the queue is empty
;JNE NotEmpty      ; go on if/when the queue is not empty

NotEmpty:
MOV BX, [SI].head           ; prepare to get element located at head
MOV AL, [SI].array[BX]      ; got byte currently located at head
CMP [SI].element, BYTE_SIZE
JE IncHead                  ; if element is byte, go on to find next head value
;JNE DequeueWord            ; otherwise, dequeue high byte

DequeueWord:
INC BX                     ; increment head to get to next byte for word
AND BX, QUEUELENGTH        ; mod (for powers of 2) to wrap around queue
MOV AH, [SI].array[BX]     ; got high byte for word
;JMP IncHead

IncHead:
INC BX                    ; go to next head value
AND BX, QUEUELENGTH       ; mod (for powers of 2) to wrap around queue
MOV [SI].head, BX         ; save next head position

RET
Dequeue	ENDP

; Enqueue
;
;
; Description: This function adds the passed 8-bit or 16-bit (depending on
;              the element size) value (v) to the tail of the queue at the
;              passed address (a). If the queue is full it waits until the
;              queue has an open space in which to add the value. It does
;              not return until the value is added to the queue.
;
; Operation: Blocks until queue is not full using a while loop by calling
;            QueueFull. Once that happens, it stores AL into the address
;            indicated by the tail. If the element is a word, it increments
;            to the next tail position and stores AH. The tail is then
;            incremented and the modulo is taken with the queue length to find
;            the next tail position.
;
; Arguments: a (DS:SI) - 16-bit address of queue.
;            v (AX or AL) - value to be added to the tail of the queue
;
; Return Values:    None.
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
; Input:            None.
; Output:           None.
; Error Handling:   None.
; Algorithms:       None.
; Data Structures:  Queue - A first-in-first-out data structure that stores
;                           a list of bytes or words. Stores a maxumim of
;                           QUEUELENGTH (255 bytes).
;                           Has the following elements:
;                   - head: 16-bit unsigned value. Head of queue, contains the
;                           location of the first occupied position. Offset so
;                           that 0 is the beginning of the queue.
;                   - tail: 16-bit unsigned value. Tail of queue, contains
;                           the empty location after the last entry (the hole).
;                           Offset so that 0 is the beginning of the queue.
;                   - element: 8-bit value indicating size of elements
;                             (in bytes)in queue. Either BYTE_SIZE (1 byte) or
;                              WORD_SIZE (2 bytes).
;                   - array: Array with 1-byte values that contain values
;                            stored in queue. Has length ARRAYLENGTH
;                            (QUEUELENGTH + 1 for hole).
; Known Bugs:       None.
; Limitations:      Assumes a valid address (a) and an initialized queue at
;                   that address.
;
; Revision History: 10/21/2016    Sophia Liu    initial revision with pseudo
;                                               code.
;                   10/22/2016    Sophia Liu    Added comments.

Enqueue         PROC        NEAR
                PUBLIC      Enqueue

WhileFullLoop:           ; block until queue is not full
CALL QueueFull
JE WhileFullLoop         ; keep looping while the queue is full
;JNE NotFull             ; go on if/when the queue is not full

NotFull:
MOV BX, [SI].tail        ; prepare to store at tail location
MOV [SI].array[BX], AL   ; store byte at tail
CMP [SI].element, BYTE_SIZE
JE IncTail               ; if element is byte, go on to find next tail value
;JNE EnqueueWord         ; otherwise, enqueue high byte

EnqueueWord:
INC BX                   ; increment tail to store next byte for word
AND BX, QUEUELENGTH      ; mod (for powers of 2) to wrap around queue
MOV [SI].array[BX], AH   ; enqueue high byte at next address for word
;JMP IncTail

IncTail:
INC BX                   ; go to next tail value
AND BX, QUEUELENGTH      ; mod (for powers of 2) to wrap around queue
MOV [SI].tail, BX        ; save next tail position

RET
Enqueue	ENDP



CODE    ENDS

        END
