; player state logic
;
; * idle - initial state, set when goal position reached
; * walking - set when cursor click on screen
;

XDEF InitPlayer
XDEF UpdatePlayer
XDEF SetPlayerPosX
XDEF GetPlayerPosX
XDEF SetPlayerPosY
XDEF SetPlayerState
XDEF GetPlayerState

XDEF ForcePlayerWalkToX
XDEF ForcePlayerDance
XDEF SetScriptOnPlayerWalkDone

XREF GameMouseClick
XREF PlayerInputLocked
XREF SetPlayerInputLock
XREF CursorX

XDEF PlayerPosX
XDEF PlayerPosY

XREF SetAnim
XREF SetAnimFacing
XREF SetAnimSpriteIndex
XREF AnimDone
XREF Player_Anim_Walk
XREF Player_Anim_Idle
XREF Player_Anim_Dance
XREF Player_Anim_Cauldron

XREF AddScreenScript
XREF ActionDone

XREF BDoing_Play
XREF BDoing_ExitLoop
XREF BDoing_AvailChannel

include zeropage.i
include state.i
include memmap.i

SECTION Code, code

InitPlayer:
{
	lda #State.Idle
	sta PlayerState

	; player
	ldx #0	; x is animation slot
	lda #Player_SPR
	jsr SetAnimSpriteIndex
	rts
}

; a = x lo, x = x hi, y = facing
SetPlayerPosX:
{
	sta PlayerPosX+1
	stx PlayerPosX+2
	tya
	ldx #0
	jsr SetAnimFacing
	jsr ExitState
	lda #State.Idle
	sta PlayerState
	ldx #0
	lda #<Player_Anim_Idle	; a(lo) / y(hi) animation
	ldy #>Player_Anim_Idle
	jmp SetAnim
}

; returns a = x lo, x = x hi
GetPlayerPosX:
{
	lda PlayerPosX+1
	ldx PlayerPosX+2
	rts
}

SetPlayerPosY:
{
	sta PlayerPosY+1
	rts
}

SetPlayerState:
{
	cmp #State.Dancing
	beq ForcePlayerDance
	cmp #State.Mixing
	beq ForcePlayerMix
	rts
}

GetPlayerState:
{
	lda PlayerState
	rts
}

ForcePlayerDance:
{
	jsr ExitState
	lda #State.Dancing
	sta PlayerState

	ldx #0
	lda #<Player_Anim_Dance	; a(lo) / y(hi) animation
	ldy #>Player_Anim_Dance
	jsr SetAnim

	lda #1
	jmp SetPlayerInputLock
}

ForcePlayerMix:
{
	jsr ExitState
	lda #State.Mixing
	sta PlayerState

	ldx #0
	lda #1
	jsr SetAnimFacing
	lda #<Player_Anim_Cauldron	; a(lo) / y(hi) animation
	ldy #>Player_Anim_Cauldron
	jsr SetAnim

	lda #134
	sta PlayerPosX+1
	lda #0
	sta PlayerPosX+2

	lda #1
	jmp SetPlayerInputLock
}

; x = x, a = x hi
ForcePlayerWalkToX:
{
	stx PlayerWalkToX
	sta PlayerWalkToX+1

	ldx #0
	stx PlayerDestinationScript
	stx PlayerDestinationScript+1
	lda PlayerPosX+1 ; carry set if target < curr
	cmp PlayerWalkToX
	lda PlayerPosX+2
	sbc PlayerWalkToX+1
	txa
	rol ; 1 if target < curr
	jsr SetAnimFacing

	{
		lda #State.Walking
		cmp PlayerState
		beq %

		jsr ExitState

		lda #State.Walking
		sta PlayerState

		ldx #0
		lda #<Player_Anim_Walk	; a(lo) / y(hi) animation
		ldy #>Player_Anim_Walk
		jsr SetAnim

		sei
		{
			jsr BDoing_AvailChannel
			sta PlayerWalkSoundChannel
			bmi %
			ldx #<Walk_SND
			ldy #>Walk_SND
			jsr BDoing_Play
		}
		cli
	}
	rts
}

; x = script lo, a = script hi
SetScriptOnPlayerWalkDone:
{
	stx PlayerDestinationScript
	sta PlayerDestinationScript+1
	rts
}

UpdatePlayer:
{
	; Change state?
	{	; check mouse all the time, not just when idling
		lda GameMouseClick
		beq %

		lda PlayerInputLocked
		bne %

		lda #0 ; consume the mouse click
		sta GameMouseClick

		ldx CursorX
		lda CursorX+1
		jsr ForcePlayerWalkToX
	}

	{
		lda PlayerState
		cmp #State.Mixing
		beq .update
		cmp #State.Dancing
		bne %
.update	{
			ldx #0
			jsr AnimDone
			bne %
			rts
		}
		jsr ExitState
		inc ActionDone
		ldx #0
		lda #<Player_Anim_Idle	; a(lo) / y(hi) animation
		ldy #>Player_Anim_Idle
		jsr SetAnim
		lda #State.Idle
		sta PlayerState
		lda #0
		jmp SetPlayerInputLock
	}

	lda PlayerState
	{
		cmp #State.Walking
		bne %

		lda PlayerPosX+1 ; carry set if target < curr
		cmp PlayerWalkToX
		lda PlayerPosX+2
		sbc PlayerWalkToX+1
		bcc .right

		sec
		lda PlayerPosX+1
		sbc #1
		sta PlayerPosX+1
		lda PlayerPosX+2
		sbc #0
		sta PlayerPosX+2

		lda PlayerPosX+1 ; carry set if target < curr
		cmp PlayerWalkToX
		lda PlayerPosX+2
		sbc PlayerWalkToX+1
		bcs %
		bcc .idle
.right
		clc
		lda PlayerPosX+1
		adc #1
		sta PlayerPosX+1
		lda PlayerPosX+2
		adc #0
		sta PlayerPosX+2

		lda PlayerPosX+1 ; carry set if target < curr
		cmp PlayerWalkToX
		lda PlayerPosX+2
		sbc PlayerWalkToX+1
		bcc %
.idle
		jsr ExitState
		ldx #0
		lda #<Player_Anim_Idle	; a(lo) / y(hi) animation
		ldy #>Player_Anim_Idle
		jsr SetAnim
		lda #State.Idle
		sta PlayerState

		{
			; x = lo, a = hi ptr to script
			ldx PlayerDestinationScript
			lda PlayerDestinationScript+1
			beq %
			jsr AddScreenScript
		}
	}
	rts
}

ExitState:
{
	lda PlayerState
	{
		cmp #State.Walking
		bne %
		ldx PlayerWalkSoundChannel
		bmi %
		sei
		jsr BDoing_ExitLoop
		cli
		lda #$ff
		sta PlayerWalkSoundChannel
	}
	rts
}

//
Walk_SND:
	dc.b $02, $3d, $00, $07, $11, $51, $81, $d0, $ff
	dc.b $09, $10, $80
	dc.b $02, $31, $00, $06, $81, $30, $00
	dc.b $09, $10, $80
	dc.b $ea
	dc.b $09, $00
	dc.b $00



SECTION BSS, bss

PlayerState:
	ds 1
PlayerWalkToX:
	ds 2 ; fixed position
PlayerDestinationScript:
	ds 2

PlayerPosX:
	ds 3
PlayerPosY:
	ds 2

PlayerWalkSoundChannel:
	ds 1