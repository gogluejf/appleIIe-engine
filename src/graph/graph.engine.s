
; -----------------------------------------------------------------------------
; Graph
; -----------------------------------------------------------------------------
GR              equ $C050 ; STA to graphics mode, in low resolution
TEXT            equ $C051 ; STA to switch back to text mode
FULLSCREEN      equ $C052 ; STA to full screen, no text line at bottom
3LINE_TEXT      equ $C053 ; STA to screen with text 3 lines at bottom
LO_RES          equ $C056 ; STA low resolution graphics mode
HI_RES          equ $C057 ; STA to set to high resolution graphics mode, no screen clear
HI_RES_PAGE1    equ $C054 ; STA to display to hi res page 1, no clear screen
HI_RES_PAGE2    equ $C055 ; STA to display to hi res page 2, no clear screen
HCLR            equ $F3F2 ; Subroutine to clear current screen to black
BKGND           equ $F3F6 ; Subroutine to clear current screen to last plotted HCOLOR
HGR             equ $F3E2 ; Subroutine to hi-res graphics mode subroutine, clear page 1
HGR2            equ $F3D8 ; Subroutine to hi-res graphics mode subroutine, clear page 2

; -----------------------------------------------------------------------------
; Colors
; -----------------------------------------------------------------------------
HCOLOR          equ $F6F0 ; Subroutine to set the color of the graphic from X-Register value, before a DRAW or HPLOT, FillBackground
C_BLACK1        equ #$00
C_GREEN         equ #$01
C_VIOLET        equ #$02
C_WHITE1        equ #$03
C_BLACK2        equ #$04
C_ORANGE        equ #$05
C_BLUE          equ #$06
C_WHITE2        equ #$07

; -----------------------------------------------------------------------------
; Drawing Shape Routines
; -----------------------------------------------------------------------------
HPLOT           equ $F457 ; Subroutine to plot a pixel on the graphics screen at the cursor position, X-Register is x hi byte, Y-Register is x low byte, Accumulator is y position
HFIND           equ $F5CB
HPOSN           equ $F411 ; Subroutine to set the cursor position for the graphics, but no plot X-Register is x hi byte, Y-Register is x low byte, Accumulator is y position
HLIN            equ $F53A ; Subroutine to draw a horizontal line on the graphics screen, start from cursor position, X-Register is x hi byte, Y-Register is x low byte, Accumulator is y position
POSX            equ $E0   ; Cursor position x
POSY            equ $E2   ; Cursor position y
PTRTB           equ $E8   ; Address to pointer to the table of shapes
SCALE           equ $E7   ; Address to scale an hplot shape for DRAW, XDRAW
ROT             equ $F9   ; Address to rotate an hplot shape for DRAW, XDRAW
SHNUM           equ $F730 ; Find the shape number of the shape for DRAW, XDRAW
DRAW            equ $F601 ; Subroutine to draw a shape on the graphics screen, start from cursor position
XDRAW           equ $F65D ; Subroutine to XOR draw a shape on the graphics screen, start from cursor position

; -----------------------------------------------------------------------------
; Double Buffer for Drawing Function
; -----------------------------------------------------------------------------
BUFFER          equ $E6   ; Buffer address point to current page, #$20 for page 1, #$40 for page 2, will write to this page
PAGE1           equ #$20  ; Address to page 1
PAGE2           equ #$40  ; Address to page 2

XBYTE_TABLE		equ $80	  ; denormalized conversion table for x coordinate to byte offset on screen
XBIT_TABLE		equ $82	  ; denormalized conversion table for x coordinate to bit offset on screen

; -----------------------------------------------------------------------------
; This subroutine enables the high-resolution double buffer graphics and clears both pages.
; It sets the color to white and moves to Page 1.
; Note that you will leave the subroutine on Page 1.
; -----------------------------------------------------------------------------
EnableFullScreenHiRes       jsr HGR2       				; Clear PAGE 2
							jsr HGR        				; Clear PAGE 1
							sta FULLSCREEN  			; Set FULL SCREEN
							ldx C_WHITE1 
							jsr HCOLOR      			; Set COLOR TO WHITE
_initBufferEngine           lda PAGE2       			; Since we display page 1, we write to page 2 on initial state
							sta BUFFER
_initXMapping				lda #<XMappingByte			; get the address of the byte offseet low byte
							sta XBYTE_TABLE
							lda #<XMappingBitOffset		; get the address of the bit offset low byte
							sta XBIT_TABLE										
							rts

; -----------------------------------------------------------------------------
; This routine fills the background with the color set in the X-Register.
; Note that this function uses HPOSN, which will change the cursor position to an inaccurate value.
;
; Usage:
;   ldx #$00 ; Load desired color into X-Register
;   jsr FillBackground
; -----------------------------------------------------------------------------
FillBackground  jsr HCOLOR  ; Set color with what is in X-Register
				jsr HPOSN   ; Set the position of the cursor, need to do this before setting background, note that it will change the cursor position
				jsr BKGND   ; Set background to last color
				rts

;  -----------------------------------------------------------------------------
; This subroutine toggles the displayed graphics page and sets the buffer to write on the page not currently displayed.
; It updates the PTR_BUFFER and HiResPage variables to reflect the change, allowing the program to keep track of where sprites are drawn on a specific page.
; This ensures that the graphics buffer is correctly managed and sprites can be memorized and traced on the appropriate page.
; -----------------------------------------------------------------------------
SwitchBuffer        lda BUFFER            	; Load current page
					cmp PAGE1
					beq _switchPage2
_switchPage1        lda PAGE1             	; Since we display page 2, we write to page 1
					sta BUFFER
					sta HI_RES_PAGE2
					jmp _endSwitchBuffer
_switchPage2        lda PAGE2             	; Since we display page 1, we write to page 2
					sta BUFFER
					sta HI_RES_PAGE1
_endSwitchBuffer    rts


; ---------------------------------------------------------------
; Routine to get the byte and bit offest on screen for the X coordinate ( 0 to 279 )
; Usage:
;  ldx #23 ; load lo byte for the X coordinate into X-Register ( that would be 23 )
;  ldy #01 ; load high byte for the X coordinate into Y-Register ( that would be +256 )
;  jsr XMapping
;
; Return :
; X-Register will hold the byte offset on screen
; Accumulator will hold the bit offset on screen
; ---------------------------------------------------------------
XMapping			lda #>XMappingByte	
					sta XBYTE_TABLE+1
					lda #>XMappingBitOffset
					sta XBIT_TABLE+1

					tya							; get the high byte of the X coordinate
					cmp #$01
					bcc _continueXMapping		; if less than 1, we are done
					clc
					inc XBYTE_TABLE+1			; we need to increase the high byte address so we look after 256
					inc XBIT_TABLE+1			; we need to increase the high byte address so we look after 256

_continueXMapping	txa							; get the low byte of the X coordinate
					tay							; put it in Y-Register
					lda (XBYTE_TABLE),y			; get the byte offset on screen 
					tax							; put it in X-Register for return
					lda (XBIT_TABLE),y			; get the bit offset on screen put it in Accumulator for return
					rts




; -----------------------------------------------------------------------------
; press Key to toggle between page 1 and page 2 buffer/display
; this is a dead end routine, it will not return to the caller, only used for debugging 
; -----------------------------------------------------------------------------
DbgToggleBuffer	jsr UnblockWhenKeyPressed 	; wait for key press
				jsr SwitchBuffer 			; switch to the other page
				jmp DbgToggleBuffer 		; loop