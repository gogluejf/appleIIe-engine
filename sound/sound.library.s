; ----------------------------------------------------------------------------
; a nice low vibe motor sound
; ----------------------------------------------------------------------------
SoundMotor		lda #40
				sta MODULATION
_soundMotorLoop	ldx #$04
				stx DURATION
				ldy #$FF
				sty PITCH
				pha
				jsr PlayTone
				pla
				ldx #$04
				stx DURATION
				ldy #$00
				sty PITCH
				pha
				jsr PlayTone
				pla
				dec MODULATION
				bne _soundMotorLoop
				rts

; ----------------------------------------------------------------------------
; a nice reward chiming sound, like zelda reward, but on one tone
; ----------------------------------------------------------------------------
SoundReward		ldx #40
				stx DURATION
				ldy #255
				sty PITCH
				jsr PlayTone
				ldx #40
				stx DURATION
				ldy #128
				sty PITCH
				jsr PlayTone
				ldx #40
				stx DURATION
				ldy #64
				sty PITCH
				jsr PlayTone
				ldx #40
				stx DURATION
				ldy #31
				sty PITCH
				jsr PlayTone
				ldx #40
				stx DURATION
				ldy #15
				sty PITCH
				jsr PlayTone
				rts

; ----------------------------------------------------------------------------
; a very high frequency short sound
; ----------------------------------------------------------------------------
SoundIce			ldx #$ff ; duration
					ldy #$18 ; Pitch
					lda #$02 ; Modulation
					jsr SoundCresendo
					rts

; ----------------------------------------------------------------------------
; a very classic apple iie alarm sound
; ----------------------------------------------------------------------------
SoundAlarm			jsr SoundBubbleUp
					jsr SoundBubbleUp
					jsr SoundBubbleUp
					jsr SoundBubbleUp
					jsr SoundBubbleUp
					jsr SoundBubbleUp
					jsr SoundBubbleUp
					jsr SoundBubbleUp
					rts

; ----------------------------------------------------------------------------
; shot sound, like a bullet, 
; ----------------------------------------------------------------------------
SoundShoot			ldx #$01 ; duration
					ldy #$00 ; Pitch
					lda #$01 ; Modulation
					jsr SoundDecresendo
					rts

; ----------------------------------------------------------------------------
; bubble up sound, like a space bubble
; ---------------------------------------------------------------------------
SoundBubbleUp		ldx #$01 ; duration
					ldy #$ff ; Pitch
					lda #$01 ; mdoulation
					jsr SoundCresendo
					rts
; ----------------------------------------------------------------------------
; square wave sound, falling by steps
; ---------------------------------------------------------------------------
SoundFalling		ldx #$40 ; duration
					ldy #136 ; Pitch
					lda #$0F ; mdoulation
					jsr SoundDecresendo
					rts
; ----------------------------------------------------------------------------
; square sound going up
; ---------------------------------------------------------------------------
SoundSquare			ldx #$FF ; duration
					ldy #135 ; Pitch
					lda #$0F ; modulation
					jsr SoundCresendo
					rts
; ----------------------------------------------------------------------------
; machine gun sound , riffle of 3 shots
; ---------------------------------------------------------------------------
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
; ----------------------------------------------------------------------------
; laser sound, like a laser shot, shurt burst
; ---------------------------------------------------------------------------
SoundLaser			ldx #$02 ; duration
					ldy #$00 ; Pitch
					lda #$01 ; mdoulation
					jsr SoundDecresendo			
					rts