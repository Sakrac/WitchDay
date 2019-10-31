;
; Shows sprites and possibly other things 
;

include zeropage.i
include memmap.i

XDEF ClearAllObjects
XDEF ShowObject
XDEF SetObjectColor
XDEF SetObjectPos
XDEF ObjectColor
XDEF ShowObjectSprites

XREF BitIndex
XREF SetAnimSpriteIndex
XREF GetAnimSpriteIndex
XREF SetAnimFacing

XREF AnimWidth ; width of each object

SECTION Code, code

; call when changing screens
ClearAllObjects:
{
	lda #3 ; player and cursor are always enabled
	sta ObjectEnabled
	rts
}

; x = object index, a = sprite index
ShowObject:
{
	jsr SetAnimSpriteIndex ; a = sprite index, x = slot
	lda #0
	jsr SetAnimFacing ; clear facing for slot x (default)
	lda BitIndex,x
	ora ObjectEnabled
	sta ObjectEnabled
	rts
}

; x = object #, a = color
SetObjectColor:
{
	sta ObjectColor,x
	rts
}

; x = object a = x*2, C = x low bit, y = y
SetObjectPos:
{
	rol
	sta ObjectPosX,x
	lda #0
	rol
	sta ObjectPosXHi,x
	tya
	sta ObjectPosY,x
	rts
}

; called from interrupt!
; go through object 2-7 if enabled
ShowObjectSprites:
{
	zpInterrupt .zpHiX
	lda #0
	sta .zpHiX
	lda ObjectEnabled
	lsr
	lsr
	ldy #4
	ldx #2
	{
		{
			lsr .zpHiX
			lsr
			bcc %
			asl .zpHiX
			pha
			clc
			lda ObjectPosY,x
			adc #50-21 ; reference is bottom of sprite
			sta $d001,y
			lda AnimWidth,x	; half width
			lsr
			eor #$ff
			sec
			adc #24
			clc
			adc ObjectPosX,x
			sta $d000,y
			lda ObjectPosXHi,x
			adc #0
			lsr
			ror .zpHiX
			lda ObjectColor,x
			sta $d027,x
			jsr GetAnimSpriteIndex
			sta GameScreen + $3f8,x
			pla
		}
		inx
		iny
		iny
		cpx #8
		bcc !
	}
	lda $d015
	and #3
	ora ObjectEnabled
	sta $d015
	lda $d010
	and #3
	ora .zpHiX
	sta $d010
	rts
}


const MAX_OBJECTS_SCREEN = 8 ; 1 for each sprite, although 0 is cursor and 1 is player.

SECTION BSS, bss

ObjectEnabled:
	ds 1	; 1 bit per object, matches sprite enable register

ObjectColor:
	ds MAX_OBJECTS_SCREEN

ObjectPosX:
	ds MAX_OBJECTS_SCREEN

ObjectPosXHi:
	ds MAX_OBJECTS_SCREEN

ObjectPosY:
	ds MAX_OBJECTS_SCREEN

