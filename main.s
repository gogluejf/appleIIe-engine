
                org $6000 ; start of the program at this address


; text
HOME	      	equ $FC58 ; Subroutine to clear the screen when in text mode
COUT			equ	$FDED ; Subroutine to Print a character to the screen at cursor position
WAIT 			EQU $FCA8


COUNTER				equ $03

PageMemoryAddr		equ $61
W_PTR				equ $63
H_PTR				equ $64
SHIFTED				equ $65
X_PTR				equ $66 ; 2 bytes
Y_PTR				equ $68



; Shape data structure
SHAPE_BYTE_OFFSET_WIDTH			equ #$00 ; 1 bytes for shape width
SHAPE_BYTE_OFFSET_HEIGHT		equ #$01 ; 1 byte for shape height
SHAPE_OFFSET_BYTE_DATA			equ #$02 ; data start at byte 

; Sprite structure ( shape or coord )
SPRITE_STRUCT_BYTE_SIZE			equ #$06 ; 6 bytes for sprite structure

;shape struct offset
SPRITE_OFFSET_SHAPE_ADDR		equ #$00 ; 2 bytes for shape address

;sprite coord offset
SPRITE_OFFSET_BYTE_HL			equ #$00 ; 2 bytes for shape Horizontal left
SPRITE_OFFSET_BYTE_HR 			equ #$02 ; 2 bytes for shape Horizontal right
SPRITE_OFFSET_BYTE_VT 			equ #$04 ; 1 byte for shape Vertical top
SPRITE_OFFSET_BYTE_VB 			equ #$05 ; 1 byte for shape Vertical bottom

SHAPE_PTR						equ $69 ; 2 bytes point the current shape data ptr

SHAPE_BYTE_COUNTER					equ $6B		; Byte pointer for reading the shape
SPRITE_PTR							equ $6C 	; 2 bytes point the current sprite structure in SPRITE_DATA 
SPRITE_COUNTER						equ $6E 	; How many struct in the sprite table
SPRITE_TABLE						equ $6F 	; contain all address of the SPRITE_DATA
SPRITE_DATA_LOW_BYTE				equ #$00 	; storage for sprite shared structures data , low byte
SPRITE_DATA_HI_BYTE_SHAPE			equ #$A0 	; storage for sprite shape structure data , high byte, 
SPRITE_DATA_HI_BYTE_COORD_PAGE1		equ #$70	; storage for sprite coordinate structure data , high byte, keep trace when drawing on page 1
SPRITE_DATA_HI_BYTE_COORD_PAGE2		equ #$90	; storage for sprite coordinate structure data , high byte, keep trace when when drawing on page 2

HL								equ $07
HR								equ $09	
VT								equ $0B
VB								equ $0C
W								equ $0D	
H								equ $0E

MAX_SPRITE						equ #12

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

ENTRY2			clc
				jsr InitSpriteEngine
				jsr EnableFullScreenHiRes

				ldx #<SquidShape		; get the address of the shape low byte
				ldy #>SquidShape 		; get the address of the shape high byte		
				jsr InitSprite
				ldx #04
				ldy #00
				lda #20
				jsr SetSpriteCoord
				;jsr DrawShape

				ldx #<SquidShape		; get the address of the shape low byte
				ldy #>SquidShape 		; get the address of the shape high byte
				jsr InitSprite
				ldx #09
				ldy #00
				lda #12
				jsr SetSpriteCoord
				;jsr DrawShape

				ldx #<SquidShape		; get the address of the shape low byte
				ldy #>SquidShape 		; get the address of the shape high byte
				jsr InitSprite
				ldx #14
				ldy #00
				lda #44
				jsr SetSpriteCoord
				;jsr DrawShape

				ldx #<SquidShape		; get the address of the shape low byte
				ldy #>SquidShape 		; get the address of the shape high byte
				jsr InitSprite
				ldx #19
				ldy #00
				lda #84
				jsr SetSpriteCoord
				;jsr DrawShape

				ldx #<SquidShape		; get the address of the shape low byte
				ldy #>SquidShape 		; get the address of the shape high byte
				jsr InitSprite
				ldx #24
				ldy #00
				lda #104
				jsr SetSpriteCoord
				;jsr DrawShape

				ldx #<SquidShape		; get the address of the shape low byte
				ldy #>SquidShape 		; get the address of the shape high byte		
				jsr InitSprite
				ldx #29
				ldy #00
				lda #10
				jsr SetSpriteCoord				
				;jsr DrawShape

				ldx #<SquidShape		; get the address of the shape low byte
				ldy #>SquidShape 		; get the address of the shape high byte
				jsr InitSprite
				ldx #34
				ldy #00
				lda #24
				jsr SetSpriteCoord
				;jsr DrawShape
				
				jsr DrawAllShape
				
				;jsr SwitchBuffer

				jsr PlaySong
				jsr DbgToggleBuffer
				;jsr TEXT
				rts
			
; ---------------------------------------------------------------
; This routine Initialize the sprite engine, this is necessary before using the sprites
; It
; ---------------------------------------------------------------		
InitSpriteEngine	lda #$00						
					sta SPRITE_COUNTER						; Init the sprite counter at 0 sprites
					ldx MAX_SPRITE
					ldy #00
					lda SPRITE_DATA_LOW_BYTE				
_initSpriteTable	sta SPRITE_TABLE,y						; Init Sprite Table with low bytes for quick access
					iny
					adc SPRITE_STRUCT_BYTE_SIZE
					dex
					bne _initSpriteTable
					rts

; ---------------------------------------------------------------
; Find the address of the sprite number loaded in X-Register and set it in the SPRITE_PTR and other coordinate for fast access
; set the low byte, this is use prior to load shape data or coordination
; Usage:
;	ldy #$01			
;   jsr LoadSpritePtr
; ---------------------------------------------------------------
LoadSpritePtr			dey
						lda SPRITE_TABLE,y		; load the low byte, the high byte is already loaded as zero page
						sta SPRITE_PTR
						rts

; ---------------------------------------------------------------
;
; ---------------------------------------------------------------
LoadSpriteShapeData		lda SPRITE_DATA_HI_BYTE_SHAPE 		; always zero page	lda #>SPRITE_DATA
						sta SPRITE_PTR+1

_loadTablePtr			ldy SPRITE_OFFSET_SHAPE_ADDR
						lda (SPRITE_PTR),y				
						sta SHAPE_PTR
						ldy SPRITE_OFFSET_SHAPE_ADDR+1
						lda (SPRITE_PTR),y				
						sta SHAPE_PTR+1

_loadDimension			ldy SHAPE_BYTE_OFFSET_WIDTH
						lda (SHAPE_PTR),y							
						sta W
						ldy SHAPE_BYTE_OFFSET_HEIGHT
						lda (SHAPE_PTR),y							
						sta H
						rts

; ---------------------------------------------------------------
;
; ---------------------------------------------------------------
SaveSpriteShapeData		lda SPRITE_DATA_HI_BYTE_SHAPE 		; always zero page	lda #>SPRITE_DATA
						sta SPRITE_PTR+1

						lda SHAPE_PTR
						ldy SPRITE_OFFSET_SHAPE_ADDR
						sta (SPRITE_PTR),y				; store the high byte of the shape address

						lda SHAPE_PTR+1
						ldy SPRITE_OFFSET_SHAPE_ADDR+1
						sta (SPRITE_PTR),y				; store the low byte of the shape address
						
						jsr _loadDimension				; load the dimension of the shape to convenience ( so we have W and H set )

						rts


; ---------------------------------------------------------------
;
; ---------------------------------------------------------------
LoadSpriteCoordDataPage1	lda SPRITE_DATA_HI_BYTE_COORD_PAGE1 	; keep trace of last movement draw on page 2
							sta SPRITE_PTR+1
							jmp _loadHorizontal

; ---------------------------------------------------------------
;
; ---------------------------------------------------------------
LoadSpriteCoordDataPage2	lda SPRITE_DATA_HI_BYTE_COORD_PAGE2 	; keep trace of last movement draw on page 2
							sta SPRITE_PTR+1

_loadHorizontal		ldy SPRITE_OFFSET_BYTE_HL
					lda (SPRITE_PTR),y 	
					sta HL
					ldy SPRITE_OFFSET_BYTE_HR
					lda (SPRITE_PTR),y 	
					sta HR

_loadVertical		ldy SPRITE_OFFSET_BYTE_VT
					lda (SPRITE_PTR),y 	
					sta VT
					ldy SPRITE_OFFSET_BYTE_VB
					lda (SPRITE_PTR),y 	
					sta VB

					rts

; ---------------------------------------------------------------
;
; ---------------------------------------------------------------
SaveSpriteCoordDataPage1	lda SPRITE_DATA_HI_BYTE_COORD_PAGE1 	; keep trace of last movement draw on page 2
							sta SPRITE_PTR+1
							jmp _saveHorizontal


SaveSpriteCoordDataPage2	lda SPRITE_DATA_HI_BYTE_COORD_PAGE2 	; keep trace of last movement draw on page 2
							sta SPRITE_PTR+1


_saveHorizontal		ldy SPRITE_OFFSET_BYTE_HL
					lda HL
					sta (SPRITE_PTR),y 	
					ldy SPRITE_OFFSET_BYTE_HR
					lda HR
					sta (SPRITE_PTR),y 	

_saveVertical		ldy SPRITE_OFFSET_BYTE_VT
					lda VT
					sta (SPRITE_PTR),y 	
					ldy SPRITE_OFFSET_BYTE_VB
					lda VB
					sta (SPRITE_PTR),y 	

					rts

; ---------------------------------------------------------------
; This routine Set the sprite coordinate in the sprite coord data structure usinx X-Register, Y-Register for X coordinate and Aaccumulator for Y coordinate 
; the data is save to the current page we are writing on
; be sure to load LoadSpritePtr and LoadSpriteShapeData prior to call that routine ( InitSprite will also do the job )
; Usage:
;	ldx #$01 		; 0-39 x coordinate low byte 0-39 for now
;	ldy #$02		; x coordinate high byte  not used for now
;	lda #00 		; y coordinate 0-191 	
; ---------------------------------------------------------------
SetSpriteCoord		sta VT				; set the  verticla top of the sprite	 with the y coordinate ( accumulator )	
					adc H
					sta VB				; offset with height for the bottom vertical position

					txa 				; set the horizontal left the sprite with the x coordinate with transfer to the accumulator
					sta HL
					adc W				; offset with width for the right horizontal right positon
					sta HR				
					
					jsr SaveSpriteCoordDataPage1
					rts

; ---------------------------------------------------------------
; This routine Initialize a sprite in the sprite structure
; the address to get the data for the sprite is pass by the X-Register for the low byte and X-Register for the high byte 
; The SPRITE_COUNTER will be increase reflecting the number of sprite in the sprite table
; The SPRITE_PTR will be set to the current sprite initialized structure in the sprite table
; This function will not set coordinate, so you need to call SetSpriteCoord after this function
; Usage:
;   ldy #<SquidShape		; get the address of the shape low byte
;	ldx #>SquidShape 		; get the address of the shape high byte
;   jsr InitSprite
; ---------------------------------------------------------------
InitSprite			stx SHAPE_PTR
					sty SHAPE_PTR+1

					inc SPRITE_COUNTER
					ldy SPRITE_COUNTER
					jsr LoadSpritePtr
					jsr SaveSpriteShapeData

					rts


; ---------------------------------------------------------------
; This routine Draw all the sprite in the sprite table to the curret buffer page
; ---------------------------------------------------------------
DrawAllShape		ldy SPRITE_COUNTER
					sty COUNTER
_drawAllShape		ldy COUNTER
					jsr LoadSpritePtr
					jsr LoadSpriteShapeData
					jsr LoadSpriteCoordDataPage1
					jsr XDrawShape
					
					lda VB
					cmp #191
					bcs _reset

					inc VB
					inc VT

					jmp _drawAllContinue

_reset				lda H
					sta VB	
					lda #00
					sta VT
					jsr SoundMachineGun

_drawAllContinue	clc
					jsr SaveSpriteCoordDataPage1

					jsr DrawShape
					dec COUNTER
					bne _drawAllShape
					jmp DrawAllShape ; temps
					rts



; ---------------------------------------------------------------
; This routine Draw the shape of the sprite in the current buffer page
; the routine read data in SPRITE_PTR Structure and SHAPE_PTR and draw using the HL,HR,VT,VB coordinates
; ---------------------------------------------------------------
DrawShape			lda H						
					sta H_PTR
					lda VB								
					sta Y_PTR								
					lda SHAPE_OFFSET_BYTE_DATA 				
					sta SHAPE_BYTE_COUNTER

_loopDrawShapeH		lda W
					sta W_PTR

					lda HR					
					sta X_PTR
					
					jsr SetMemoryMapAddr

_loopDrawShapeW		lda #00
					sta SHIFTED
					
					lda #$02						; bit shifted				
					cmp #$01
					tax

					ldy SHAPE_BYTE_COUNTER
					lda (SHAPE_PTR),y
					inc SHAPE_BYTE_COUNTER
					
					ldy #$00
					bcc _contDrawShape

					clc
_shiftDrawRight		rol
					rol SHIFTED
					dex 
					bne _shiftDrawRight

					rol								; push the bit 8 so it is shifted
					rol SHIFTED
					ror								; rolll back the bit 8 to 0

					tax
					lda (PageMemoryAddr),y
					ora SHIFTED
					sta (PageMemoryAddr),y
					txa

_contDrawShape		clc
					dec PageMemoryAddr
					sta (PageMemoryAddr),y		
					dec W_PTR
					bne _loopDrawShapeW
					dec Y_PTR
					dec H_PTR
					bne _loopDrawShapeH
					rts

; ---------------------------------------------------------------
; 
; ---------------------------------------------------------------
XDrawShape			lda H						
					sta H_PTR
					lda VB								
					sta Y_PTR								
					lda SHAPE_OFFSET_BYTE_DATA 				
					sta SHAPE_BYTE_COUNTER

_loopXDrawShapeH	lda W
					sta W_PTR

					lda HR					
					sta X_PTR
					
					jsr SetMemoryMapAddr

_loopXDrawShapeW	lda #00
					sta SHIFTED
					
					lda #$02						; bit shifted				
					cmp #$01
					tax

					ldy SHAPE_BYTE_COUNTER
					lda (SHAPE_PTR),y
					inc SHAPE_BYTE_COUNTER
					
					ldy #$00
					bcc _contXDrawShape

					clc
_shiftXDrawRight	rol
					rol SHIFTED
					dex 
					bne _shiftXDrawRight

					rol								; push the bit 8 so it is shifted
					rol SHIFTED
					ror								; rolll back the bit 8 to 0

					tax
					lda (PageMemoryAddr),y
					EOR SHIFTED
					sta (PageMemoryAddr),y
					txa

_contXDrawShape		clc
					dec PageMemoryAddr
					EOR (PageMemoryAddr),y
					sta (PageMemoryAddr),y		
					dec W_PTR
					bne _loopXDrawShapeW
					dec Y_PTR
					dec H_PTR
					bne _loopXDrawShapeH
					rts



; ---------------------------------------------------------------
; 
; ---------------------------------------------------------------
SetMemoryMapAddr	ldy Y_PTR
					lda DataMemLowByte,y				; load the y coordinate low byt
					adc X_PTR
					sta PageMemoryAddr
					lda BUFFER
					cmp PAGE1
					bne _memoryPage2
_memoryPage1		clc
					lda DataMemHighBytePage1,y
					sta PageMemoryAddr+1
					rts
_memoryPage2		clc
					lda DataMemHighBytePage2,y			
					sta PageMemoryAddr+1
					rts



PlaySong		ldy #$00 
				lda SquidThemeSong,y ; 
				tax ; firs byte,  set number of notes to play
_playNote		iny
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
				bne _playNote
				jmp PlaySong
				rts


					
			











MAIN			JSR SET
				jsr SwitchBuffer
				JSR DSPLY
				jsr SwitchBuffer
				JSR DSPLY
				JSR ANIMATE
				rts

ANIMATE			jsr SwitchBuffer
				jsr REMOVE
            	jsr DSPLY
            	; jsr UnblockWhenButtonDown
				dec X_PTR
				; dec ROT
        	    JMP ANIMATE
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
				sta X_PTR
				lda #$00 ; X = 139
				sta X_PTR+1
				lda #$4F ; Y = 79
				sta Y_PTR
				rts


DSPLY 		LDA X_PTR
			sta (PTR_BUFFER)
			tax ; X = 139, low
			LDA X_PTR+1 
			ldy #$01
			sta (PTR_BUFFER),y
			tay ; X = 139, high
			phy
			ldy #$02
			LDA Y_PTR ; Y = 79
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







; Shape of SquidShape width = 2, height = 24
; Structure: [width byte] [height byte] [shape_data...]
SquidShape hex 02181000204C4112491165486548244C34641F7C0F780360000003600C18300642214221400148012602260210040C180360

; Shape of PapaSquidShape width = 4, height = 48
; Structure: [width byte] [height] [shape_data...]
PapaSquidShape hex 0430060000000E0000001C006170180061786003461C6003060E614306077143460378736140783361407833614078336160383161701C3071701E3078301E387C300F7F7F70077F7F70037F7F60017F7F40001F7C00000F78000000000000000000000F7800000F780001700740017007401E00003C1E00003C600C1803600C1803600C1803600C180360000003600000036140000361400003183C000C183C000C183C000C1C3C001C0E000038070000700370076001700740000F7800000F7800


; data memory for hires graphics page 1 and 2 ofr y coordinate quick access
DataMemHighBytePage1 hex 2024282C3034383C2024282C3034383C2125292D3135393D2125292D3135393D22262A2E32363A3E22262A2E32363A3E23272B2F33373B3F23272B2F33373B3F2024282C3034383C2024282C3034383C2125292D3135393D2125292D3135393D22262A2E32363A3E22262A2E32363A3E23272B2F33373B3F23272B2F33373B3F2024282C3034383C2024282C3034383C2125292D3135393D2125292D3135393D22262A2E32363A3E22262A2E32363A3E23272B2F33373B3F23272B2F33373B3F
DataMemHighBytePage2 hex 4044484C5054585C4044484C5054585C4145494D5155595D4145494D5155595D42464A4E52565A5E42464A4E52565A5E43474B4F53575B5F43474B4F53575B5F4044484C5054585C4044484C5054585C4145494D5155595D4145494D5155595D42464A4E52565A5E42464A4E52565A5E43474B4F53575B5F43474B4F53575B5F4044484C5054585C4044484C5054585C4145494D5155595D4145494D5155595D42464A4E52565A5E42464A4E52565A5E43474B4F53575B5F43474B4F53575B5F
DataMemLowByte hex 000000000000000080808080808080800000000000000000808080808080808000000000000000008080808080808080000000000000000080808080808080802828282828282828A8A8A8A8A8A8A8A82828282828282828A8A8A8A8A8A8A8A82828282828282828A8A8A8A8A8A8A8A82828282828282828A8A8A8A8A8A8A8A85050505050505050D0D0D0D0D0D0D0D05050505050505050D0D0D0D0D0D0D0D05050505050505050D0D0D0D0D0D0D0D05050505050505050D0D0D0D0D0D0D0D0



; this is a track of 64 Notes, at 240 bpm ; melancoly
SquidThemeSong hex 4064726466646064C064726466646064C064806466646064C064806466646064C064726466646064AC647264666460649A64726466644C649A648064666455649A6440643864326480644064386432642F643864406438649A64666460645564406448644C6455644C645564666460644C64556466646064556480646664606466
; this is a track of 39 Notes, at 240 bpm ; punk short
SquidTheme2Song hex 2732AC320064AC32004BAC190032C064AC64C064E764C096AC649A64923280969232E732AC32803292329A64729655644C3248644C647264806492969A647264AC32809692329A3292329A32AC32C0
; this is a track of 123 Notes, at 240 bpm ; punk long
SquidTheme3Song hex 7B32AC320064AC320064AC320032C0320032C0320032AC3200329A32003292320096923200329232003280320032803200329A320032C0320032AC3200C8AC640032C0320064C064AC649A32923200329232003292320032923200327232003272320032923200329A32C032AC3200C8AC6400649264C064E764C032AC6400649A329232003280C892C88032723200967264AC3200649264C064E764C096AC969A649264726480649264C032AC320064AC320064AC3200649264C064E764C064AC3200329A320064923200FA9232803292329A64729655644C3248644C647264806492969A647264AC32809692329A3292329A32AC32C0
