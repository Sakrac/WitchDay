; * draw text for all items
; * select one or many
; * hover / select color
; 3 columns
; 0123456789012
;"Breath of Dog"
;
; 0123456789012345678901234567890123456789
; 012345678901  012345678901  012345678901

include game.i
include zeropage.i
include memmap.i

XDEF DrawItemSelector
XDEF UpdateItemSelector
XDEF ClearItemSelector
XDEF ItemSelectorOn
XDEF ItemSelection

XREF ClearTextArea
XREF CursorY
XREF CursorX
XREF GameMouseClick


SECTION Code, code

struct ItemList {
	word title
	byte id
	byte title_len
	word callback
	byte items
}

struct ItemEntry {
	word name
	byte name_len
}

ClearItemSelector:
{
	lda #0
	sta ItemSelectorOn
	rts
}

UpdateItemSelector:
{
	{
		lda ItemSelectorOn
		bne %
		rts
	}

	; determine rows

	{
		lda CursorY
		cmp #8
		bcc %
		cmp #6*8
		bcs %

		; returns item index in x
		jsr GetHoverItemIndex

		{
			ldx GameMouseClick
			beq %
			ldx #0
			stx GameMouseClick
			cmp ItemSelectorCount
			bcs %
			tax
			pha
			lda ItemSelection,x
			eor #1
			sta ItemSelection,x
			pla
			{
				ldy SelectCallback+2
				beq %
SelectCallback:
				jmp $0000
			}
		}

		{
			cmp ItemSelectorHover
			beq %
			pha
			{
				lda ItemSelectorHover
				cmp ItemSelectorCount
				bcs %
				tay
				ldx ItemSelection,y
				beq .notSel
				ldx #6
				dc.b $2c
	.notSel		ldx #11
				jsr .MarkItem
			}
			pla
		}

		{
			cmp ItemSelectorHover
			beq %
			sta ItemSelectorHover
			cmp ItemSelectorCount
			bcs %
			ldx #0
			jsr .MarkItem
		}
	}

	rts

.MarkItem
	tay
	lda ItemToScreenOffs,y
	tay
	txa
	ldx #11
	{
		sta ColorRAM+40,y
		iny
		dex
		bpl !
	}
	rts
}

ItemToScreenOffs:
{
	rept 5 {
		dc.b rept*40, rept*40+14, rept*40+28
	}
}


GetHoverItemIndex:
{
	ldx #4 * 3
	lda #5*8
	{
		cmp CursorY
		bcc %
		sbc #8
		dex
		dex
		dex
		bne !
	}
	{
		lda CursorX+1
		beq .loX
		inx
		inx
		bne %
.loX	lda CursorX
		cmp #13*8
		bcc %
		inx
		cmp #27*8
		bcc %
		inx
	}
	; a is hover index
	txa
	rts
}


; zpSrc is a pointer to a potion selector
DrawItemSelector:
{
	zpLocal .zpText.w
	zpLocal .zpLeft
	zpLocal .zpColumn


	jsr ClearTextArea
	ldx #40
	lda #2
	{
		dex
		sta ColorRAM,x
		bne !
	}

	ldx #5 * 40
	lda #11
	{
		dex
		sta ColorRAM+40,x
		bne !
	}

	; deselect everything
	ldx #5*3
	lda #0
	{
		dex
		sta ItemSelection,x
		bne !
	}

	lda #-1
	sta ItemSelectorHover

	ldy #ItemList.items
	lda (zpSrc),y
	sta ItemSelectorCount
	sta .zpLeft

	ldy #ItemList.callback
	lda (zpSrc),y
	sta SelectCallback+1
	iny
	lda (zpSrc),y
	sta SelectCallback+2

	ldy #0
	lda (zpSrc),y
	sta .zpText
	iny
	lda (zpSrc),y
	sta .zpText+1
	iny
	lda (zpSrc),y
	sta ItemSelectorOn
	iny
	lda (zpSrc),y
	tay
	lsr
	adc #19
	tax
	{
		dey
		lda (.zpText),y
		sta GameScreen,x
		dex
		tya
		bne !
	}

	lda zpSrc
	adc #ItemList.bytes
	sta zpSrc
	{
		bcc %
		inc zpSrc+1
	}

	ldx #0
	stx .zpColumn
	{
		txa
		pha

		ldy #0
		lda (zpSrc),y
		sta .zpText
		iny
		lda (zpSrc),y
		sta .zpText+1
		iny
		lda (zpSrc),y
		sta .lenchk+1
		ldy #0
.loop	lda (.zpText),y
		sta GameScreen+40,x
		inx
		iny
.lenchk	cpy #12
		bcc .loop

		clc
		lda zpSrc
		adc #ItemEntry.bytes
		sta zpSrc
		{
			bcc %
			inc zpSrc+1
		}

		pla
		clc
		ldx .zpColumn
		adc .columnWidth,x
		inx
		{
			cpx #3
			bcc %
			ldx #0
		}
		stx .zpColumn
		tax

		dec .zpLeft
		bne !
	}
	rts

.columnWidth:
	dc.b 14, 14, 12
}



SECTION BSS, bss

ItemSelectorOn:
	ds 1

ItemSelectorHover:
	ds 1

ItemSelectorCount:
	ds 1

ItemSelection:
	ds 5 * 3


