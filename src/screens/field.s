include ../script.i
include ../memmap.i
include ../game.i
include ../inventory.i

XDEF FieldScreen

SECTION Code, code
FieldScreen:
{
	; data (crunched)
	dc.w FieldScreenData

	dc.w 40 ; start x on left side
	dc.w 276 ; start x on right side

	dc.b 144

	; action for left edge
	dc.w 24 ; x pos of left edge
	dc.b ScreenID.WitchHouse
	dc.w 0 ; no text
	dc.b 0 ; no text len

	; action for right edge
	dc.w 264
	dc.b -1
	dc.w SadBoyText ; put pointer here
	dc.b SadBoyTextLen

	; scripts begin here
	dc.w BullScript
	dc.w SadBoyScript
	dc.w TreeScript
	dc.w AppleScript
	dc.w 0 ; end of scripts
}

SadBoyText:
	TEXT [FontOrder] "I can't walk past this crying boy or my ears will shatter"
const SadBoyTextLen = * - SadBoyText

SadBoyExplain:		; 0123456789012345678901234567890123456789
	TEXT [FontOrder] "BOY: My parents won't let me have any   "
	TEXT [FontOrder] "     Poison Apple Cake.                 "
	TEXT [FontOrder] "     Because I'm too young to eat it."
const SadBoyExplainLen = * - SadBoyExplain

WitchExplayBoy:		; 0123456789012345678901234567890123456789
	TEXT [FontOrder] "WITCH: Of course you can't eat that kid!"
	TEXT [FontOrder] "It is made with apples, eggs, flour,    "
	TEXT [FontOrder] "brandy and raisins!                     "
	TEXT [FontOrder] "But maybe I can make you one without    "
	TEXT [FontOrder] "any raisins in it, I just need an apple."
const WitchExplayBoyLen = * - WitchExplayBoy

BullScript:
{
	IfFlag SF.BullLeft
	ThenDisable
	CreateObject 2, Object_SPR
	SetAnim Bull_Anim_Idle
	SetObjectPos 220, 138
	SetObjectColor 9
	Disable
}

SadBoyScript:
{
	IfFlag SF.BoyGotCake
	ThenDisable
	CreateObject 3, Object_SPR+1
	SetAnim Boy_Anim_Idle
	SetObjectPos 280, 144
.waitClick
	IfAction PlayerAction.Talk
	ThenGoto .checkTalk
	SetObjectColor 6
	Yield .waitClick
.checkTalk
	CheckHover 278, 284, 130, 142
	SetObjectColorConditional 6, 14
	ThenGoto .checkClick
	Yield .waitClick
.checkClick
	CheckClick
	ThenGoto .dialogue
	Yield .waitClick
.dialogue
	LockPlayerInput 1
	ScriptPlayerWalkTo 260, SadBoyTextScript
	Yield .waitClick
}

SadBoyTextScript:
{
	ScriptText SadBoyExplain, SadBoyExplainLen, 6
	PauseUntilClick
	ScriptText WitchExplayBoy, WitchExplayBoyLen, 0
	PauseUntilClick
	ScriptText 0, 0, 0
	LockPlayerInput 0
	Disable
}

TreeScript:
{
	IfFlag SF.AppleGrown
	ThenDisable
	IfFlag SF.BullLeft
	ThenDisable
.waitDropGrow
	IfHoldingItem InventoryItem.FullBottleGrow
	ThenGoto .checkUse
.notHover
	ColorArea 21, 12, 2, 5, 9
	Yield .waitDropGrow
.checkUse
	CheckHover 168, 184, 96, 140
	ThenGoto .checkDrop
	Goto .notHover
.checkDrop
	ColorArea 21, 12, 2, 5, 8
	IfDroppedItem InventoryItem.FullBottleGrow
	ThenGoto .useAppleGrow
	Yield .waitDropGrow
.useAppleGrow
	LockPlayerInput 1
	ScriptPlayerWalkTo 174, GrowAppleOnTreeScript
	Disable
}

GrowAppleOnTreeScript:
{
	IfFlag SF.AppleTaken
	ThenDisable
	InventoryExchange InventoryItem.FullBottleGrow InventoryItem.EmptyBottle
	LockPlayerInput 0
	SetFlag SF.AppleGrown
} ; FALLTHROUGH
AppleScript:
{
	IfFlag SF.AppleGrown
	Not
	ThenDisable
	IfFlag SF.AppleTaken
	ThenDisable
	CreateObject 4, Object_SPR+2
	SetAnim Apple_Anim_Idle
	SetObjectPos 148, 112
	SetObjectColor 2
.appleWait
	dc.b ScriptCodes.CHECK_BULL
	ThenGoto .bullDance
	Yield .appleWait
.bullDance
	SetFlag SF.AppleTaken
	dc.b ScriptCodes.ADD_ITEM, InventoryItem.Apple
	Disable
}

; eating grass
Bull_Anim_Idle:
	dc.w Spr_Bull_Idle
	dc.b 21, 3
	dc.b 0, 100
	dc.b 1, 100
	dc.b -1

Boy_Anim_Idle:
	dc.w Spr_Boy_Sad
	dc.b 15, 1
	dc.b 0, -1
	dc.b -1

Boy_Anim_Idle:
	dc.w Spr_Boy_Sad
	dc.b 15, 1
	dc.b 0, -1
	dc.b -1

Apple_Anim_Idle:
	dc.w Spr_Apple
	dc.b 8, 1
	dc.b 0, -1
	dc.b -1

Spr_Boy_Sad: ; 1x15
	incbin "../../bin/boy_sad.bin"
Spr_Bull_Idle: ; 3x21
	incbin "../../bin/bull_idle.bin"
Spr_Apple: ; 1x8
	incbin "../../bin/apple.bin"

	import c64 "../../bin/field_screen.exo"
FieldScreenData: