; just a common place to print things

; text area is 6 top lines of screen

XDEF DrawText
XDEF ClearTextArea
XDEF CheckTextClear
XDEF SetClearTextOnClick

XREF GameMouseClick
XREF ClearItemSelector

include zeropage.i
include memmap.i

SECTION Code, code

CheckTextClear:
{
	{
		lda ClearTextOnClick
		beq %
		lda GameMouseClick
		beq %
		jsr ClearTextArea
		lda #0
		sta ClearTextOnClick
	}
	rts
}

SetClearTextOnClick:
{
	lda #1
	sta ClearTextOnClick
	rts
}

; text in zpSrc
; color in a
; len in x
; does not change zpLocal
DrawText:
{
	zpUtility .zpCol
	zpUtility .zpColDst.w

	sta .zpCol
	lda #<GameScreen
	sta zpDst
	sta .zpColDst
	lda #>GameScreen
	sta zpDst+1
	lda #>ColorRAM
	sta .zpColDst+1

	ldy #0
	sty ClearTextOnClick
	{
		lda (zpSrc),y
		bpl .char
		and #$f
		sta .zpCol
		dec zpDst ; compensate for hidden char by dec destination
		bne .next
		dec zpDst+1
		bne .next
.char	sta (zpDst),y
		lda .zpCol
		sta (.zpColDst),y
.next	iny
		{
			bne %
			inc zpSrc+1
			inc zpDst+1
			inc .zpColDst+1
		}
		dex
		bne !
	}
	rts
}



ClearTextArea:
{
	ldx #240
	lda #0
	{
		dex
		sta GameScreen,x
		bne !
	}
	jsr ClearItemSelector
	rts
}

SECTION BSS, bss

ClearTextOnClick:
	ds 1
