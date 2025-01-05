
                org $6000 ; start of the program at this address


; text
HOME	      	equ $FC58 ; Subroutine to clear the screen when in text mode
COUT			equ	$FDED ; Subroutine to Print a character to the screen at cursor position
WAIT 			EQU $FCA8

TMP					equ $00 ; 2 bytes tmp
COUNTER				equ $02


PageMemoryAddr		equ $61
W_PTR				equ $63
H_PTR				equ $64
SHIFTED				equ $65
X_PTR				equ $66 ; 2 bytes
Y_PTR				equ $68
XBIT_PTR			equ $69


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

SHAPE_PTR							equ $6A ; 2 bytes point the current shape data ptr

SHAPE_BYTE_COUNTER					equ $6C		; Byte pointer for reading the shape
SPRITE_PTR							equ $6D 	; 2 bytes point the current sprite structure in SPRITE_DATA 
SPRITE_COUNTER						equ $6F 	; How many struct in the sprite table
SPRITE_TABLE						equ $70 	; contain all address of the SPRITE_DATA
MAX_SPRITE							equ #12		; max sprite in the sprite table
SPRITE_DATA_LOW_BYTE				equ #$00 	; storage for sprite shared structures data , low byte
SPRITE_DATA_HI_BYTE_SHAPE			equ #$A0 	; storage for sprite shape structure data , high byte, 
SPRITE_DATA_HI_BYTE_COORD_PAGE1		equ #$90	; storage for sprite coordinate structure data , high byte, keep trace when drawing on page 1
SPRITE_DATA_HI_BYTE_COORD_PAGE2		equ #$91	; storage for sprite coordinate structure data , high byte, keep trace when when drawing on page 2

MAGIC_BYTE							equ #$FF	; magic byte for tracing the remove need, if HL is 255, then we assume that the sprite has no position on that page, so there is not need to remove it

; load the sprite data we manipulate in the sprite engine for quick access to properties
HL								equ $07		; horizontal left, 2 bytes
HR								equ $09		; horizontal right, 2 bytes
VT								equ $0B		; vertical top
VB								equ $0C		; vertical bottom
W								equ $0D		; width in byte ( 7 bits per byte ), max with is 40 ( 7*40 = 280, the screen resolution )
H								equ $0E		; height ( pixels height  ), max height is 191 ( 0-191, 192 is the screen resolution )


ENTRY 			JMP ENTRY2

				USE graph/graph.engine.data.s
				USE graph/graph.engine.s
				USE sound/sound.engine.s
				USE sound/sound.library.s
				USE controller.engine.s	



ENTRY2			clc

				jsr InitSpriteEngine
				jsr EnableFullScreenHiRes

				ldx #<SquidShape		; get the address of the shape low byte
				ldy #>SquidShape 		; get the address of the shape high byte		
				jsr InitSprite
				ldx #28
				ldy #00
				lda #20
				jsr SetSpriteCoord

				ldx #<SnakeShape		; get the address of the shape low byte
				ldy #>SnakeShape 		; get the address of the shape high byte
				jsr InitSprite
				ldx #56
				ldy #00
				lda #12
				jsr SetSpriteCoord
				
				ldx #<SquidShape		; get the address of the shape low byte
				ldy #>SquidShape 		; get the address of the shape high byte
				jsr InitSprite
				ldx #98
				ldy #00
				lda #44
				jsr SetSpriteCoord
			
				ldx #<SquidShape		; get the address of the shape low byte
				ldy #>SquidShape 		; get the address of the shape high byte
				jsr InitSprite
				ldx #126
				ldy #00
				lda #84
				jsr SetSpriteCoord
				
				ldx #<SquidShape		; get the address of the shape low byte
				ldy #>SquidShape 		; get the address of the shape high byte
				jsr InitSprite
				ldx #168
				ldy #00
				lda #104
				jsr SetSpriteCoord
				
				ldx #<SnakeShape		; get the address of the shape low byte
				ldy #>SnakeShape 		; get the address of the shape high byte		
				jsr InitSprite
				ldx #196
				ldy #00
				lda #10
				jsr SetSpriteCoord				
				
				ldx #<SnakeShape		; get the address of the shape low byte
				ldy #>SnakeShape 		; get the address of the shape high byte
				jsr InitSprite
				ldx #238
				ldy #00
				lda #24
				jsr SetSpriteCoord

				jsr Debug
				jsr DbgToggleBuffer

				
				jsr DrawAllShape

				jsr PlaySong
				jsr DbgToggleBuffer

				rts
			
; ---------------------------------------------------------------
; This routine is used to switch back to text and brk so it is quicker to debug
; ---------------------------------------------------------------
Debug			sta TEXT
				brk
				
; ---------------------------------------------------------------
; This routine Initialize the sprite engine, this is necessary before using the sprites
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
; Load shape address in SHAPE_PTR and W and H from the sprite data loaded
; this require to LoadSpritePtr prior to call that routine
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
; Save the shape data in the sprite data structure at location reserve for that
; this reuire to LoadSpritePtr prior to call that routine and having SHAPE_PTR set with the address of the shape data to save for that sprite
; this function also load W and H witht the shape width and height fro the shape data
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
; set the SPRITE_PTR to the coord data structure for the page that is not currently displayed 
; ( the page behind is he page we draw on
; ---------------------------------------------------------------
SetSpriteCoordPageBehind			lda BUFFER            	
									cmp PAGE2
									beq _setPageDisplayed2
_setPageDisplayed1					lda SPRITE_DATA_HI_BYTE_COORD_PAGE1
									jmp _endSetPageDisplayed
_setPageDisplayed2					lda SPRITE_DATA_HI_BYTE_COORD_PAGE2
_endSetPageDisplayed				sta SPRITE_PTR+1
									clc
									rts

; ---------------------------------------------------------------
; set the SPRITE_PTR to the coord data structure for the page that is currently displayed
; ---------------------------------------------------------------
SetSpriteCoordPageDisplayed			lda BUFFER            	
									cmp PAGE1
									beq _setPageBehind2
_setPageBehind1						lda SPRITE_DATA_HI_BYTE_COORD_PAGE1
									jmp _endSetPageBehind
_setPageBehind2						lda SPRITE_DATA_HI_BYTE_COORD_PAGE2
_endSetPageBehind					sta SPRITE_PTR+1
									clc
									rts

; ---------------------------------------------------------------
; Load the sprite coord data structure for the page that is not currently displayed for quick access ( HL, HR, VT, VB )
; ( the page behind is he page we draw on )
; ---------------------------------------------------------------
LoadSpriteCoordPageBehind		jsr SetSpriteCoordPageBehind
								jmp _loadHorizontal

; ---------------------------------------------------------------
; Load the sprite coord data structure for the page that is currently displayed for quick access ( HL, HR, VT, VB )
; ---------------------------------------------------------------
LoadSpriteCoordPageDisplayed	jsr SetSpriteCoordPageDisplayed
								
_loadHorizontal					ldy SPRITE_OFFSET_BYTE_HL
								lda (SPRITE_PTR),y 	
								sta HL
								ldy SPRITE_OFFSET_BYTE_HL+1
								lda (SPRITE_PTR),y
								sta HL+1

								ldy SPRITE_OFFSET_BYTE_HR
								lda (SPRITE_PTR),y 	
								sta HR
								ldy SPRITE_OFFSET_BYTE_HR+1
								lda (SPRITE_PTR),y
								sta HR+1

_loadVertical					ldy SPRITE_OFFSET_BYTE_VT
								lda (SPRITE_PTR),y 	
								sta VT
								ldy SPRITE_OFFSET_BYTE_VB
								lda (SPRITE_PTR),y 	
								sta VB

								rts

; ---------------------------------------------------------------
; Save the sprite coord data structure for the page that is not currently displayed ( HL, HR, VT, VB )
; ( the page behind is he page we draw on )
; ---------------------------------------------------------------
SaveSpriteCoordPageBehind		jsr SetSpriteCoordPageBehind
								jmp _saveHorizontal

; ---------------------------------------------------------------
; Save the sprite coord data structure for the page that is currently displayed ( HL, HR, VT, VB )
; ---------------------------------------------------------------
SaveSpriteCoordPageDisplayed	jsr SetSpriteCoordPageDisplayed 
							
_saveHorizontal					ldy SPRITE_OFFSET_BYTE_HL
								lda HL
								sta (SPRITE_PTR),y 	
								ldy SPRITE_OFFSET_BYTE_HL+1
								lda HL+1
								sta (SPRITE_PTR),y 	

								ldy SPRITE_OFFSET_BYTE_HR
								lda HR
								sta (SPRITE_PTR),y
								ldy SPRITE_OFFSET_BYTE_HR+1
								lda HR+1
								sta (SPRITE_PTR),y 	

_saveVertical					ldy SPRITE_OFFSET_BYTE_VT
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
;	ldx #$23 		; x coordinate low byte
;	ldy #$01		; x coordinate high byte ( 1 = +256)
;	lda #00 		; y coordinate 0-191 	
; ---------------------------------------------------------------
SetSpriteCoord		sta VT				; set the  verticla top of the sprite	 with the y coordinate ( accumulator )	
					adc H
					sta VB				; offset with height for the bottom vertical position
 								
					stx HL				; set the horizontal left of the sprite with the x coordinate ( low byte )
					sty HL+1			; set the horizontal left of the sprite with the y coordinate ( high byte )

					lda W				; we load the width in byte and will convert to pixels
					rol					; multiply by 8 ( 3x rol )
					rol
					rol
					tax
					lda #$00			; transert to x ( low byte for our with in pixel)
					adc #$00			; add the carry bit if the width exceed 280 ( max width in byte is 40, so it can only exceed on the thirds rol )
					tay					; transfer to y ( high byte for our with in pixel )

					txa 
					sec								
					sbc W				; substract the width in pixel to get the right coordinate for the right side of the sprite
					sta TMP				; save the width in pixel for the right side of the sprite
					tya
					sbc #00
					sta TMP+1					
					clc		

					lda HL				; adding the width in pixel to the left side of the sprite to get the right side of the sprite
					adc TMP
					sta HR
					lda HL+1
					adc TMP+1
					sta HR+1

					jsr SaveSpriteCoordPageBehind
					jsr DrawShape
					
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

					; set magic byte for tracing the remove need
					; if HL is 255, then we assume that the sprite has no position on that page, so there is not need to remove it

					jsr SetSpriteCoordPageDisplayed
					ldy SPRITE_OFFSET_BYTE_HL
					lda MAGIC_BYTE
					sta (SPRITE_PTR),y 

					rts


; ---------------------------------------------------------------
; This routine Draw all the sprite in the sprite table to the curret buffer page
; ---------------------------------------------------------------
DrawAllShape		jsr SwitchBuffer
					
					ldy SPRITE_COUNTER
					sty COUNTER
_drawAllShape		ldy COUNTER
					jsr LoadSpritePtr
					jsr LoadSpriteShapeData
					jsr LoadSpriteCoordPageBehind
					
					ldy SPRITE_OFFSET_BYTE_HL
					lda (SPRITE_PTR),y
					cmp MAGIC_BYTE
					beq _contDrawAllShape 
					clc
					jsr XDrawShape
					
_contDrawAllShape	clc
					jsr LoadSpriteCoordPageDisplayed
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
					jsr SaveSpriteCoordPageBehind
					jsr DrawShape
					dec COUNTER
					bne _drawAllShape
					jmp DrawAllShape ; temps
					rts


;todo
; vb and HR should not be 192 and 280, they should be 191 and 279
; Y_PTR to become VB_PTR ? X_PTR to become xbyte_ptr ?


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
					
					ldx HR
					ldy HR+1
					jsr XMapping		
					stx X_PTR
					sta XBIT_PTR
					

_loopDrawShapeH		lda W
					sta W_PTR					
					jsr SetMemoryMapAddr

_loopDrawShapeW		lda #00
					sta SHIFTED
					
					lda XBIT_PTR						; bit shifted				
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

					ldx HR
					ldy HR+1
					jsr XMapping		
					stx X_PTR
					sta XBIT_PTR 

					
_loopXDrawShapeH	lda W
					sta W_PTR
					jsr SetMemoryMapAddr

_loopXDrawShapeW	lda #00
					sta SHIFTED
					
					lda XBIT_PTR						; bit shifted				
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



; Shape of SquidShape width = 2, height = 24
; Structure: [width byte] [height byte] [shape_data...]
SquidShape hex 02181000204C4112491165486548244C34641F7C0F780360000003600C18300642214221400148012602260210040C180360

; Shape of SnakeShape width = 2, height = 24
; Structure: [width byte] [height byte] [sprite_data...]
SnakeShape hex 02180770080813642002277220021364080804100360000002201A2C21424001463144114001480126022602100408080770



; Shape of PapaSquidShape width = 4, height = 48
; Structure: [width byte] [height] [shape_data...]
PapaSquidShape hex 0430060000000E0000001C006170180061786003461C6003060E614306077143460378736140783361407833614078336160383161701C3071701E3078301E387C300F7F7F70077F7F70037F7F60017F7F40001F7C00000F78000000000000000000000F7800000F780001700740017007401E00003C1E00003C600C1803600C1803600C1803600C180360000003600000036140000361400003183C000C183C000C183C000C1C3C001C0E000038070000700370076001700740000F7800000F7800



; this is a track of 64 Notes, at 240 bpm ; melancoly
SquidTheme2Song hex 4064726466646064C064726466646064C064806466646064C064806466646064C064726466646064AC647264666460649A64726466644C649A648064666455649A6440643864326480644064386432642F643864406438649A64666460645564406448644C6455644C645564666460644C64556466646064556480646664606466
; this is a track of 39 Notes, at 240 bpm ; punk short
SquidThemeSong hex 2732AC320064AC32004BAC190032C064AC64C064E764C096AC649A64923280969232E732AC32803292329A64729655644C3248644C647264806492969A647264AC32809692329A3292329A32AC32C0
; this is a track of 123 Notes, at 240 bpm ; punk long
SquidTheme3Song hex 7B32AC320064AC320064AC320032C0320032C0320032AC3200329A32003292320096923200329232003280320032803200329A320032C0320032AC3200C8AC640032C0320064C064AC649A32923200329232003292320032923200327232003272320032923200329A32C032AC3200C8AC6400649264C064E764C032AC6400649A329232003280C892C88032723200967264AC3200649264C064E764C096AC969A649264726480649264C032AC320064AC320064AC3200649264C064E764C064AC3200329A320064923200FA9232803292329A64729655644C3248644C647264806492969A647264AC32809692329A3292329A32AC32C0
