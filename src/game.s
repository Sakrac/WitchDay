; global gameplay stuff

XDEF BeginGameFrame
XDEF GameMouseClick
XDEF GameHoldButton
XDEF SetPlayerInputLock
XDEF PlayerInputLocked

XREF RawSticks
XREF RawSticksHit

SECTION Code, code

SetPlayerInputLock:
{
	sta PlayerInputLocked
	rts
}

BeginGameFrame:
{
	ldx #0
	{
		lda RawSticksHit
		and #$10
		bne %
		inx
	}
	stx GameMouseClick
	ldx #0
	{
		lda RawSticks
		and #$10
		bne %
		inx
	}
	stx GameHoldButton
	rts
}


SECTION BSS, bss

GameMouseClick:
	ds 1

GameHoldButton:
	ds 1

PlayerInputLocked:
	ds 1