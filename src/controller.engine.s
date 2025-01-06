
; -----------------------------------------------------------------------------
; joystick interaction
; -----------------------------------------------------------------------------
PREAD           EQU $FB1E ; Subcroutine, Read the joystick position X axis. Set LDX = #00 (Paddle 0) before PREAD to ensure the correct joystick is read.
PB0             EQU $C061 ; Address to load the button press from joystick 0.

; -----------------------------------------------------------------------------
; keyboard interation
; -----------------------------------------------------------------------------
KYBD			equ $C000 ; Address to read the last key pressed
STROBE			equ $C010 ; STA to Clear the last key pressed, sta to clear


; -----------------------------------------------------------------------------
; If joystick button is up, Execution will block and resume when button is pressed down
; -----------------------------------------------------------------------------
UnblockWhenButtonDown		lda PB0 					; read joystick button 0
							bpl UnblockWhenButtonDown
							rts	

; -----------------------------------------------------------------------------
; block until keypress
; -----------------------------------------------------------------------------
UnblockWhenKeyPressed		lda KYBD					; load last pressed key to accumulator
							cmp #$80
							bcc UnblockWhenKeyPressed
							sta STROBE 					; clear last keyboard key pressed
							clc
							rts



PDL0    					EQU  $C064
PDL1    					EQU  $C065
PTRIG   					EQU  $C070

ReadPaddleAxis    			lda  PTRIG
							ldx  #0
							ldy  #0
							pha               ; give some space for count = 0
							pla
_gotPdl1 					bit  $0
_chkPdl0 					lda  PDL0
							bpl  _gotPdl0
							nop
							iny
							lda  PDL1
							bmi  _noGots
							bpl  _goPtdl1
_noGots  					inx
							jmp  _chkPdl0

_gotPdl0 					bit  $0
							lda  PDL1
							bmi  _noGots
							rts	