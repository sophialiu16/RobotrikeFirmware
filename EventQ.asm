NAME EVENTQ
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  EventQ.asm                                ;
;                             Event Queue Functions                          ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: EventQ.asm
; Description:
; Public functions:
; Local functions:
; Input:          None.
; Output:         None.
;
; Revision History: 12/02/16 Sophia Liu       initial revision

$INCLUDE(Queue.inc)
$INCLUDE(Events.inc)
$INCLUDE(EventQ.inc)

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

; external functions
EXTRN   QueueInit:NEAR
EXTRN   QueueFull:NEAR
EXTRN   QueueEmpty:NEAR
EXTRN   Dequeue:NEAR
EXTRN   Enqueue:NEAR

; EnqueueEvent
;
;
; Description: Enqueues events (AH event constant, AL value) to the event
;              queue if it is not full. If the event queue is full, it sets
;              a critical error flag. Takes one argument, the event, in AX,
;              with AH as the event constant and AL as the value.
;
; Operation: Checks if the event queue is full. If it is, the CriticalErrorFlag
;            is set and the function returns. Otherwise, the event is enqueued.
;
; Arguments:         event (AX - AH event constant, AL value), the event to enqueue
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  CriticalErrorFlag (W) - 8-bit unsigned value, flag for critical
;                        errors. The value is 1 if there is an error, and 0 if there
;                        is not.
;                    EventQueue (W) - Word queue containing events for the
;                        RoboTrike.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
; Algorithms:        None.
; Data Structures:   None.
;
; Known Bugs:        Lose event if EventQueue is full
; Limitations:       None.
; Registers changed:
; Stack depth:
;
; Revision History: 11/29/16   Sophia Liu      initial revision

EnqueueEvent       PROC        NEAR
                   PUBLIC      EnqueueEvent

MOV SI, OFFSET(EventQueue) ; pass in event queue address to check if empty
CALL QueueFull             ; check if event queue is empty
JZ EventQueueFull          ; if queue is full, zero flag is set, cannot enqueue event
;JNZ EventQueueNotFull     ; else queue is not full, enqueue event

EventQueueNotFull:
Call Enqueue               ; enqueue event
JMP EnqueueEventEnd        ; done enqueuing

EventQueueFull:
MOV CriticalErrorFlag, CRITICAL_ERROR ; if event queue is full, something went wrong,
                                      ; set critical error flag and return
; JMP EnqueuEventEnd

EnqueueEventEnd:
RET
EnqueueEvent	ENDP

; DequeueEvent
;
;
; Description: Dequeues events (AH event constant, AL value) from the event
;              queue if it is not empty. Calls the appropriate handler from
;              a command table to deal with the event.
;
; Operation: Checks that the event queue is not empty. If it is not empty,
;            an event is dequeued and the appropriate handler is called from
;            the command table to deal with the event.
;
; Arguments:         None.
; Return Values:     Return event in AX (value NO_EVENT if no event)
;
; Local Variables:   None.
; Shared Variables:  EventQueue (W) - Word queue containing events for the
;                        RoboTrike.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
; Algorithms:        None.
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       None.
; Registers changed:
; Stack depth:
;
; Revision History: 11/29/16   Sophia Liu      initial revision
DequeueEvent       PROC        NEAR
                   PUBLIC      DequeueEvent
MOV SI, OFFSET(EventQueue) ; pass in event queue address to check if empty
CALL QueueEmpty            ; check if event queue is empty
JZ EventQueueEmpty         ; if queue is empty, zero flag is set, cannot dequeue event
;JNZ EventQueueNotEmpty    ; else queue is not empty, dequeue event

EventQueueNotEmpty:
CALL Dequeue               ; Dequeue event from queue into AX
JMP DequeueEventEnd        ; finished dequeueing, can end

EventQueueEmpty:
MOV AX, NO_EVENT           ; if the event queue is empty, return with no event
;JMP DequeueEventEnd

DequeueEventEnd:
RET
DequeueEvent	ENDP

; InitEvent
;
;
; Description: Initializes the event queue to be a word queue and resets the
;              critical error flag.
;
; Operation: Initializes the event queue to be empty with word elements,
;            and resets the CriticalErrorFlag.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  CriticalErrorFlag (W) - 8-bit unsigned value, flag for critical
;                        errors. The value is 1 if there is an error, and 0 if there
;                        is not.
;                    EventQueue (W) - Word queue containing events for the
;                        RoboTrike.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
; Algorithms:        None.
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       None.
; Registers changed: SI, BL
; Stack depth:
;
; Revision History: 11/29/16   Sophia Liu      initial revision

InitEvent       PROC        NEAR
                PUBLIC      InitEvent
MOV SI, OFFSET(EventQueue) ; pass in address of EventQueue to initialize
MOV BL, WORD_ELEMENTS      ; pass in argument indicating queue elements are words
CALL QueueInit             ; initialize EventQueue as word queue

MOV CriticalErrorFlag, NO_CRITICAL_ERROR ; initialize with no critical error

RET
InitEvent	ENDP

; CheckCriticalFlag
;
;
; Description:       Returns the status of the critical error flag. Sets the carry
;                    flag if there is a critical error, and resets the carry flag if
;                    there is no critical error.
;
; Operation:         Checks the value of the critical error flag. Sets the carry
;                    flag if there is a critical error, and resets the carry flag if
;                    there is no critical error.
;
; Arguments:         None.
; Return Values:     Returns with the carry flag set if there is a critical error,
;                    and with the carry flag reset if there is no critical error.
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
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       None.
; Registers changed: CF
; Stack depth:       0 words.
;
; Revision History: 12/02/16   Sophia Liu      initial revision
;
CheckCriticalErrorFlag       PROC        NEAR
                             PUBLIC      CheckCriticalErrorFlag
; return critical flag status
CMP CriticalErrorFlag, CRITICAL_ERROR
JE HaveCriticalError
; JNE NoCriticalError

NoCriticalError:
CLC      ; clear carry flag if there is no critical error
JMP CheckCriticalErrorFlagEnd   ; can end now

HaveCriticalError:
STC      ; set carry flag if there is a critical error
; JMP CheckCriticalErrorFlagEnd ; can end now

CheckCriticalErrorFlagEnd:
RET
CheckCriticalErrorFlag	ENDP

CODE    ENDS

DATA    SEGMENT PUBLIC  'DATA'

CriticalErrorFlag        DB ? ; flag...
EventQueue QUEUESTRUC    <>   ; event queue...

DATA    ENDS

        END
