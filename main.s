
                org $6000 ; start of the program at this address
				; #INCLUDE "init.asm"
        		; #INCLUDE "logic.asm"
        		; #INCLUDE "graphics.asm"


; text
HOME	      	equ $FC58 ; Clear the screen when in text mode
COUT			equ	$FDED ; Print a character to the screen at cursor position
KYBD			equ $C000 ; Read the last key pressed
STROBE			equ $C010 ; Clear the last key pressed, sta to clear

; Graph
GR              equ $C050 ; Graphics mode, in low resolution
TEXT            equ $C051 ; Switch back to text mode
FullScreen      equ $C052 ; Full screen, no text line at bottom
ScreenWithText  equ $C053 ; Screen with text 3 lines at bottom
LoRes           equ $C056 ; Low resolution graphics mode
HiRes           equ $C057 ; Set to high resolution graphics mode, no screen clear
HiResPage1      equ $C054 ; Switch to hi res page 1, no clear screen
HiResPage2      equ $C055 ; Switch to hi res page 2, no clear screen
HCLR            equ $F3F2 ; Clears current screen to black
BKGND           equ $F3F6 ; Clears current screen to last plotted HCOLOR
HGR             equ $F3E2 ; HiRes graphics mode subroutine, clear page 1
HGR2            equ $F3D8 ; HiRes graphics mode subroutine, clear page 2


PREAD 			EQU $FB1E ; 
WAIT 			EQU $FCA8
PB0 			EQU $C061 ; Read the button press from the joystick
HCOLOR 			EQU $F6F0 ; Set the color of the graphics, before a DRAW or HPLOT
HPLOT 			EQU $F457 ; Plot a pixel on the graphics screen at the cursor position, x register is x hi byte, y is x low byte, accumulator is y position
HFIND 			EQU $F5CB ;
HPOSN 			EQU $F411 ; Set the cursor position for the graphics, but no plot x register is x hi byte, y is x low byte, accumulator is y position
HLIN 			EQU $F53A ; Draw a horizontal line on the graphics screen, start from cursor position, x register is x hi byte, y is x low byte, accumulator is y position
;X 				EQU $E0 ; Cursor position x
;Y 				EQU $E2 ; Cursor position y
BUFFER			EQU $E6 ; Buffer point to current page, #20 for page 1, #40 for page 2
PTRTB 			EQU $E8 ; Pointer to the table of shapes
SCALE 			EQU $E7 ; Scale an hplot shape for DRAW, XDRAw
ROT 			EQU $F9 ; rotate an hplot shape for DRAW, XDRAW

SHNUM 			EQU $F730 ; Find the shape number of the shape fox DRAW, XDRAW
DRAW 			EQU $F601 ; Draw a shape on the graphics screen, start from cursor position
XDRAW 			EQU $F65D ; XOR draw a shape on the graphics screen, start from cursor position


tmp				equ $04
Duration		equ $05 
Pitch			equ $06
PTRX			equ $08 ; 2 bytes
PTRY			equ $0A
Speaker			equ $C030


CURRENT_PAGE	equ $11 
PTR_BUFFER		equ $80

PageMemoryAddr	equ $81
width			equ $83
height			equ $84

ENTRY 			JMP E2
TABLE 			HEX 010004
				HEX 00123F
				HEX 20642D
				HEX 15361E
				HEX 0700
; SHAPE   		HEX 3C 42 81 81 42 3C ; A 6x6 bitmap representing a circle

E2				
				; jmp SkipGR
EnableGraph		sta GR
				JSR HGR2 					
				sta HiRes		
				JSR HGR ; CLR SCRN
				sta FullScreen	
SkipGR			LDX #$03 ; WHITE = 3
				JSR HCOLOR
		


Init			lda #24 ; height	
				sta height
				lsr A ; divide 2, center
				adc #$4f ; Y =  ; add to y ( 79 )
				sta PTRY
				ldy #$00 ;  shape byte counter
LoopShapeH		lda #02 ; width	
				sta width
				;asl A
				;asl A ; divide 2, center, but multiple 8 to get pixel
				adc #$13	;#$8b ;   ; add to x ( 139 )
				sta PTRX 
				lda #$00 
				sta PTRX+1
LoopShapeW		tya
				pha	
				jsr SetMemoryMapAddr
				pla
				tay
				lda SquidShape,y
				tax
				tya
				pha
				ldy #$00
				txa
				sta (PageMemoryAddr),y
				pla 
				tay
				iny ;increase shape byte counte
				dec PTRX
				dec width
				bne LoopShapeW
				dec PTRY
				dec height
				bne LoopShapeH


Init2			lda #48 ; height	
				sta height
				lsr A ; divide 2, center
				adc #$18 ; Y =  ; add to y ( 96 )
				sta PTRY
				ldy #$00 ;  shape byte counter
LoopShapeH2		lda #04 ; width	
				sta width
				;asl A
				;asl A ; divide 2, center, but multiple 8 to get pixel
				adc #$2	;#$8b ;   ; add to x ( 139 )
				sta PTRX 
				lda #$00 
				sta PTRX+1
LoopShapeW2		tya
				pha	
				jsr SetMemoryMapAddr
				pla
				tay
				lda PapaSquidShape,y
				tax
				tya
				pha
				ldy #$00
				txa
				sta (PageMemoryAddr),y
				pla 
				tay
				iny ;increase shape byte counte
				dec PTRX
				dec width
				bne LoopShapeW2
				dec PTRY
				dec height
				bne LoopShapeH2

				; jsr TestSounds
				; jsr BeatBeep
				; jsr ShapeSoundEffect

PlaySong		ldy #$00 
				lda SquidThemeSong,y ; 
				tax ; firs byte,  set number of notes to play
PlayNote		iny
				lda SquidThemeSong,y
				sta Duration
				iny
				lda SquidThemeSong,y
				sta Pitch
				tya
				pha
				txa
				pha
				jsr PlayTone
				pla
				tax
				pla
				tay
				dex
				bne PlayNote
				jmp PlaySong
				rts

; testin pulse beat
BeatBeep		ldx #$ff
				stx Duration
				ldy #$FF
				sty Pitch
				jsr PlayTone
				ldx #$ff
				stx Duration
				ldy #$00
				sty Pitch
				jsr PlayTone
				jsr BeatBeep
		
TestSounds		jsr KLOOP
				jsr SoundMotor
				jsr KLOOP
				jsr SoundReward
				jsr KLOOP
				jsr SoundIce
				jsr KLOOP
				jsr SoundAlarm
				jsr KLOOP
				jsr SoundShoot
				jsr KLOOP
				jsr SoundBubbleUp
				jsr KLOOP				
				jsr SoundFalling
				jsr KLOOP
				jsr SoundSquare
				jsr KLOOP				
				jsr SoundMachineGun
				jsr KLOOP				
				jsr SoundLaser
				rts
					
ShapeSoundEffect	jsr KLOOP
					ldx #$ff ; duration
					ldy #$FF ; Pitch
					lda #$08 ; Modulation
					jsr SoundCresendo
					jmp ShapeSoundEffect
					rts					

SoundMotor		lda #40
SoundMotorLoop	ldx #$04
				stx Duration
				ldy #$FF
				sty Pitch
				pha
				jsr PlayTone
				pla
				ldx #$04
				stx Duration
				ldy #$00
				sty Pitch
				pha
				jsr PlayTone
				pla
				dec
				bne SoundMotorLoop
				rts

SoundReward		ldx #40
				stx Duration
				ldy #255
				sty Pitch
				jsr PlayTone
				ldx #40
				stx Duration
				ldy #128
				sty Pitch
				jsr PlayTone
				ldx #40
				stx Duration
				ldy #64
				sty Pitch
				jsr PlayTone
				ldx #40
				stx Duration
				ldy #31
				sty Pitch
				jsr PlayTone
				ldx #40
				stx Duration
				ldy #15
				sty Pitch
				jsr PlayTone
				rts

SoundIce			ldx #$ff ; duration
					ldy #$18 ; Pitch
					lda #$02 ; Modulation
					jsr SoundCresendo
					rts
SoundAlarm			jsr SoundBubbleUp
					jsr SoundBubbleUp
					jsr SoundBubbleUp
					jsr SoundBubbleUp
					jsr SoundBubbleUp
					jsr SoundBubbleUp
					jsr SoundBubbleUp
					jsr SoundBubbleUp
					rts
SoundShoot			ldx #$01 ; duration
					ldy #$00 ; Pitch
					lda #$01 ; Modulation
					jsr SoundDecresendo
					rts
SoundBubbleUp		ldx #$01 ; duration
					ldy #$ff ; Pitch
					lda #$01 ; mdoulation
					jsr SoundCresendo
					rts
SoundFalling		ldx #$40 ; duration
					ldy #136 ; Pitch
					lda #$0F ; mdoulation
					jsr SoundDecresendo
					rts
SoundSquare			ldx #$FF ; duration
					ldy #135 ; Pitch
					lda #$0F ; modulation
					jsr SoundCresendo
					rts
SoundMachineGun		ldx #$02 ; duration
					ldy #$00 ; Pitch
					lda #$04 ; mdoulation
					jsr SoundDecresendo
					ldx #$02 ; duration
					ldy #$00 ; Pitch
					lda #$04 ; mdoulation
					jsr SoundDecresendo
					ldx #$02 ; duration
					ldy #$00 ; Pitch
					lda #$04 ; mdoulation
					jsr SoundDecresendo
					rts
SoundLaser			ldx #$02 ; duration
					ldy #$00 ; Pitch
					lda #$01 ; mdoulation
					jsr SoundDecresendo			
					rts

; play a sound decresing the pitch tone base on a modulation of pitch at each duration
; x register is the duration, y register is the pitch, a register is the modulation
SoundDecresendo		stx Duration
					sta tmp
					tya
SoundDeresendoLoop	sta Pitch
					jsr PlaySound
					clc
					adc tmp
					bne SoundDeresendoLoop
					rts

; play a sound increasing the pitch tone base on a modulation of pitch at each duration
; x register is the duration, y register is the pitch, a register is the modulation
SoundCresendo		stx Duration
					sta tmp
					tya
SoundCresendoLoop	sta Pitch
					jsr PlaySound
					sec
					sbc tmp
					bne SoundCresendoLoop
					rts

; play tone for a precise duration, good for music
PlayTone		ldx Pitch
				bne SpeakerTone ; if not zero, if have a ptich, otherwize rest

RestTone		nop
				nop
				dey ; no value set,  as far as it is loop every 255 cycles
				bne RestTone
				dec Duration
				bne RestTone
				jmp EndPlayTone

SpeakerTone		sta Speaker
DecDuration		dey ; no value set,  as far as it is loop every 255 cycles
				bne DecPitch
				dec Duration
				beq EndPlayTone
DecPitch		dex
				bne DecDuration
				ldx Pitch
				jmp SpeakerTone
EndPlayTone		rts

; play sound, but duration is dynamic to tone, good for effects
PlaySound		ldx Duration
LoopSound		ldy Pitch
				sta Speaker
LoopPitch		dey				
				bne LoopPitch
				dex
				bne LoopSound
				rts

; press button to toggle buffer, 
ToggleBuffer	jsr BLOOP
				jsr SWITCHBUFFER
				jmp ToggleBuffer

; quick access
SetMemoryMapAddr	ldy PTRY
					lda DataMemHighByte,y
					sta PageMemoryAddr+1
					lda DataMemLowByte,y
					adc PTRX ;x is per byte for now
					sta PageMemoryAddr
					rts

DrawAtMemoryPos	lda #$FF ; time to draw the pixels
				sta (PageMemoryAddr)
				rts



MAIN			JSR SET
				jsr SWITCHBUFFER
				JSR DSPLY
				jsr SWITCHBUFFER
				JSR DSPLY
				JSR ANIMATE
				rts

SET 			LDA #$03
				STA PTRTB
				LDA #$60
				STA PTRTB+1 ; SET TABLE TO $6003
				LDA #$04 ; scale by 4
				STA SCALE
				LDA #$01 ; rot by 4
				STA ROT
				lda #00
				sta PTR_BUFFER+1
	
SetPageCursor	lda #$00
				sta CURRENT_PAGE

SetXY			lda #$8F ;   
				sta PTRX
				lda #$00 ; X = 139
				sta PTRX+1
				lda #$4F ; Y = 79
				sta PTRY
				rts

ANIMATE		jsr SWITCHBUFFER
			jsr REMOVE
            jsr DSPLY
            ; jsr BLOOP
			dec PTRX
			; dec ROT
            JMP ANIMATE
            rts

DSPLY 		LDA PTRX
			sta (PTR_BUFFER)
			tax ; X = 139, low
			LDA PTRX+1 
			ldy #$01
			sta (PTR_BUFFER),y
			tay ; X = 139, high
			phy
			ldy #$02
			LDA PTRY ; Y = 79
			sta (PTR_BUFFER),y
			ply
			JSR HPOSN
			LDX #$01 ; SHAPE #1
			JSR SHNUM ; FIND SHP ADDR
			ldy #$03
			LDA ROT
			sta (PTR_BUFFER),y
			JSR DRAW+4 ; USE SHNUM ENTRY PT
			rts		

REMOVE		LDA (PTR_BUFFER) ; X = 139, lo
			TAX
			ldy #$01
			LDA (PTR_BUFFER),y ; X = 139, high
			TAY
			phy
			ldy #$02
			LDA (PTR_BUFFER),y ; Y = 79
			ply
			JSR HPOSN
			LDX #$01 ; SHAPE #1
			JSR SHNUM ; FIND SHP ADDR
			ldy #$03
			LDA (PTR_BUFFER),y
			JSR XDRAW+4
			rts

SWITCHBUFFER		LDA CURRENT_PAGE  ; Load current page
       				EOR #$01          ; Toggle between 0 and 1
        			STA CURRENT_PAGE  ; Save toggled page
					CMP #$00
					beq SwitchPage2
SwitchPage1			lda #$20 ; page1
					sta BUFFER
					lda #$82
					sta PTR_BUFFER
					sta HiResPage2
					jmp EndSwitch
SwitchPage2			lda #$40 ; page2
					sta BUFFER
					lda #$92
					sta PTR_BUFFER
					sta HiResPage1
EndSwitch			rts


; block until button press
BLOOP		lda PB0 ; button pressed
			BPL BLOOP
			rts	
; block until keypress
KLOOP		lda KYBD	; load last pressed key to accumulator
			cmp #$80
			bcc KLOOP
			sta STROBE ; clear last keyboard
			rts

; this is a track of 123 Notes, at 240 bpm ; punk long
SquidTheme3Song hex 7B32AC320064AC320064AC320032C0320032C0320032AC3200329A32003292320096923200329232003280320032803200329A320032C0320032AC3200C8AC640032C0320064C064AC649A32923200329232003292320032923200327232003272320032923200329A32C032AC3200C8AC6400649264C064E764C032AC6400649A329232003280C892C88032723200967264AC3200649264C064E764C096AC969A649264726480649264C032AC320064AC320064AC3200649264C064E764C064AC3200329A320064923200FA9232803292329A64729655644C3248644C647264806492969A647264AC32809692329A3292329A32AC32C0
; this is a track of 64 Notes, at 240 bpm ; melancoly
SquidTheme2Song hex 4064726466646064C064726466646064C064806466646064C064806466646064C064726466646064AC647264666460649A64726466644C649A648064666455649A6440643864326480644064386432642F643864406438649A64666460645564406448644C6455644C645564666460644C64556466646064556480646664606466
; this is a track of 39 Notes, at 240 bpm ; punk short
SquidThemeSong hex 2732AC320064AC32004BAC190032C064AC64C064E764C096AC649A64923280969232E732AC32803292329A64729655644C3248644C647264806492969A647264AC32809692329A3292329A32AC32C0

; Shape of SquidShape width = 2, height = 24
SquidShape hex 1000204C4112491165486548244C34641F7C0F780360000003600C18300642214221400148012602260210040C180360
; Shape of PapaSquid2Shape width = 4, height = 48
PapaSquidShape hex 060000000E0000001C006170180061786003461C6003060E614306077143460378736140783361407833614078336160383161701C3071701E3078301E387C300F7F7F70077F7F70037F7F60017F7F40001F7C00000F78000000000000000000000F7800000F780001700740017007401E00003C1E00003C600C1803600C1803600C1803600C180360000003600000036140000361400003183C000C183C000C183C000C1C3C001C0E000038070000700370076001700740000F7800000F7800


; data memory for high byte address for hi res graphics page 1  ofr y coordinate quick access
DataMemHighByte hex 2024282C3034383C2024282C3034383C2125292D3135393D2125292D3135393D22262A2E32363A3E22262A2E32363A3E23272B2F33373B3F23272B2F33373B3F2024282C3034383C2024282C3034383C2125292D3135393D2125292D3135393D22262A2E32363A3E22262A2E32363A3E23272B2F33373B3F23272B2F33373B3F2024282C3034383C2024282C3034383C2125292D3135393D2125292D3135393D22262A2E32363A3E22262A2E32363A3E23272B2F33373B3F23272B2F33373B3F
; data memory for low byte address for hi res graphics page 1 and 2 ofr y coordinate quick access
DataMemLowByte hex 000000000000000080808080808080800000000000000000808080808080808000000000000000008080808080808080000000000000000080808080808080802828282828282828A8A8A8A8A8A8A8A82828282828282828A8A8A8A8A8A8A8A82828282828282828A8A8A8A8A8A8A8A82828282828282828A8A8A8A8A8A8A8A85050505050505050D0D0D0D0D0D0D0D05050505050505050D0D0D0D0D0D0D0D05050505050505050D0D0D0D0D0D0D0D05050505050505050D0D0D0D0D0D0D0D0

