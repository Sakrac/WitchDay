; show some use actions on-screen

XDEF InitActions
XDEF UpdateActions
XDEF DrawActions
XDEF ActiveAction
XDEF ActionDone

XREF CursorX
XREF CursorY

XREF GameMouseClick
XREF PlayerInputLocked
XREF ForcePlayerDance


include game.i
include zeropage.i
include memmap.i
include script.i

SECTION Code, code

const NUM_ACTIONS = 4
const WID_ACTION = 6

DrawActions:
{
	ldx #0
	{
		zpUtility .zpCol.w
		lda ActionText,x
		sta zpSrc
		lda ActionText+1,x
		sta zpSrc+1
		lda ActionText+3,x
		sta zpDst
		sta .zpCol
		lda ActionText+4,x
		sta zpDst+1
		clc
		adc #>(ColorRAM - GameScreen)
		sta .zpCol+1
		ldy ActionText+2,x
		{
			lda (zpSrc),y
			sta (zpDst),y
			lda #11
			sta (.zpCol),y
			dey
			bpl !
		}
		clc
		txa
		adc #5
		tax
		cpx #NUM_ACTIONS * 5
		bcc !
	}
	rts
}

InitActions:
{
	lda #-1
	sta ActiveAction
	sta HoverAction
	lda #0
	sta ConsumeAction
	rts
}

UpdateActions:
{
; check vertical row (0 is top, 2 is bottom)
	ldx #0
	stx ActionChanged
	{
		lda ActionDone
		bne .clearAction
		lda ConsumeAction
		beq %
.clearAction
		{
			lda #0
			sta ActionDone
			ldy ActiveAction
			cpy #NUM_ACTIONS
			bcs %
			inc ActionChanged
			ldx #11
			jsr .MarkAction
		}
		lda #-1
		sta ActiveAction
	}
	lda GameMouseClick
	sta ConsumeAction

	ldy #-1
	lda PlayerInputLocked
	bne .noScreenCheck
	{
		lda CursorY
		cmp #(ActionScreenYC+2) * 8
		bcc .notLower
		ldy #2
		bne %
.notLower		
		cmp #(ActionScreenYC+1) * 8
		bcs %
		cmp #(ActionScreenYC) * 8
		bcc %
		iny
	}
	{
		tya
		bmi %
		lda CursorX+1
		bne .badX ; no actions in the high X range
		lda CursorX
		cmp #WID_ACTION * 8 * 2
		bcs .badX
		cmp #WID_ACTION * 8
		bcc %
		iny
		bne %
.badX	ldy #-1
	}
.noScreenCheck
	tya
	{	; check if clicking
		zpLocal .actionPrev
		bmi %
		ldx GameMouseClick
		beq %
		ldx PlayerInputLocked
		bne %
		stx GameMouseClick
		stx ConsumeAction
		{
			ldy ActiveAction
			cpy #NUM_ACTIONS
			bcs %
			ldx #11
			jsr .MarkAction
		}
		sta ActiveAction
		tay
		ldx #6
		jsr .MarkAction
		inc ActionChanged
	}

	{
		cmp HoverAction
		beq %
		{
			ldy HoverAction
			bmi % ; don't need to clear if not hovering
			ldx #11
			{
				cpy ActiveAction
				bne %
				ldx #6
			}
			jsr .MarkAction
		}
		sta HoverAction
		{
			tay
			bmi %
			ldx #0
			{
				cmp ActiveAction
				bne %
				ldx #6
			}
			jsr .MarkAction
		}
	}

	{
		lda ActionChanged
		beq %
		lda ActiveAction
		cmp #PlayerAction.Dance
		bne %
		jsr ForcePlayerDance
	}
	rts
	; y = action, x = color
.MarkAction
	{
		zpUtility .zpAction
		sty .zpAction
		pha
		tya
		asl
		asl
		adc .zpAction
		tay
		lda ActionText+3,y
		sta zpDst
		clc
		lda ActionText+4,y
		adc #>(ColorRAM - GameScreen)
		sta zpDst+1
		ldy #WID_ACTION-1
		txa
		{
			sta (zpDst),y
			dey
			bpl !
		}
		pla
		rts
	}
}


ActionText:
{
	dc.w ActionTalk
	dc.b ActionTalkLen-1
	dc.w GameScreen + ActionScreenYC * 40

	dc.w ActionEat
	dc.b ActionEatLen-1
	dc.w GameScreen + ActionScreenYC * 40 + WID_ACTION

	dc.w ActionDance
	dc.b ActionDanceLen-1
	dc.w GameScreen + (ActionScreenYC + 2 ) * 40

	dc.w ActionUse
	dc.b ActionUseLen-1
	dc.w GameScreen + (ActionScreenYC + 2 ) * 40 + WID_ACTION
}

ActionTalk:
	TEXT [FontOrder] "Talk"
const ActionTalkLen = * - ActionTalk

ActionDance:
	TEXT [FontOrder] "Dance"
const ActionDanceLen = * - ActionDance

ActionEat:
	TEXT [FontOrder] "Eat"
const ActionEatLen = * - ActionEat

ActionUse:
	TEXT [FontOrder] "Use"
const ActionUseLen = * - ActionUse


SECTION BSS, bss

ActiveAction:
	ds 1	; -1 if no action

ActionChanged:
	ds 1

ActionDone:
	ds 1	; action was completed

HoverAction:
	ds 1	; current action that is hovered by the cursor

ConsumeAction:
	ds 1	; if clicking anywhere except selecting an action it is consumed the next frame
