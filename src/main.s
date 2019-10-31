; Simple cursor driven adventure game
;
; TODO:
;	* Walk to and then do something (click on object, drag item to object)
;	* Dialog sequence
;	* Walk State
;	  - walking sfx
;   * mouse screen areas (things the mouse can interact with)
;	  - click on area leads to walk to then do something
;	* Select from a list of options
;	* Inventory
;   * player screen areas (things the player can interact with, walls, stairs, game objects)
;
; DONE:
;   * move assets to correct place in vic bank
;   * set up screen & colors from hard-arted test screen
;   * mouse input
;   * mouse -> cursor sprite positioning
;   * witch idle/walk state
;	  - animation system
;	  - reverse frames
;   * click on screen to walk
;	  - move to point
;   * simple scripting for each screen/state of each screen
;	* Left / Right edge action (script?)
;	* multiple screens


include zeropage.i
include animation.i
include memmap.i
include state.i

XDEF CursorX
XDEF CursorY

XREF PlayerPosX
XREF PlayerPosY

XREF SetupScreen		; Set up a screen
XREF ShowObjectSprites	; Set up object sprites

XREF BeginGameFrame
XREF RunAllScripts

XREF ReadStick
XREF InitStick
XREF MouseValid
XREF MouseDelta
XREF KeyboardBits
XREF KeyboardBitsChange
XREF RawSticks
XREF RawSticksHit

XREF BDoing_Init
XREF BDoing_Play
XREF BDoing_Update
XREF BDoing_AvailChannel

XREF SetAnim
XREF SetAnimFacing
XREF UpdateAnims
XREF Sprite_Clear
XREF Sprite_Copy
XREF InitAnim

XREF InitInventory
XREF InitGameScript
XREF InitPlayer
XREF UpdatePlayer
XREF InitActions
XREF UpdateActions
XREF CheckPlayerScreen
XREF UpdateItemSelector
XREF ClearItemSelector
XREF UpdateInventory

XREF CheckTextClear

XREF ObjectColor
XREF Spr_Cursor
;XREF SetAnimSpriteIndex
;XREF Player_Anim_Walk
;XREF Spr_Boy_Sad
;XREF Spr_Bull_Idle

XREF decrunchFrom


SECTION Code, code
org $801

; 1 SYS 2064
dc.b $0b, $08, $01, $00, $9e, $32, $30, $36, $34, $00, $00, $00, $00, $00, $00

{
	sei
	lda #$35
	sta 1
	ldx #$1f
	txs

	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	lda $dd0d

	; clear all of vram
	lda #>VRAM
	ldy #$40
	jsr Pages_Clear

	; set up screen mode
	lda $dd00	 ; vic bank = $4000
	and #$fc
	ora #VRAM_SET
	sta $dd00

	lda #$1b
	sta $d011
	lda #$c8
	sta $d016
	lda #((GameScreen>>6)&$f0) | ((GameFont>>10)&$0e)
	sta $d018
	lda #15
	sta $d020
	sta $d021

	jsr BDoing_Init	; sound effects init
	jsr InitStick	; input init
	jsr InitAnim	; animation, bit reverse init
	jsr InitActions
	jsr InitGameScript ; clear all the flags etc
	jsr InitPlayer	; player sprite
	jsr InitInventory
	jsr ClearItemSelector

	lda #0
	sta ObjectColor+1

; src in zpSrc
; dst in zpDst
; size in y (lo), x (hi)
	lda #<Font
	ldx #>Font
	jsr decrunchFrom

	; init cursor
	lda #160
	sta CursorX
	lda #0
	sta CursorX+1
	lda #100
	sta CursorY

	lda #0
	jsr SetupScreen

	; MOST OF THESE WILL COME FROM ANIMATIONS OR SCRIPTS, DON'T WORRY ABOUT SETTING UP PARAMETERS

	; cursor
	lda #<Spr_Cursor
	sta zpSrc
	lda #>Spr_Cursor
	sta zpSrc+1
	lda #Cursor_SPR
	ldx #21
	ldy #1
	jsr Sprite_Copy

	lda #<Interrupt
	sta $fffe
	lda #>Interrupt
	sta $ffff
	lda #1
	sta $d01a
	lda #$fa	; start interrupt at bottom border
	sta $d012

; a channel, x lo/y hi
;	lda #0
;	ldx #<Tick_SND
;	ldy #<Tick_SND
;	jsr BDoing_Play

	cli

	{
		sta IntWait
		{
			cmp IntWait
			beq !
		}

		jsr BeginGameFrame
if 0
		{
			XREF GameMouseClick
			lda GameMouseClick
			beq %
			debugbreak
			nop
		}
endif
		jsr CheckTextClear
		jsr UpdateItemSelector
		jsr UpdateInventory
		jsr UpdateActions
		jsr RunAllScripts
		jsr UpdatePlayer
		jsr UpdateAnims
		jsr CheckPlayerScreen

		jmp !
	}

	jmp *

}

; a = first page
; y = # pages
Pages_Clear:
{
	sta .loop+2
	lda #0
	tax
.loop
	sta VRAM,x
	inx
	bne .loop
	inc .loop+2
	dey
	bne .loop
	rts
}

; src in zpSrc
; dst in zpDst
; size in y (lo), x (hi)
CopyMem:
{
	zpUtility .zpLo
	; save initial size
	{
		tya ; lo size empty? skip right to page copy
		beq %
		pha	; save number of bytes copied in partial page
		{
			dey
			lda (zpSrc),y
			sta (zpDst),y
			cpy #$ff
			bne !
		}
		pla
		dex ; decrease pages left
		{ ; are we done?
			bpl %
			rts
		}
		clc
		pha
		adc zpSrc
		sta zpSrc
		{
			bcc %
			inc zpSrc+1
		}
		clc
		pla
		adc zpDst
		sta zpDst
		{
			bcc %
			inc zpDst+1
		}
	}
	{
		ldy #0
		{
			lda (zpSrc),y
			sta (zpDst),y
			iny
			bne !
			inc zpSrc+1
			inc zpDst+1
			dex
			bpl !
		}
	}
	rts
}















; Main interrupt
Interrupt:
{
	pha
	txa
	pha
	tya
	pha

;	inc $d020

	jsr ReadStick
	{
		lda MouseValid
		beq %
		
		lda MouseDelta ; x delta
		{
			cmp #$80 ; check if negative
			bcc %
			dec CursorX+1
		}
		clc
		adc CursorX
		sta CursorX
		{
			bcc %
			inc CursorX+1
		}
		{
			lda CursorX+1	; did the value overflow?
			bmi .overflow
			lda CursorX		; clamp to 8
			cmp #8
			lda CursorX+1
			sbc #0
			bcs %
.overflow
			lda #8
			sta CursorX
			lda #0
			sta CursorX+1
		}
		{
			lda CursorX
			cmp #<320
			lda CursorX+1
			sbc #>320
			bcc %
			lda #<320
			sta CursorX
			lda #>320
			sta CursorX+1
		}

		clc
		lda MouseDelta+1
		adc CursorY
		{
			cmp #224
			bcc %
			lda #0
		}
		{
			cmp #196
			bcc %
			lda #196
		}
		sta CursorY
		lda #0
		sta MouseDelta
		sta MouseDelta+1
	}

	{
		lda KeyboardBitsChange + 1
		and #$20
		beq %
		jsr BDoing_AvailChannel
		ldx #<Tock_SND
		ldy #>Tock_SND
		jsr BDoing_Play
	}

	{
		lda RawSticksHit
		and #$10
		bne %
		jsr BDoing_AvailChannel
		ldx #<LeftStep_SND
		ldy #>LeftStep_SND
		jsr BDoing_Play
	}

	{
		lda RawSticksHit
		and #$01
		bne %
		jsr BDoing_AvailChannel
		ldx #<RightStep_SND
		ldy #>RightStep_SND
		jsr BDoing_Play
	}

	; CHECK PLAYER STATE

	; SHOW SPRITES
	{
		zpInterrupt .zpSprHi
		zpInterrupt .zpSprEna
		lda #0
		sta .zpSprHi
		sta .zpSprEna

		lda #Cursor_SPR
		sta GameScreen + $3f8

		lda #0
		sta $d027 ; cursor (black)
		sta $d017
		sta $d01c
		sta $d01d

		lda ObjectColor+1
		sta $d028 ; player (black)

		clc
		lda CursorX
		adc #24-2
		sta $d000
		lda CursorX+1
		adc #0
		{
			beq %
			lda #1
			sta .zpSprHi
		}
		clc
		lda CursorY
		adc #50+3-21
		sta $d001
		lda #1
		sta .zpSprEna

		; show player sprite
		lda #Player_SPR
		sta GameScreen + $3f9
		clc
		lda PlayerPosX+1
		adc #24-4 ; player center at 4
		sta $d002
		lda PlayerPosX+2
		adc #0
		{
			beq %
			lda .zpSprHi
			ora #2 ; player mask is 2
			sta .zpSprHi
		}
		lda .zpSprEna
		ora #2
		sta .zpSprEna
		lda PlayerPosY+1
		adc #50 - 21 ; reference point is bottom of sprite
		sta $d003

		lda .zpSprHi
		sta $d010
		lda .zpSprEna
		sta $d015
	}

	jsr ShowObjectSprites

	jsr BDoing_Update

	inc IntWait

	ldy #$fa

;	dec $d020

;IntrptExit:
;	stx $fffe
;	sta $ffff

IntrptExitSame:
	; IRQ ACKNOWLEDGE
	lda #$ff
	sta $d019

	lda $d011
	and #$7f
	sta $d011

	sty $d012
IntrptJustExit:
	pla
	tay
	pla
	tax
	pla
IntrptJustRTI:
	rti
}


; test sounds
Tick_SND:
	dc.b $01, $1f, $00, $10, $00, $01, $11, $24, $41
	dc.b $08, $10, $40
	dc.b $00

Tock_SND:
	dc.b $01, $1f, $00, $10, $00, $07, $11, $24, $41
	dc.b $08, $10, $40
	dc.b $00

LeftStep_SND:
	dc.b $02, $3d, $00, $10, $21, $61, $81, $00, $01
	dc.b $06, $10, $80
	dc.b $00

RightStep_SND:
	dc.b $02, $3d, $00, $13, $21, $62, $81, $80, $ff
	dc.b $06, $10, $80
	dc.b $00


	incbin "..\bin\fontdata.exo"
Font:


SECTION BSS, bss

IntWait:
	ds 1

CursorX:
	ds 2
CursorY:
	ds 1

