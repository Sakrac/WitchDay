; information for each screen
;	* graphics
;	* scripts (handles game objects on screen)
;	* player start point based on where you came from

XDEF SetupScreen
XDEF CheckPlayerScreen
XDEF ColorScreenArea

XREF FieldScreen
XREF WitchHouseScreen

XREF ClearAllObjects

XREF ClearAllScripts
XREF AddScreenScript
XREF RunAllScripts		; Update all scripts

XREF SetPlayerPosX
XREF GetPlayerPosX
XREF SetPlayerPosY
XREF SetPlayerInputLock

XREF DrawText
XREF SetClearTextOnClick
XREF DrawInventory
XREF DrawActions

XREF decrunchFrom

include zeropage.i
include game.i
include memmap.i

SECTION Code, code

ScreenScripts:
	dc.w FieldScreen	; room 0 = field
	dc.w WitchHouseScreen

InitScreens:
{
	lda #0
	sta EnteredFrom
	sta CurrentScreen
	jsr SetPlayerInputLock
	rts
}

; a = x lo, x = x hi
CheckPlayerScreen:
{
	jsr GetPlayerPosX

	zpLocal .zpScreen.w

	pha
	lda CurrentScreen
	asl
	tay
	lda ScreenScripts,y
	sta .zpScreen
	lda ScreenScripts+1,y
	sta .zpScreen+1

	ldy #ScreenSetup.LeftEdge
	pla
	{
		pha
		cmp (.zpScreen),y
		txa
		iny
		sbc (.zpScreen),y
		pla
		bcs %
		; player is left of left edge
		{
			ldy #ScreenSetup.LeftNextScreen
			lda (.zpScreen),y
			bmi %
			ldy #1 ; entering next screen on the right side
			sty EnteredFrom
			jmp SetupScreen
		}
		ldy #ScreenSetup.LeftEdgeText
		lda (.zpScreen),y
		sta zpSrc
		iny
		lda (.zpScreen),y
		sta zpSrc+1
		{
			beq %
			iny
			lda (.zpScreen),y
			tax
			lda #0 ; black for generic messages
			jsr DrawText
			jsr SetClearTextOnClick
		}

		ldy #ScreenSetup.LeftEdge
		clc
		lda (.zpScreen),y
		adc #2
		pha
		iny
		lda (.zpScreen),y
		adc #0
		tax
		pla
		ldy #0 ; face right
		jmp SetPlayerPosX ; 
	}
	{
		ldy #ScreenSetup.RightEdge
		cmp (.zpScreen),y
		pha
		txa
		iny
		sbc (.zpScreen),y
		pla
		bcc %
		; player is right of right edge
		{
			ldy #ScreenSetup.RightNextScreen
			lda (.zpScreen),y
			bmi %
			ldy #0 ; entering next screen on the right side
			sty EnteredFrom
			jmp SetupScreen
		}
		ldy #ScreenSetup.RightEdgeText
		lda (.zpScreen),y
		sta zpSrc
		iny
		lda (.zpScreen),y
		sta zpSrc+1
		{
			beq %
			iny
			lda (.zpScreen),y
			tax
			lda #0 ; black for generic messages
			jsr DrawText
			jsr SetClearTextOnClick
		}

		ldy #ScreenSetup.RightEdge
		sec
		lda (.zpScreen),y
		sbc #2
		pha
		iny
		lda (.zpScreen),y
		sbc #0
		tax
		pla
		ldy #1 ; face left
		jmp SetPlayerPosX ; 
	}
	rts
}

; a = screen #
SetupScreen:
{
	zpLocal .zpScripts.w
	zpLocal .zpIndex

	sta CurrentScreen

	pha
	; decrunch screen graphics
	asl
	tax
	lda ScreenScripts,x
	sta .zpScripts
	lda ScreenScripts+1,x
	sta .zpScripts+1
	ldy #1
	lda (.zpScripts),y
	tax
	dey
	lda (.zpScripts),y
	jsr decrunchFrom
	jsr ShowScreen

	jsr ClearAllObjects
	jsr ClearAllScripts
	pla
	pha

	asl
	tax
	lda ScreenScripts,x
	sta .zpScripts
	lda ScreenScripts+1,x
	sta .zpScripts+1

	ldy #ScreenSetup.StartHeight
	lda (.zpScripts),y
	jsr SetPlayerPosY

	clc ; facing right
	ldy #ScreenSetup.LeftStartEdge
	{
		lda EnteredFrom
		beq %
		ldy #ScreenSetup.RightStartEdge
		sec
	}
	lda (.zpScripts),y
	pha
	iny
	lda (.zpScripts),y
	tax
	lda #0
	rol
	tay
	pla
	jsr SetPlayerPosX

	pla

	asl
	tax
	lda ScreenScripts,x
	sta .zpScripts
	lda ScreenScripts+1,x
	sta .zpScripts+1

	ldy #ScreenSetup.bytes
	{
		lda (.zpScripts),y
		iny
		tax
		lda (.zpScripts),y
		beq %
		iny
		sty .zpIndex
		jsr AddScreenScript
		ldy .zpIndex
		bne !
	}

	lda #0
	jsr SetPlayerInputLock

	jsr DrawInventory	; redraw inventory on each screen
	jsr DrawActions
	jsr RunAllScripts	; scripts should run once before game start to set things up

	rts
}

; zpDst = color address
; x = width, y = height, a = color
ColorScreenArea:
{
	zpUtility .zpRows
	zpUtility .zpColumns
	sty .zpRows
	stx .zpColumns
	{
		ldy .zpColumns
		{
			dey
			sta (zpDst),y
			bne !
		}
		pha
		clc
		lda zpDst
		adc #40
		sta zpDst
		{
			bcc %
			inc zpDst+1
		}
		pla
		dec .zpRows
		bne !
	}
	rts
}


GraphicsStart = $8000
ShowScreen:
{
	; $8000
	; 1 byte = number of chars in char data
	; 500 bytes of color data
	; 1000 bytes of screen map
	; char data

	; hide the map while copying chars
	ldx #0
	lda #15
	{
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $db00,x
	}

	lda GraphicsStart
	eor #$ff
	clc
	adc #1 ; this is the start char

	zpLocal .zpFirstChar

	; copy chars
	sta .zpFirstChar
	asl
	rol zpDst+1
	asl
	rol zpDst+1
	asl
	rol zpDst+1
	sta zpDst
	lda zpDst+1
	and #7
	ora #>GameFont
	sta zpDst+1
	lda #<(GraphicsStart + 1 + 500 + 1000)
	sta zpSrc
	lda #>(GraphicsStart + 1 + 500 + 1000)
	sta zpSrc+1
	; copy 1 char at a time, not performance critical
	ldx GraphicsStart
	{
		ldy #7
		{
			lda (zpSrc),y
			sta (zpDst),y
			dey
			bpl !
		}
		clc
		lda zpSrc
		adc #8
		sta zpSrc
		{
			bcc %
			inc zpSrc+1
		}
		clc
		lda zpDst
		adc #8
		sta zpDst
		{
			bcc %
			inc zpDst+1
		}
		dex
		bne !
	}

	; copy screen
	lda #<(GraphicsStart + 1 + 500)
	sta zpSrc
	lda #>(GraphicsStart + 1 + 500)
	sta zpSrc+1
	lda #<GameScreen
	sta zpDst
	lda #>GameScreen
	sta zpDst+1
	ldx #4
	{
		ldy #0
		{
			lda (zpSrc),y
			{
				beq %
				clc
				adc .zpFirstChar
			}
			sta (zpDst),y
			iny
			cpy #250
			bcc !
		}
		clc
		lda zpSrc
		adc #250
		sta zpSrc
		{
			bcc %
			inc zpSrc+1
		}
		clc
		lda zpDst
		adc #250
		sta zpDst
		{
			bcc %
			inc zpDst+1
		}
		dex
		bne !
	}
	lda #<(GraphicsStart + 1)
	sta zpSrc
	lda #>(GraphicsStart + 1)
	sta zpSrc+1
} ; fallthrough
; src in zpSrc
; will overlap end of color ram a bit but doesn't matter
Copy_Colors:
{
	zpLocal .zpLeft
	lda #4
	sta .zpLeft
	lda #>ColorRAM
	sta .trg1+2
	sta .trg2+2
	ldx #0
	ldy #0
.loop
	lda (zpSrc),y
	iny
	{
		bne %
		inc zpSrc+1
	}
.trg1 
	sta ColorRAM,x
	inx
	lsr
	lsr
	lsr
	lsr
.trg2
	sta ColorRAM,x
	inx
	bne .loop
	inc .trg1+2
	inc .trg2+2
	dec .zpLeft
	bne .loop
	rts
}

SECTION BSS, bss

CurrentScreen:
	ds 1

EnteredFrom:
	ds 1 ; 0 is left side, 1 is right side