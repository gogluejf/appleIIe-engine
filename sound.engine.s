; ---------------------------------------------------------------
; Sound Subroutine
; ---------------------------------------------------------------
SPEAKER			equ $C030 ; use STA, to poke the speaker, depending on delay on each poke, it will generate a tone, used routines to make sound.

; ---------------------------------------------------------------
; variable for Sound Engine
; ---------------------------------------------------------------
MODULATION		equ $04
DURATION		equ $05 
PITCH			equ $06


; ---------------------------------------------------------------
; play tone for a precise duration, good for music
; read the set PITCH and DURATION from memory address and play the tone
; the routine leave the PITCH in accurate state, but let DURATION in innacurate state compare to entry, use carefully
; ---------------------------------------------------------------
PlayTone		ldx PITCH
				bne _speakerTone 			; if not zero, if have a ptich, otherwize rest
_restTone		nop							; the rest is exact same as length as tone, nop, nope to match the dec pitch intstruction
				nop
				dey 						; no value set,  as far as it is loop every 255 cycles
				bne _restTone
				dec DURATION
				bne _restTone
				jmp _endPlayTone
_speakerTone	sta SPEAKER
_decDuration	dey 						; no value set,  as far as it is loop every 255 iteation
				bne _decPitch				; every 255 iteration, we decrease the duration
				dec DURATION
				beq _endPlayTone
_decPitch		dex
				bne _decDuration			; if not zero, keep going with duration, we stil on he right pitch
				ldx PITCH
				jmp _speakerTone
_endPlayTone	rts


; ---------------------------------------------------------------
; Play sound, the lower is the pitch, the shorter is the sound duration
; becaues the full duration is pitch iteration * duration iteration
; this is very cool to create nice sound effesct

; ---------------------------------------------------------------
PlaySound		ldx DURATION
_loopSound		ldy PITCH
				sta SPEAKER
_loopPitch		dey				
				bne _loopPitch
				dex
				bne _loopSound
				rts


; ---------------------------------------------------------------
; Play a sound by decreasting the pitch tone based on a modulation of pitch at each duration.
; The X-Register holds the duration, the Y-Register holds the pitch, and the Accumulator holds the modulation.
;
; Usage:
;   ldx #$00 ; Load desired duration into X-Register
;   ldy #$FF ; Load desired pitch into Y-Register
;   lda #$08 ; Load desired modulation into Accumulator
;   jsr SoundDecresendo
; ---------------------------------------------------------------
SoundDecresendo		stx DURATION
					sta MODULATION
					tya
_soundDeresendoLoop	sta PITCH
					jsr PlaySound
					clc								; is it necessary? need to review
					adc MODULATION					; increasing value is actually decreasing the pitch due to longer frequency
					bne _soundDeresendoLoop
					rts

; ---------------------------------------------------------------
; Play a sound by increasing the pitch tone based on a modulation of pitch at each duration.
; The X-Register holds the duration, the Y-Register holds the pitch, and the Accumulator holds the modulation.
;
; Usage:
;   ldx #$00 ; Load desired duration into X-Register
;   ldy #$FF ; Load desired pitch into Y-Register
;   lda #$08 ; Load desired modulation into Accumulator
;   jsr SoundCresendo
; ---------------------------------------------------------------
SoundCresendo		stx DURATION
					sta MODULATION
					tya
_soundCresendoLoop	sta PITCH
					jsr PlaySound
					sec								; is it necessary? need to review
					sbc MODULATION					; increasing value is actually decreasing the pitch due to longer frequency
					bne _soundCresendoLoop
					rts


; ---------------------------------------------------------------
; Testing the pulse to be sure tone and rest tone are the same duration
; this is a dead end, only used for debugging and testing pulse
; ---------------------------------------------------------------
DbgPulse		lda #$ff		; the duration of the pulse
_pulseTone		ldy #$ff		; low pitch
				sty PITCH
				tax
				stx DURATION
				jsr PlayTone
_pulseRest		ldy #$00		; silent pitch
				sty PITCH
				tax
				stx DURATION				
				jsr PlayTone
				jmp _pulseTone


; ---------------------------------------------------------------
; Testing the sound effect, loop through all the sound effect pre build in the library
; this is a dead end, only used for debugging and testing sound effecc
; ---------------------------------------------------------------
DbgTestSounds		jsr UnblockWhenKeyPressed
					jsr SoundMotor
					jsr UnblockWhenKeyPressed
					jsr SoundReward
					jsr UnblockWhenKeyPressed
					jsr SoundIce
					jsr UnblockWhenKeyPressed
					jsr SoundAlarm
					jsr UnblockWhenKeyPressed
					jsr SoundShoot
					jsr UnblockWhenKeyPressed
					jsr SoundBubbleUp
					jsr UnblockWhenKeyPressed				
					jsr SoundFalling
					jsr UnblockWhenKeyPressed
					jsr SoundSquare
					jsr UnblockWhenKeyPressed				
					jsr SoundMachineGun
					jsr UnblockWhenKeyPressed				
					jsr SoundLaser
					jmp DbgTestSounds


; ---------------------------------------------------------------
; Have found changing the value, and calling different sound effect, we can create a lot of sound effect
; when satisfy, move your routine to the sound library and five it a subroutine label
; this function is a dead end, only used for debugging and testing sound effect
; ---------------------------------------------------------------
DbgShapeSoundEffect	jsr UnblockWhenKeyPressed
					ldx #$ff ; duration
					ldy #$ff ; Pitch
					lda #$08 ; Modulation
					jsr SoundCresendo
					jmp DbgShapeSoundEffect


; ---------------------------------------------------------------
; Make scratching noise with the Paddle 0
; this function is a dead end, only used for debugging and testing scratching sound
; ---------------------------------------------------------------
DbgScratchingSound		ldx #$00 				; joystick 0
_pitchDelay 			jsr PREAD 				; read the joystick position X axis
						tya 					; transfer to A only to print to screen
						jsr COUT 				; print to screen
						sta SPEAKER				; poke the speaker
_loopScratchPich		dey						; decreate for creating the pich
						bne _loopScratchPich
						jmp _pitchDelay			; to read another pitch from joystick
