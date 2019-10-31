; script ptr -> zero page word
; operator - byte -> function call, pull & increment script ptr
; function can pull further args from script ptr
; functions can return C flag or accumulator for condition to next operator

include zeropage.i
include script.i
include state.i

XDEF InitGameScript
XDEF ClearAllScripts
XDEF RunAllScripts
XDEF AddScreenScript

XREF BitIndex
XREF ShowObject
XREF SetObjectColor
XREF SetObjectPos
XREF ColorScreenArea
XREF DrawItemSelector
XREF SetAnim
XREF SetPlayerInputLock
XREF ForcePlayerWalkToX
XREF SetScriptOnPlayerWalkDone

XREF SetPlayerState
XREF GetPlayerState
XREF PlayerPosX
XREF ObjectColor

XREF AnimWidth

XREF GameMouseClick
XREF CursorX
XREF CursorY
XREF ActiveAction

XREF ClearTextArea
XREF DrawText

XREF InventoryDragType
XREF InventoryDrop
XREF ExchangeInventoryItem
XREF AddInventoryItem
XREF MixItemsIntoCauldron
XREF FillBottleFromCauldron

SECTION Code, code

InitGameScript:
{
	ldx #256>>3
	lda #0
	{
		dex
		sta ScriptFlags,x
		bne !
	}
	sta ScriptCount ; no current scripts
	rts
}

ClearAllScripts:
{
	ldy #0
	sty ScriptCount
	rts
}

; x = lo, a = hi ptr to script
AddScreenScript:
{
	ldy ScriptCount
	sta ScriptCurrHi,y
	txa
	sta ScriptCurrLo,y
	lda #0
	sta ScriptDisabled,y
    sta ScriptWaitFrames,y
	inc ScriptCount
	rts
}

RunAllScripts:
{
	{
		ldx ScriptCount
		bne %
		rts
	}
	ldx #0
	{
		{
			lda ScriptDisabled,x
			bne %
            lda ScriptWaitFrames,x
            beq .run
            dec ScriptWaitFrames,x
            jmp %
.run		lda ScriptCurrLo,x
			sta zpScript
			lda ScriptCurrHi,x
			sta zpScript+1
			stx ScriptContext
			jsr RunScript
			ldx ScriptContext
		}
		inx
		cpx ScriptCount
		bcc !
	}
	; clean up disabled scripts
	ldx #0
	ldy #0
	{
		{
            zpUtility .zpIdx
			lda ScriptDisabled,x
			bne %
            {
                stx .zpIdx  ; no copy needed if x = y
                cpy .zpIdx
                beq %
                lda ScriptCurrLo,x
                sta ScriptCurrLo,y
                lda ScriptCurrHi,x
                sta ScriptCurrHi,y
                lda ScriptObject,x
                sta ScriptObject,y
                lda ScriptWaitFrames,x
                sta ScriptWaitFrames,y
                lda #0
                sta ScriptDisabled,y
            }
			iny
		}
		inx
		cpx ScriptCount
		bcc !
        cpy ScriptCount
        beq %
		sty ScriptCount
	}
	rts
}

; zpScript is current PC of a script
RunScript:
{
	lda #0
	sta ScriptDone
	clc
	{   ; don't change C, X or A while interpreting
		ldy #0
        php
		pha
		lda (zpScript),y
		jsr IncScript
		asl
		tay
		lda ScriptFunctions,y
		sta .call+1
		lda ScriptFunctions+1,y
		sta .call+2
		pla
        plp
.call   jsr ScriptFunction
		ldy ScriptDone
		beq !
	}
ScriptFunction:
	rts
}

; increments script by 1
; no registers changed
; C preserved
IncScript:
{
	inc zpScript
	{
		bne %
		inc zpScript+1
	}
	rts
}

; A = increment, modifies C
AddScript:
{
	clc
	adc zpScript
	sta zpScript
	{
		bcc %
		inc zpScript+1
	}
	rts
}

ScriptFunctions:
	dc.w ScriptYield ; 0
	dc.w ScriptGoto
	dc.w ScriptGotoIfTrue
	dc.w ScriptDisable
	dc.w ScriptDisableIfTrue
	dc.w ScriptNotCondition ; 5
	dc.w ScriptCheckFlag
	dc.w ScriptSetFlag
	dc.w ScriptCheckHover
    dc.w ScriptCheckAction
    dc.w ScriptCheckClick ; 10
	dc.w ScriptCreateObject
	dc.w ScriptSetAnim
	dc.w ScriptSetPos
	dc.w ScriptSetColor
	dc.w ScriptSetColorConditional ; 15
    dc.w ScriptWait
    dc.w ScriptWaitClick
    dc.w ScriptShowText
    dc.w ScriptWalkPlayerToScript
    dc.w ScriptLockPlayer ; 20
    dc.w ScriptColorArea
    dc.w ScriptShowItemSelector
	dc.w ScriptCheckHoldItem
	dc.w ScriptCheckDropItem
	dc.w ScriptMixCauldron ; 25
	dc.w ScriptSetPlayerState
	dc.w ScriptFillBottleFromCauldron
	dc.w ScriptExchangeItem
	dc.w ScriptAddInventory
	dc.w ScriptCheckDanceBull


; arg = offset to next instruction
ScriptYield:
{
	ldx ScriptContext
	ldy #0
	lda (zpScript),y
	{
		bpl %
		dec zpScript+1
	}
	clc
	adc zpScript
	sta ScriptCurrLo,x
	lda zpScript+1
	adc #0
	sta ScriptCurrHi,x
	inc ScriptDone
	rts
}

ScriptGotoIfTrue:
{
	bcs %
    jsr IncScript
	rts
} ; FALLTHROUGH ScriptGoto
; arg = offset to next instruction
; preserves C and A
ScriptGoto:
{
	php
	pha
	ldx ScriptContext
	ldy #0
	lda (zpScript),y
	{
		bpl %
		dec zpScript+1
	}
	clc
	adc zpScript
	sta zpScript
	lda zpScript+1
	adc #0
	sta zpScript+1
	pla
	plp
	rts
}

; inverts C, preserves A
ScriptNotCondition:
{
	pha
	rol
	eor #1
	lsr
	pla
	rts
}

; no argument
ScriptDisableIfTrue:
{
	bcs %
	rts
} ; FALLTHROUGH
ScriptDisable:
{
	ldx ScriptContext
	inc ScriptDisabled,x
	inc ScriptDone
	rts
}

; pulls the flag index from the next script byte
; return x = flag byte, a = flag mask
; modifies C and Y
ScriptFlagArgToXA:
{
	ldy #0
	lda (zpScript),y
	jsr IncScript
	pha
	lsr
	lsr
	lsr
	tax
	pla
	and #7
	tay
	lda BitIndex,y
	rts
}

ScriptCheckFlag:
{
	jsr ScriptFlagArgToXA
	clc ; return clear carry if 
	and ScriptFlags,x
	{
		beq %
		sec
	}
	rts
}

ScriptSetFlag:
{
	jsr ScriptFlagArgToXA
	ora ScriptFlags,x
	sta ScriptFlags,x
	rts
}

ScriptCreateObject:
{
	ldy #0
	lda (zpScript),y
	ldx ScriptContext ; remember the object this script is associated with
	sta ScriptObject,x
	tax ; x = object
	iny
	lda (zpScript),y
	pha
	lda #2
	jsr AddScript
	pla
	jmp ShowObject
}

ScriptSetAnim:
{
	ldy ScriptContext
	ldx ScriptObject,y ; anim slot is same as object slot for objects
	ldy #0
	lda (zpScript),y
	pha
	iny
	lda (zpScript),y
	tay
	lda #2
	jsr AddScript
	pla
	; a(lo) / y(hi) animation
	; x is animation slot
	jmp SetAnim
}

ScriptSetPos:
{
	ldy ScriptContext
	ldx ScriptObject,y
	ldy #0
	lda (zpScript),y ; x lo
	pha
	iny
	lda (zpScript),y ; x hi
	pha
	iny
	lda (zpScript),y ; y
	tay
	lda #3
	jsr AddScript
	pla
	lsr
	pla
	ror ; x = object index, a = x/2, C = x lo bit, y = y
	jmp SetObjectPos
}

ScriptSetColor:
{
	ldy ScriptContext
	ldx ScriptObject,y
	ldy #0
	lda (zpScript),y ; x lo
	jsr IncScript
	jmp SetObjectColor
}

ScriptSetColorConditional:
{
	php
	ldy ScriptContext
	ldx ScriptObject,y
	lda #0
	rol ; 1 if C
	tay
	lda (zpScript),y ; x lo
	jsr SetObjectColor
	lda #2
	jsr AddScript
	plp
	rts
}


ScriptCheckHover:
{
	ldx #0
	{
		lda CursorX+1
		lsr
		lda CursorX
		ror
		ldy #0
		cmp (zpScript),y	; a >= left ? 
		bcc %
		iny
		cmp (zpScript),y	; a < right ?
		bcs %
		lda CursorY
		iny
		cmp (zpScript),y	; a >= top ?
		bcc %
		iny
		cmp (zpScript),y	; a < bottom ?
		bcs %
		inx				 ; return C
	}
	lda #4
	jsr AddScript ; does not change x
	txa ; x = 1 -> return C
	lsr
	rts
}

ScriptCheckAction:
{
    ldy #0
    lda (zpScript),y
    jsr IncScript
    {
        cmp ActiveAction ; C set on equal or higher
        beq %
        clc
    }
    rts
}

ScriptCheckClick:
{
    lda GameMouseClick
    lsr
    lda #0
    sta GameMouseClick
    rts
}

ScriptWaitClick:
{
    lda GameMouseClick
    lsr
    lda #0
    sta GameMouseClick
    {
        bcs %
        inc ScriptDone
        ldx ScriptContext
        sec
        lda zpScript
        sbc #1
        sta ScriptCurrLo,x
        lda zpScript+1
        sbc #0
        sta ScriptCurrHi,x
    }
    rts
}

ScriptWait:
{
	ldx ScriptContext
	ldy #0
	lda (zpScript),y
    sta ScriptWaitFrames,x
    jsr IncScript
    lda zpScript
    sta ScriptCurrLo,x
    lda zpScript+1
    sta ScriptCurrHi,x
    inc ScriptDone
    rts
}

ScriptShowText:
{
    ; text in zpSrc
    ; color in a
    ; len in x
    ; does not change zpLocal
    jsr ClearTextArea
    ldy #0
    lda (zpScript),y ; text lo
    sta zpSrc
    iny
    lda (zpScript),y ; text hi
    sta zpSrc+1
    {
        beq %
        iny
        lda (zpScript),y ; length
        tax
        iny
        lda (zpScript),y ; color
        jsr DrawText
    }
    lda #4
    jmp AddScript
}

ScriptWalkPlayerToScript:
{
    ldy #0
    lda (zpScript),y
    tax
    iny
    lda (zpScript),y
    jsr ForcePlayerWalkToX
    ldy #2
    lda (zpScript),y
    tax
    iny
    lda (zpScript),y
    jsr SetScriptOnPlayerWalkDone
    lda #4
    jmp AddScript
}

ScriptLockPlayer:
{
    ldy #0
    lda (zpScript),y
    jsr IncScript
    jmp SetPlayerInputLock
}

ScriptColorArea:
{
    ldy #0
    lda (zpScript),y
    sta zpDst
    iny
    lda (zpScript),y
    sta zpDst+1
    iny
    lda (zpScript),y
    pha
    iny
    lda (zpScript),y
    tax
    iny
    lda (zpScript),y
    tay
    pla
    jsr ColorScreenArea
    lda #5
    jmp AddScript
}

ScriptShowItemSelector:
{
    ldy #0
    lda (zpScript),y
    sta zpSrc
    iny
    lda (zpScript),y
    sta zpSrc+1
    jsr DrawItemSelector
    lda #2
    jmp AddScript
}

ScriptCheckHoldItem:
{
    ldy #0
    lda (zpScript),y
	jsr IncScript
	{
		cmp InventoryDrop
		beq %
		cmp InventoryDragType
		beq %
		clc
	}
	rts
}

ScriptCheckDropItem:
{
    ldy #0
    lda (zpScript),y
	jsr IncScript
	cmp InventoryDrop
	{
		beq %
		clc
	}
	rts
}

ScriptMixCauldron:
{
	jmp MixItemsIntoCauldron
}

ScriptSetPlayerState:
{
	ldy #0
	lda (zpScript),y
	jsr IncScript
	jmp SetPlayerState
}

ScriptFillBottleFromCauldron:
{
	jmp FillBottleFromCauldron
}

ScriptExchangeItem:
{
	ldy #0
	lda (zpScript),y
	tax
	iny
	lda (zpScript),y
	jsr ExchangeInventoryItem
	lda #2
	jmp AddScript
}

ScriptAddInventory:
{
	ldy #0
	lda (zpScript),y
	jsr AddInventoryItem
	jmp IncScript
}

ScriptCheckDanceBull:
{
	{
		lda PlayerPosX+2
		bne %
		lda PlayerPosX+1
		cmp #182
		bcc %
		cmp #215
		bcs %
		jsr GetPlayerState
		cmp #State.Dancing
		bne %
		lda ObjectColor+1
		cmp #2
		bne %
		sec
		rts
	}
	clc
	rts
}


const MAX_CURRENT_SCRIPTS = 12

SECTION BSS, bss

ScriptDone:
	ds 1

ScriptCount:
	ds 1 ; number of scripts currently running

ScriptContext:
	ds 1 ; current script index

ScriptDisabled:
	ds MAX_CURRENT_SCRIPTS

ScriptWaitFrames:
    ds MAX_CURRENT_SCRIPTS

ScriptCurrLo:
	ds MAX_CURRENT_SCRIPTS

ScriptCurrHi:
	ds MAX_CURRENT_SCRIPTS

ScriptObject: ; save the object so scripts don't need to pass it in for each change
	ds MAX_CURRENT_SCRIPTS 

ScriptFlags:	; note: part of save game (move to save game section if implemented)
	ds 256>>3   ; 1 bit per flag, up to 256 flags