SECTION Code, code

include zeropage.i

; KEYBOARD MATRIX
;   |   38 |   30 |   28 |   20 |   18 |   10 |   8  |   0  |
;---+------+------+------+------+------+------+------+------+
; 0 | DOWN |  F5  |  F3  |  F1  |  F7  |RIGHT |  RET |  DEL |
; 1 |L-SHFT|   e  |   s  |   z  |   4  |   a  |   w  |   3  |
; 2 |   x  |   t  |   f  |   c  |   6  |   d  |   r  |   5  |
; 3 |   v  |   u  |   h  |   b  |   8  |   g  |   y  |   7  |
; 4 |   n  |   o  |   k  |   m  |   0  |   j  |   i  |   9  |
; 5 |   ,  |   @  |   :  |   .  |   -  |   l  |   p  |   +  |
; 6 |   /  |   ^  |   =  |R-SHFT| HOME |   ;  |   *  |   £  |
; 7 | STOP |   q  |  C=  |SPACE |   2  | CTRL |  <-  |   1  |
;---+------+------+------+------+------+------+------+------+
;   |  80  |  40  |  20  |  10  |   8  |   4  |   2  |   1  |
; KEYBOARD MASK

const MouseSupport = 1
const NumSticks = 2

XDEF ReadStick
XDEF InitStick

XREF BitShiftInv

XDEF MouseValid
XDEF MouseDelta
XDEF KeyboardBits
XDEF KeyboardBitsChange
XDEF RawSticks
XDEF RawSticksHit

; CALL FROM INTERRUPT - uses temp zero page reserved for active interrupt
ReadStick:
{
;	jsr ReadStickInt

if MouseSupport
	jsr ReadMouse
endif
	ldx #0
	stx $dc02
	stx $dc03
	lda $dc01 // read port1
	and #$1f
	sta IntSticks

	lda $dc00 // read port2
	sta IntSticks+1

	lda #$00	; Set to input
	sta $dc03	; Port B data direction register
	ldx #$ff	; Set to output
	stx $dc02	; Port A data direction register

	ldx #7
	{
		lda BitShiftInv,x ; ~(1<<x), KeyboardColumnMasks
		sta $dc00
		lda $dc01
		sta KeyboardBitsInt,x
		dex
		bpl !
	}

if MouseSupport
	; disable keyboard to read mouse
	lda #$e0
	sta $dc02
	lda #$c0
	sta $dc00

endif


	{
		inc StickHoldTime
		lda IntSticks+1
		cmp RawSticks+1
		beq %
		lda #0
		sta StickHoldTime
	}

	ldx #NumSticks - 1
	{
		lda RawSticks,x
		sta RawSticksPrev,x
		lda IntSticks,x
		sta RawSticks,x
		dex
		bpl !
	}

	ldx #7
	{
		lda KeyboardBitsInt,x
		pha
		ora KeyboardBits,x
		eor #$ff
		sta KeyboardBitsChange,x
		pla
		eor #$ff
		sta KeyboardBits,x
		dex
		bpl !
	}

KeysToInput:
	{
		zpInterrupt .zpInput
		lda KeyboardBits+7
		lsr
		lsr
		lsr
		rol .zpInput
		lda KeyboardBits+1
		lsr
		lsr
		php ; w, up
		lsr
		php ; a, left
		lda KeyboardBits+2
		lsr
		lsr
		lsr ; d, right
		rol .zpInput
		plp
		rol .zpInput
		lda KeyboardBits+1 ; LShift, fire
		asl
		asl
		asl
		rol .zpInput
		plp
		rol .zpInput
		lda #$1f
		and .zpInput
		eor #$ff
		and RawSticks+1
		sta RawSticks+1
	}

	ldx #NumSticks-1
	{
		lda RawSticks,x ; 0
		eor #$ff
		and RawSticksPrev,x ; 1
		eor #$ff
		sta RawSticksHit,x
		dex
		bpl !
	}
	rts
}


InitStick:
ClearInput:
{
	lda #0
	ldx #ClearButtonLen
	{
		dex
		sta InputBSSStart,x
		bne !
	}
	rts
}

if MouseSupport
; 1 Keep a variable for the position of the mouse and for the position of the pointer, in both (X and Y) directions.
; 2 Turn on the 4066 analog switches of your particular joystick port, to let the SID POT lines be connected to the joystick port. This can be done by selecting the PA6 or PA7 output of the CIA1 chip to '1', respectively (can be set in $dc00). If the POT lines were disconnected before, spend a 'lot of time'. Probably it's better to activate the SID POT outputs for a whole frame, then read mouse position first, handle keyboard (switch off SID POT if neccessary), and then re-activate the lines. It's needed for syncing SID and the 1351 together.
; 3 Read the POTX and POTY registers from the SID ($d419 / $d41a). Bit0 should be treated as noise, bit7 is a 'don't care'-bit. The remaining bits are the lowmost 6 bits of the current coordinates of the mouse.
; 4 Comparing the stored and the read position you can make a decision on the movement direction and the new position. Then modify the pointers by the difference you got. As last step, replace the old mouse position by the new one.
; 5 Repeat from 2.

ReadMouse:
{
	ldy SIDPotPrev
	lda $d419
	jsr PotValueCheck
	sty SIDPotPrev

	{
		ldx MouseValid
		beq %
		clc
		adc MouseDelta
		sta MouseDelta
	}

	ldy SIDPotPrev+1
	lda $d41a
	jsr PotValueCheck
	sty SIDPotPrev+1
	{
		ldx MouseValid
		beq %
		eor #$ff
		sec
		adc MouseDelta+1
		sta MouseDelta+1
	}

	lda #$ff
	sta MouseValid
	sta $dc02
	rts
}

PotValueCheck:
{
	zpInterrupt .zpOld
	zpInterrupt .zpNew
	sty .zpOld
	sta .zpNew

	sec
	sbc .zpOld
	and #$7f
	cmp #$40
	{
		bcs %
		lsr
		beq .checked
		ldy .zpNew
		rts
	}
	{
		cmp #$7f
		beq .checked
		lsr
		ora #$c0
		ldy .zpNew
		rts
	}
.checked
	lda #0
	rts
}
endif


SECTION BSS, bss

InputBSSStart:
IntSticks:
	ds NumSticks
RawSticksPrev:
	ds NumSticks
RawSticks:
	ds NumSticks
RawSticksHit:
	ds NumSticks

StickHoldTime:
	ds 1		; cleared when RawSticksHit & 0x1f changes, incremented otherwise

;WiggleHoldTime:
;	ds 1		; cleared when left, right changes, increased otherwise

KeyboardBitsInt:
	ds 8

DoubleClickTime:
	ds 3
if MouseSupport
MouseValid:
	ds 1
SIDPotPrev:
	ds 2
LastFrameMouse:
	ds 1
endif

;WiggleCount:
;	ds 1		; cleared when hold time > wiggleMaxTime,
;WiggleLastDir:	; which direction was held last?
;	ds 1

MouseDelta:
	ds 2
KeyboardBits:
	ds 8
KeyboardBitsChange:
	ds 8

ClearButtonLen = * - InputBSSStart

