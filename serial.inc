
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Serial.inc                                ;
;                              Serial include file                           ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Name of file: Serial.inc
; Description: Include file containing serial constants and addresses.
;
; Revision History: 11/17/16 Sophia Liu       initial revision
;                   11/20/16 Sophia Liu       updated comments 

; general constants
KICKSTART_OFF      EQU 0 ; value indicating no kickstart is needed
KICKSTART_ON       EQU 1 ; value indicating kickstart is needed to reactivate
                         ;     transmit interrupts

; serial constants

; Line Status Register (LSR) - provides information to the CPU concerning the
;     state of data transfers

LSR_DATAREADY      EQU 00000001B ; Data ready bit set, incoming character received (DR)
LSR_OVERRUN_ERROR  EQU 00000010B ; Overrun error (OE)
LSR_PARITY_ERROR   EQU 00000100B ; Parity error (PE)
LSR_FRAMING_ERROR  EQU 00001000B ; Framing error (FE)
LSR_BREAK_ERROR    EQU 00010000B ; Break interrupt indicator (BI)
LSR_THR_EMPTY      EQU 00100000B ; THR empty indicator
LSR_TRANS_EMPTY    EQU 01000000B ; Transmitter empty (TEMT) indicator

LSR_ERROR_BIT_MASK EQU 00011110B ; mask for error bits in LSR


; Line Control Register (LCR) - controls format of asynchronous data communication
;     exchange

LCR_WORDBIT0       EQU 00000001B ; Word length select bit 0 (WLSB0)
LCR_WORDBIT1       EQU 00000010B ; Word length select bit 1 (WLSB1)
LCR_STOPBITS       EQU 00000100B ; Specifies number of stop bits (STB)
LCR_PARITYENABLE   EQU 00001000B ; Parity enable bit set (PEN)
LCR_EVENPARITY     EQU 00010000B ; Even parity select bit set (EPS)
LCR_STICKPARITY    EQU 00100000B ; Stick parity bit set
LCR_SETBREAK       EQU 01000000B ; Break control bit; set to force break condition
LCR_DLAB_EN        EQU 10000000B ; Divisor latch access bit set (DLAB), enable
                                 ;     access to the baud rate divisor

LCR_PARITY_MASK    EQU 11000111B ; Mask parity bits

LCR_INIT        EQU LCR_WORDBIT0 OR LCR_WORDBIT1
                                        ;0-------  access Rx/Tx data registers
                                        ;-0------  no break output
                                        ;--000---  no parity
                                        ;-----0--  one stop bit
                                        ;------11  8 data bits

; Interrupt enable register (IER) - enables or disables interrupts
IER_RXDATA      EQU 00000001B ; enable received data available interrupt
IER_THRE        EQU 00000010B ; enable THRE interrupt
IER_RX_LS       EQU 00000100B ; enable receiver line status interrupt
IER_MS          EQU 00001000B ; enable modem status interrupt


IER_EN_IRQ   EQU IER_RXDATA OR IER_THRE OR IER_RX_LS OR IER_MS
                ; enable all serial interrupts

; Interrupt identification register (IIR)
NO_PENDING_INTS EQU     1 ; value of IIR if there are no pending interrupts

; Register I/O Addresses
SERIAL_BASE     EQU     100H            ;base address for serial
SERIAL_BRG_DIV  EQU     SERIAL_BASE + 0 ;baud rate generator divisor (R/W)
SERIAL_RX_REG   EQU     SERIAL_BASE + 0 ;receive data register (R)
SERIAL_TX_REG   EQU     SERIAL_BASE + 0 ;transmit data register (W)
SERIAL_IER      EQU     SERIAL_BASE + 1 ;interrupt enable register (R/W)
SERIAL_IIR      EQU     SERIAL_BASE + 2 ;interrupt ID register (R)
SERIAL_LCR      EQU     SERIAL_BASE + 3 ;line control register (R/W)
SERIAL_MCR      EQU     SERIAL_BASE + 4 ;modem control register (R/W)
SERIAL_LSR      EQU     SERIAL_BASE + 5 ;line status register (R/W)
SERIAL_MSR      EQU     SERIAL_BASE + 6  ;modem status register (R/W)
