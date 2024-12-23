
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
							rts