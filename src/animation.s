; ANIMATION CODE

include zeropage.i
include animation.i
include memmap.i

XDEF SetAnim
XDEF SetAnimSpriteIndex
XDEF GetAnimSpriteIndex
XDEF SetAnimFacing
XDEF UpdateAnims
XDEF Sprite_Clear
XDEF Sprite_Copy
XDEF InitAnim
XDEF AnimDone

XDEF AnimWidth

XREF BitIndex

const MAX_ANIMATIONS = 8

SECTION Code, code

; x = slot
; a = sprite index
SetAnimSpriteIndex:
{
	sta AnimPlayIndex,x
	rts
}

; x = slot, return sprite index in a
GetAnimSpriteIndex:
{
	lda AnimPlayIndex,x
	rts
}

; x = slot
; a = true if reversed
; no registers changed
SetAnimFacing:
{
	sta AnimPlayFacing,x
	rts
}

; x = animation
AnimDone:
{
	lda AnimPlayWait,x
	bmi .yes
	lda #0
	rts
.yes
	lda #1
	rts
}

; a(lo) / y(hi) animation
; x is animation slot
SetAnim:
{
	; set pointer to animation data
	sta AnimPlayDataStartLo,x
	tya
	sta AnimPlayDataStartHi,x
	lda BitIndex,x
	ora AnimEnabled
	sta AnimEnabled
	lda #0	; set frame -1 so it will increment to frame 0
	jmp ForceAnimFrame
}

; x = anim slot
StopAnim:
{
	lda BitReverse,x
	and AnimEnabled
	sta AnimEnabled
	rts
}

StopAllAnims:
{
	lda #0
	sta AnimEnabled
	rts
}

UpdateAnims:
{
	lda AnimEnabled
	ldx #0
	{
		{
			lsr
			bcc %
			pha
			txa
			pha
			jsr UpdateAnim
			pla
			tax
			pla
		}
		inx
		cpx #MAX_ANIMATIONS
		bcc !
	}
	rts
}

; x is animation slot
UpdateAnim:
{
	{
		lda AnimPlayWait,x
		bmi .stopped
		sec
		sbc #1
		sta AnimPlayWait,x
		bcc %
.stopped
		rts
	}
	lda AnimPlayFrame,x
	clc
	adc #1
} ; fall through
; x = anim slot
; a = anim frame
ForceAnimFrame:
{
	zpLocal .zpAnim.w
	zpLocal .zpSlot
	sta AnimPlayFrame,x
	asl
	adc #AnimData.Frames
	tay ; y is animation data frame
	lda AnimPlayDataStartLo,x
	sta .zpAnim
	lda AnimPlayDataStartHi,x
	sta .zpAnim+1

	lda (.zpAnim),y
	{	; if anim frame < 0 then restart animation
		bpl %
		lda #0
		sta AnimPlayFrame,x
		ldy #AnimData.Frames
		lda (.zpAnim),y
	}
	pha ; frame index
	iny
	lda (.zpAnim),y
	sta AnimPlayWait,x

	; store width of current frame
	ldy #AnimData.Width
	lda (.zpAnim),y
	asl
	asl
	asl
	sta AnimWidth,x

	ldy #AnimData.Graphics
	lda (.zpAnim),y
	sta zpSrc
	iny
	lda (.zpAnim),y
	sta zpSrc+1

	ldy #AnimData.Width
	lda (.zpAnim),y
	stx .zpSlot
	tax ; width
	dey
	lda #0	; zpSrc will contain the sprite source graphics
	{	; calculate size of one frame
		clc
		adc (.zpAnim),y
		dex
		bne !
	}
	; a is now size of frame
	tay
	pla ; frame
	tax
	tya
	{
		dex
		bmi %
.loop	pha
		clc
		adc zpSrc
		sta zpSrc
		{
			bcc %
			inc zpSrc+1
		}
		pla
		dex
		bpl .loop
	}
 
	ldx .zpSlot
	lda AnimPlayFacing,x
	php
	lda AnimPlayIndex,x	; Index
	pha
	ldy #AnimData.Height
	lda (.zpAnim),y ; Height
	tax
	iny
	lda (.zpAnim),y ; Width (bytes)
	tay
	pla
	plp
	beq %
	jmp Sprite_Copy_Reverse
;	jmp Sprite_Copy
} ; FALLTHROUGH
; copy sprite to trg
; src = zpSrc
; target sprite = a
; bytes/row = y
; lines = x
; align sprites with bottom!
Sprite_Copy:
{
	zpLocal .zpTrg
	zpLocal .zpLine
	stx .zpLine
	ldx #0
	stx .zpTrg
	lsr
	ror .zpTrg
	lsr
	ror .zpTrg
	ora #>VRAM
	pha
	sta .zpTrg+1
	lda .zpLine
	asl
	adc .zpLine ; carry clear after adc
	eor #$ff ; negate
	adc #64 ; add one for negation
	tax
	pla
.one
	dey
	bne .two
	{
		sta .trg+2
		lda .zpTrg
		sta .trg+1
.loop   lda (zpSrc),y
.trg	sta VRAM,x
		inx
		inx
		inx
		iny
		cpx #63
		bcc .loop
	}
	rts
.two
	dey
	bne .three
	{
		sta .trg+2
		sta .trg2+2
		lda .zpTrg
		sta .trg+1
		sta .trg2+1
.loop   lda (zpSrc),y
.trg	sta VRAM,x
		inx
		iny
		lda (zpSrc),y
.trg2	sta VRAM,x
		inx
		inx
		iny
		cpx #63
		bcc .loop
	}
	rts
.three
	{
		sta .trg+2
		lda .zpTrg
		sta .trg+1
		ldy #0
.loop   lda (zpSrc),y
.trg	sta VRAM,x
		inx
		iny
		cpx #63
		bcc .loop
	}
	rts
}

Sprite_Copy_Reverse:
{
	zpLocal .zpTrg ; starts same as Sprite_Copy
	zpLocal .zpLine
	stx .zpLine
	ldx #0
	stx .zpTrg
	lsr
	ror .zpTrg
	lsr
	ror .zpTrg
	ora #>VRAM
	pha
	sta .zpTrg+1
	lda .zpLine
	asl
	adc .zpLine ; carry clear after adc
	eor #$ff ; negate
	adc #64 ; add one for negation
	tax
	pla
.one
	dey
	bne .two
	{
		sta .trg+2
		lda .zpTrg
		sta .trg+1
.loop   lda (zpSrc),y
		stx .save_x+1
		tax
		lda BitReverse,x
.save_x	ldx #0
.trg	sta VRAM,x
		inx
		inx
		inx
		iny
		cpx #63
		bcc .loop
	}
	rts
.two
	dey
	bne .three
	{
		zpLocal .zpByte0
		sta .trg+2
		sta .trg2+2
		lda .zpTrg
		sta .trg+1
		sta .trg2+1
.loop   lda (zpSrc),y
		sta .zpByte0
		iny
		lda (zpSrc),y
		iny
		sty .save_y+1
		tay
		lda BitReverse,y
.trg	sta VRAM,x
		inx
		ldy .zpByte0
		lda BitReverse,y
.trg2	sta VRAM,x
		inx
		inx
.save_y	ldy #0
		cpx #63
		bcc .loop
	}
	rts
.three
	{
		zpLocal .zpByte0
		zpLocal .zpByte1
		sta .trg+2
		lda .zpTrg
		sta .trg+1
		ldy #0
.loop   lda (zpSrc),y
		sta .zpByte0
		iny
		lda (zpSrc),y
		sta .zpByte1
		iny
		lda (zpSrc),y
		iny
		sty .save_y+1
		tay
		lda BitReverse,y
.trg	sta VRAM,x
		inx
		ldy .zpByte1
		lda BitReverse,y
.trg	sta VRAM,x
		inx
		ldy .zpByte0
		lda BitReverse,y
.trg	sta VRAM,x
		inx
.save_y	ldy #0
		cpx #63
		bcc .loop
	}
	rts
}

; a = target sprite idx
; x untouched
Sprite_Clear:
{
	zpLocal .zpTrg.w
	ldy #0
	sty .zpTrg
	lsr
	ror .zpTrg
	lsr
	ror .zpTrg
	ora #>VRAM
	sta .zpTrg+1
	ldy #63-1
	{
		sta (.zpTrg),y
		dey
		bpl !
	}
	rts
}

InitAnim:
{
	; fill out bit reverse table
	ldx #0
	{
		zpLocal .zpBits
		stx .zpBits
		ldy #7
		{
			lsr .zpBits
			rol
			dey
			bpl !
		}
		sta BitReverse,x
		inx
		bne !
	}
	stx AnimEnabled
	rts
}

SECTION BSS, bss

AnimEnabled:			; update animations if true
	ds 1

; up to 8 animations
AnimPlayDataStartLo:	; address of AnimData
	ds MAX_ANIMATIONS

AnimPlayDataStartHi:
	ds MAX_ANIMATIONS

AnimPlayFrame:	; current frame of animation
	ds MAX_ANIMATIONS

AnimPlayWait:	; how many more screens to wait until next frame
	ds MAX_ANIMATIONS

AnimPlayIndex:
	ds MAX_ANIMATIONS

AnimPlayFacing:
	ds MAX_ANIMATIONS

AnimWidth:		; pixel width of current animation
	ds MAX_ANIMATIONS