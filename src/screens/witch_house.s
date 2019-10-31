include ../script.i
include ../memmap.i
include ../game.i
include ../inventory.i
include ../state.i
include ../zeropage.i

XDEF WitchHouseScreen

XREF SetObjectColor
XREF ClearTextArea
XREF DrawText

SECTION Code, code
WitchHouseScreen:
{
	; data (crunched)
	dc.w WitchHouseData

	dc.w 100 ; start x on left side
	dc.w 244 ; start x 

	dc.b 140

	; action for left edge
	dc.w 96; x pos of left edge
	dc.b -1
	dc.w 0 ; no text
	dc.b 0

	; action for right edge
	dc.w 256
	dc.b ScreenID.Field
	dc.w 0 ; no text
	dc.b 0

	; scripts begin here
	dc.w CauldronScript
	dc.w PotionsScript
	dc.w TrashScript
	dc.w DresserScript
	dc.w LibraryScript
	dc.w 0 ; end of scripts
}

SelectDress:
{	; a = item #
	; 0 -> 0, 1 -> 2, 2 -> 5
	tay
	lda .colors,y
	ldx #1
	; x = object #, a = color
	jsr SetObjectColor
	jmp ClearTextArea
.colors
	dc.b 0, 2, 5
}

SelectRecipe:
{
	pha
	jsr ClearTextArea
	pla
	tay
	ldx .recipeLen,y
	asl
	tay
	lda .recipes,y
	sta zpSrc
	lda .recipes+1,y
	sta zpSrc+1
	lda #0

; text in zpSrc
; color in a
; len in x
	jmp DrawText
.recipes
	dc.w AppleGrowRecipe
	dc.w BarkEarRecipe
.recipeLen
	dc.b AppleGrowRecipeLen
	dc.b BarkEarRecipeLen
}



CauldronScript:
{
.waitClick
	IfHoldingItem InventoryItem.Broom
	ThenGoto .checkUse
	IfHoldingItem InventoryItem.EmptyBottle
	ThenGoto .checkUse
.notHover
	ColorArea 16, 16, 1, 2, 0
	Yield .waitClick
.checkUse
	CheckHover 128, 136, 133, 140
	ThenGoto .checkClick
	Goto .notHover
.checkClick
	ColorArea 16, 16, 1, 2, 11
	IfDroppedItem InventoryItem.Broom
	ThenGoto .useCauldron
	IfDroppedItem InventoryItem.EmptyBottle
	ThenGoto .fillBottle
	Yield .waitClick
.useCauldron
	LockPlayerInput 1
	ScriptPlayerWalkTo 18*8, CauldronMixScript
	Yield .waitClick
.fillBottle
	LockPlayerInput 1
	ScriptPlayerWalkTo 18*8, FillBottleScript
	Yield .waitClick
}

CauldronMixScript:
{
	ForcePlayer State.Mixing
	PauseFor 50
	MixCauldron
	LockPlayerInput 0
	Disable
}

FillBottleScript:
{
	FillBottleFromCauldron
	LockPlayerInput 0
	Disable
}

PotionsScript:
{
.waitClick
	IfAction PlayerAction.Use
	ThenGoto .checkUse
.notHover
	ColorArea 17, 15, 2, 3, 4
	Yield .waitClick
.checkUse
	CheckHover 17*8, 19*8, 15*8, 17*8
	ThenGoto .checkClick
	Goto .notHover
.checkClick
	ColorArea 17, 15, 2, 3, 10
	CheckClick
	ThenGoto .usePotions
	Yield .waitClick
.usePotions
	ScriptPlayerWalkTo 18*8, PotionSelectorScript
	Yield .waitClick
}

PotionSelectorScript:
{
	ItemSelector PotionSelector
	Disable
}

TrashScript:
{
.waitClick
	IfHoldingItem InventoryItem.FullBottleGrow
	ThenGoto .checkUse
	IfHoldingItem InventoryItem.FullBottleBarkEar
	ThenGoto .checkUse
.notHover
	ColorArea 12, 17, 1, 1, 9
	Yield .waitClick
.checkUse
	CheckHover 94, 100, 133, 143
	ThenGoto .checkDrop
	Goto .notHover
.checkDrop
	ColorArea 12, 17, 1, 1, 10
	IfDroppedItem InventoryItem.FullBottleGrow
	ThenGoto .emptyBottleGrow
	IfDroppedItem InventoryItem.FullBottleBarkEar
	ThenGoto .emptyBottleBarkEar
	Yield .waitClick
.emptyBottleGrow
	InventoryExchange InventoryItem.FullBottleGrow InventoryItem.EmptyBottle
	Yield .waitClick
.emptyBottleBarkEar
	InventoryExchange InventoryItem.FullBottleBarkEar InventoryItem.EmptyBottle
	Yield .waitClick
}

DresserScript:
{
.waitClick
	IfAction PlayerAction.Use
	ThenGoto .checkUse
.notHover
	ColorArea 16, 11, 2, 2, 2
	Yield .waitClick
.checkUse
	CheckHover 129, 142, 92, 105
	Not
	ThenGoto .notHover
	ColorArea 16, 11, 2, 2, 9
	CheckClick
	ThenGoto .useDresser
	Yield .waitClick
.useDresser
	ItemSelector DressSelector
	Yield .waitClick
}

LibraryScript:
{
.waitClick
	IfAction PlayerAction.Use
	ThenGoto .checkUse
.notHover
	ColorArea 26, 11, 4, 3, 8
	Yield .waitClick
.checkUse
	CheckHover 208, 240, 88, 105
	Not
	ThenGoto .notHover
	ColorArea 26, 11, 4, 3, 9
	CheckClick
	ThenGoto .useDresser
	Yield .waitClick
.useDresser
	ItemSelector RecipeSelector
	Yield .waitClick
}

AppleGrowRecipe:	; 0123456789012345678901234567890123456789"
	TEXT [FontOrder] "Potion making any tree grow an apple:   "
	TEXT [FontOrder] "One huske of larvae                     "
	TEXT [FontOrder] "Air of anura, and stem of the fruit.    "
const AppleGrowRecipeLen = * - AppleGrowRecipe

BarkEarRecipe:	; 0123456789012345678901234567890123456789"
	TEXT [FontOrder] "Potion of the barking ear:              "
	TEXT [FontOrder] "Any part of chicken, breath of the dog"
const BarkEarRecipeLen = * - BarkEarRecipe

DressSelector:
	dc.w DresserTitle
	dc.b SelectorID.Clothes
	dc.b DressetTitleLen
	dc.w SelectDress
	dc.b 3
	dc.w BlackDress
	dc.b BlackDressLen
	dc.w RedDress
	dc.b RedDressLen
	dc.w GreenDress
	dc.b GreenDressLen

DresserTitle:		; 0123456789012345678901234567890123456789"
	TEXT [FontOrder] "Select an outfit:"
const DressetTitleLen = * - DresserTitle
BlackDress:
	TEXT [FontOrder] "Black Dress"
const BlackDressLen = * - BlackDress
RedDress:
	TEXT [FontOrder] "Red Dress"
const RedDressLen = * - RedDress
GreenDress:
	TEXT [FontOrder] "Green Dress"
const GreenDressLen = * - GreenDress


RecipeSelector:
	dc.w RecipeTitle
	dc.b SelectorID.Library
	dc.b RecipeTitleLen
	dc.w SelectRecipe
	dc.b 2
	dc.w AppleGrowName
	dc.b AppleGrowNameLen
	dc.w BarkEarName
	dc.b BarkEarNameLen

RecipeTitle:		; 0123456789012345678901234567890123456789"
	TEXT [FontOrder] "Witch's Library Of Recipes:"
const RecipeTitleLen = * - RecipeTitle

AppleGrowName:
	TEXT [FontOrder] "Apple Grow"
const AppleGrowNameLen = * - AppleGrowName

BarkEarName:
	TEXT [FontOrder] "Bark Ear"
const BarkEarNameLen = * - BarkEarName


PotionTitle:		; 0123456789012345678901234567890123456789"
	TEXT [FontOrder] "Select ingredients to mix in cauldron:"
const PotionTitleLen = * - PotionTitle

PotionDogBreath:
	TEXT [FontOrder] "DogsBreath"
const PotionDogBreathLen = * - PotionDogBreath

LarvaeHusk:
	TEXT [FontOrder] "Larvae Husk"
const LarvaeHuskLen = * - LarvaeHusk

ChickenBits:
	Text [FontOrder] "Chickenbits"
const ChickenBitsLen = * - ChickenBits

AppleStem:
	Text [FontOrder] "Apple Stem"
const AppleStemLen = * - AppleStem

FrogFlatus:
	Text [FontOrder] "Frog Flatus"
const FrogFlatusLen = * - FrogFlatus

PotionSelector:
	dc.w PotionTitle
	dc.b SelectorID.Ingredients ; id 1
	dc.b PotionTitleLen
	dc.w 0 ; no callback on item select
	dc.b IngredientID.Count ; 5 items
	dc.w PotionDogBreath
	dc.b PotionDogBreathLen
	dc.w LarvaeHusk
	dc.b LarvaeHuskLen
	dc.w ChickenBits
	dc.b ChickenBitsLen
	dc.w AppleStem
	dc.b AppleStemLen
	dc.w FrogFlatus
	dc.b FrogFlatusLen



	import c64 "../../bin/witch_house_screen.exo"
WitchHouseData: