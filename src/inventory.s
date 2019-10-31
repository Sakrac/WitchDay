; player inventory tracking and display

XDEF InitInventory
XDEF UpdateInventory
XDEF ExchangeInventoryItem
XDEF AddInventoryItem
XDEF DrawInventory

XDEF InventoryDragType
XDEF InventoryDrop

XREF CursorY
XREF CursorX
XREF GameMouseClick
XREF GameHoldButton

include inventory.i
include zeropage.i
include memmap.i

SECTION Code, code

; check if interacting with inventory
UpdateInventory:
{
	{
		lda #-1
		sta InventoryDrop
		lda InventoryDrag
		bmi %
		ldx GameHoldButton
		bne %
		lda InventoryDragType
		sta InventoryDrop
		ldy #15
		ldx #20*3+2
		lda #0
		{
			sta VRAM + (Cursor_SPR<<6),x
			dex
			sta VRAM + (Cursor_SPR<<6),x
			dex
			dex
			dey
			bpl !
		}
		sty InventoryDrag
		sty InventoryDragType
		rts
	}

	{
		lda GameMouseClick
		beq .ret
		lda CursorY
		cmp #22*8
		bcc .ret
		cmp #24*8
		bcc .ok
.ret	rts
.ok		sec
		lda CursorX
		sbc #22*8
		tax
		lda CursorX+1
		sbc #0
		bcc %
		lda #0
		sta GameMouseClick
		txa	; a is leftmost inventory item
		ldx #5
		{
			cmp #24
			bcs .next
			cmp #16
			bcs .outside
			bcc %
.next		sec
			sbc #24
			dex
			bpl !
		}
		cpx InventoryCount
		bcs .outside

		stx InventoryDrag

		lda Inventory,x
		sta InventoryDragType
		pha
		tax
		lda InventoryChars,x
		; 32 bytes
		asl
		rol zpSrc+1
		asl
		rol zpSrc+1
		asl
		rol zpSrc+1
		asl
		rol zpSrc+1
		asl
		rol zpSrc+1
		clc
		adc #<InventoryGraphics
		sta zpSrc
		lda zpSrc+1
		and #$1f
		adc #>InventoryGraphics
		sta zpSrc+1
		{
			zpLocal .zpSrc2
			clc
			lda zpSrc
			adc #16
			sta .zpSrc2
			lda zpSrc+1
			adc #0
			sta .zpSrc2+1
			ldy #15
			ldx #20*3+2
			{
				lda (.zpSrc2),y
				sta VRAM + (Cursor_SPR<<6),x
				dex
				lda (zpSrc),y
				sta VRAM + (Cursor_SPR<<6),x
				dex
				dex
				dey
				bpl !
			}
		}
		pla
.outside
	}
	rts
}


InitInventory:
{
	; starting the game the player has a broom and an empty bottle
	lda #2
	sta InventoryCount
	lda #InventoryItem.Broom
	sta Inventory
	lda #InventoryItem.EmptyBottle
	sta Inventory+1

	lda #-1
	sta InventoryDrag
	sta InventoryDragType
	sta InventoryDrop

if 0
; but for now add more things
	lda #6
	sta InventoryCount
	lda #InventoryItem.FullBottleGrow
	sta Inventory+2
	lda #InventoryItem.FullBottleBarkEar
	sta Inventory+3
	lda #InventoryItem.Apple
	sta Inventory+4
	lda #InventoryItem.Cake
	sta Inventory+5
endif
	rts
}

; a = item
AddInventoryItem:
{
	{
		ldy InventoryCount
		{
			cpy #MAX_INVENTORY
			bcc %
			rts
		}
		beq %
		dey
		{
			{
				cmp Inventory,y
				bne %
				rts ; item already exists
			}
			dey
			bpl !
		}
	}
	ldy InventoryCount
	sta Inventory,y
	inc InventoryCount
	jmp DrawInventory
}

; a = original item, x = new item
ExchangeInventoryItem:
{
	{
		ldy InventoryCount
		bne %
		rts
	}
	dey
	{
		cmp Inventory,y
		beq %
		dey
		bpl !
		rts ; original item was not found
	}
	txa
	sta Inventory,y
} ; FALLTHROUGH
DrawInventory:
{
	zpUtility .zpScrn.w
	zpUtility .zpCol.w
	zpUtility .zpFontChar
	lda #<(InventoryFirst * 8 + GameFont)
	sta zpDst
	lda #>(InventoryFirst * 8 + GameFont)
	sta zpDst+1
	lda #<(GameScreen + InventoryScreenOffs)
	sta .zpScrn
	sta .zpCol
	lda #>(GameScreen + InventoryScreenOffs)
	sta .zpScrn+1
	lda #>(ColorRAM + InventoryScreenOffs)
	sta .zpCol+1

	lda #InventoryFirst
	sta .zpFontChar

	ldx #MAX_INVENTORY-1
	{
		ldy #0
		clc
		lda .zpFontChar
		sta (.zpScrn),y
		adc #1
		ldy #40
		sta (.zpScrn),y
		adc #1
		ldy #1
		sta (.zpScrn),y
		adc #1
		ldy #41
		sta (.zpScrn),y
		adc #1
		sta .zpFontChar

		cpx InventoryCount
		bcc .hasItem
		ldy #31
		lda #0
		{
			sta (zpDst),y
			dey
			bpl !
		}
		bmi .next
.hasItem
		txa
		pha
		lda Inventory,x
		asl
		tax
		ldy #0
		lda InventoryColor,x
		sta (.zpCol),y
		iny
		sta (.zpCol),y
		lda InventoryColor+1,x
		ldy #40
		sta (.zpCol),y
		iny
		sta (.zpCol),y
		pla
		tax

		ldy Inventory,x
		lda InventoryChars,y
		asl
		rol zpSrc+1
		asl
		rol zpSrc+1
		asl
		rol zpSrc+1
		asl
		rol zpSrc+1
		asl
		rol zpSrc+1
		clc
		adc #<InventoryGraphics
		sta zpSrc
		lda zpSrc+1
		and #$1f
		adc #>InventoryGraphics
		sta zpSrc+1
		ldy #31
		{
			lda (zpSrc),y
			sta (zpDst),y
			dey
			bpl !
		}
.next	clc
		lda .zpScrn
		adc #3
		sta .zpScrn
		sta .zpCol
		{
			bcc %
			inc .zpScrn+1
			inc .zpCol+1
		}
		clc
		lda zpDst
		adc #32
		sta zpDst
		{
			bcc %
			inc zpDst+1
		}
		dex
		bmi %
		jmp !
	}
	rts
}

InventoryChars:
{
	dc.b InventoryArt.Broom 		; Broom
	dc.b InventoryArt.EmptyBottle 	; Empty Bottle
	dc.b InventoryArt.FullBottle 	; Bottle with Grow
	dc.b InventoryArt.FullBottle 	; Bottle with Bark Ear
	dc.b InventoryArt.Apple 		; Apple
	dc.b InventoryArt.Cake 			; Poison Apple Cake without Raisins
	dc.b InventoryArt.Key 			; Key
}

InventoryColor:
{
	dc.b 9, 9	; Broom
	dc.b 0, 0	; Empty Bottle
	dc.b 0, 5	; Bottle with Grow
	dc.b 0, 6	; Bottle with Bark Ear
	dc.b 2, 2	; Apple
	dc.b 8, 9	; Poison Apple Cake without Raisins
	dc.b 9, 9	; Key
}

InventoryGraphics:
	incbin "../bin/InventoryAssets.bin"

SECTION BSS, bss

InventoryCount:
	ds 1

InventoryDrag:
	ds 1	; index of inventory item being dragged

InventoryDragType:
	ds 1	; type of inventory item being dragged

InventoryDrop:
	ds 1	; type of inventory item dropped now

Inventory:
	ds MAX_INVENTORY