
                org $6000 ; start of the program at this address


; text
HOME	      	equ $FC58 ; Subroutine to clear the screen when in text mode
COUT			equ	$FDED ; Subroutine to Print a character to the screen at cursor position
WAIT 			EQU $FCA8


PageMemoryAddr	equ $81
width			equ $83
height			equ $84
PTRX			equ $85 ; 2 bytes
PTRY			equ $87


ENTRY 			JMP ENTRY2
TABLE 			HEX 010004
				HEX 00123F
				HEX 20642D
				HEX 15361E
				HEX 0700

				USE graph.engine.s
				USE sound.engine.s
				USE sound.library.s
				USE controller.engine.s	

ENTRY2			jsr EnableFullScreenHiRes


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


				jsr DbgTestSounds

				; jsr TestSounds
				; jsr BeatBeep
				; jsr ShapeSoundEffect

PlaySong		ldy #$00 
				lda SquidThemeSong,y ; 
				tax ; firs byte,  set number of notes to play
PlayNote		iny
				lda SquidThemeSong,y
				sta DURATION
				iny
				lda SquidThemeSong,y
				sta PITCH
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


					
			





; quick access
SetMemoryMapAddr	ldy PTRY
					lda DataMemHighByte,y
					sta PageMemoryAddr+1
					lda DataMemLowByte,y
					adc PTRX ;x is per byte for now
					sta PageMemoryAddr
					rts

DrawAtMemoryPos		lda #$FF ; time to draw the pixels
					ldy #$00
					sta (PageMemoryAddr), y
					rts






MAIN			JSR SET
				jsr SwitchBuffer
				JSR DSPLY
				jsr SwitchBuffer
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
	


SetXY			lda #$8F ;   
				sta PTRX
				lda #$00 ; X = 139
				sta PTRX+1
				lda #$4F ; Y = 79
				sta PTRY
				rts

ANIMATE		jsr SwitchBuffer
			jsr REMOVE
            jsr DSPLY
            ; jsr UnblockWhenButtonDown
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

