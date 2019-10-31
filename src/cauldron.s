; mixing logic for the cauldron

XDEF MixItemsIntoCauldron
XDEF FillBottleFromCauldron

XREF ItemSelectorOn
XREF ItemSelection
XREF DrawText
XREF ClearTextArea
XREF SetClearTextOnClick
XREF ExchangeInventoryItem


include zeropage.i
include game.i
include inventory.i

SECTION Code, code

MixItemsIntoCauldron:
{
	{
		zpLocal .zpMask.w
		lda #PotionID.Failure
		sta CauldronPotion

		lda ItemSelectorOn
		cmp #SelectorID.Ingredients
		bne %

		lda #0
		sta .zpMask
		sta .zpMask+1

		ldx #IngredientID.Count-1
		{
			lda ItemSelection,x
			lsr
			rol .zpMask
			rol .zpMask+1
			dex
			bpl !
		}
		{
			lda .zpMask
			bne %
			lda .zpMask
			bne %
			jsr ClearTextArea
			lda #<EmptyPotionName
			sta zpSrc
			lda #>EmptyPotionName
			sta zpSrc+1
			lda #9
			ldx #EmptyPotionNameLen
			jmp DrawText
		}

		ldx #(PotionID.NumPotions-1)*2
		{
			{
				lda .zpMask
				cmp ValidPotions,x
				bne %
				lda .zpMask+1
				cmp ValidPotions+1,x
				bne %
				txa
				lsr
				clc
				adc #PotionID.AppleGrow
				sta CauldronPotion
				
				jsr ClearTextArea
				lda CauldronPotion
				tay
				sec
				sbc #PotionID.AppleGrow
				asl
				tax
				lda PotionNames,x
				sta zpSrc
				lda PotionNames+1,x
				sta zpSrc+1
				ldx PotionNameLens,y
				lda #2
				jsr DrawText
				jmp SetClearTextOnClick
			}
			dex
			dex
			bpl !
		}
	}
	jsr ClearTextArea
	lda #<BadPotionName
	sta zpSrc
	lda #>BadPotionName
	sta zpSrc+1
	lda #4
	ldx #BadPotionNameLen
	jmp DrawText
}

FillBottleFromCauldron:
{
	{
		lda CauldronPotion
		ldx #InventoryItem.FullBottleGrow
		cmp #PotionID.AppleGrow
		beq %
		inx
		cmp #PotionID.BarkEar
		beq %
		rts
	}
	lda #InventoryItem.EmptyBottle
	jmp ExchangeInventoryItem
}


ValidPotions:
	; AppleGrow
	dc.w (1<<IngredientID.LarvaeHusk) | (1<<IngredientID.AppleStem) | (1<<IngredientID.FrogFlatus)
	; Bark-Ear
	dc.w (1<<IngredientID.DogsBreath) | (1<<IngredientID.ChickenBits)

PotionNames:
	dc.w AppleGrowName
	dc.w BarkEarName

PotionNameLens:
	dc.b AppleGrowNameLen
	dc.b BarkEarNameLen

AppleGrowName:
	TEXT [FontOrder] "Mixed up AppleGrow potion"
const AppleGrowNameLen = * - AppleGrowName

BarkEarName:
	TEXT [FontOrder] "Created some Bark Ear potion"
const BarkEarNameLen = * - BarkEarName

EmptyPotionName:
	TEXT [FontOrder] "First pick ingredients from the cabinet"
const EmptyPotionNameLen = * - EmptyPotionName

BadPotionName:
	TEXT [FontOrder] "Mixed up something rotten and foul.."
const BadPotionNameLen = * - BadPotionName


SECTION BSS, bss

; set to something if player has successfully mixed a potion
CauldronPotion:
	ds 1
