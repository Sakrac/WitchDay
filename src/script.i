enum SF { ; script flags
	BullLeft = 0,
	BoyGotCake,
	AppleGrown,
	AppleFallen,
	AppleTaken
}

enum PlayerAction { ; player actions
	Talk = 0,
	Eat,
	Dance,
	Use
}

enum ScriptCodes {
	YIELD = 0,
	GOTO = 1,
	GOTO_IF_TRUE = 2,
	DISABLE = 3,
	DISABLE_IF_TRUE = 4,
	NOT_COND = 5,
	CHECK_FLAG = 6,
	SET_FLAG = 7,
	CHECK_HOVER = 8,
	CHECK_ACTION = 9,
	CHECK_CLICK = 10
	CREATE_OBJECT = 11,
	SET_ANIM = 12,
	SET_POS = 13,
	SET_COLOR = 14,
	SET_COLOR_COND = 15,
	WAIT = 16,
	WAIT_CLICK = 17,
	SHOW_TEXT = 18,
	WALK_PLAYER = 19,
	LOCK_INPUT = 20,
	COLOR_AREA = 21,
	ITEM_SELECTOR = 22,
	CHECK_HOLD_ITEM = 23,
	CHECK_DROP_ITEM = 24,
	MIX_CAULDRON = 25,
	PLAYER_STATE = 26,
	BOTTLE_CAULDRON = 27,
	EXCHANGE_ITEM = 28,
	ADD_ITEM = 29,
	CHECK_BULL = 30
}

macro Yield( target ) {
	dc.b ScriptCodes.YIELD
	dc.b target - *
}

macro Goto( target ) {
	dc.b ScriptCodes.GOTO
	dc.b target - *
}

macro ThenGoto( target ) {
	dc.b ScriptCodes.GOTO_IF_TRUE
	dc.b target - *
}

macro Disable() {
	dc.b ScriptCodes.DISABLE
}

macro ThenDisable() {
	dc.b ScriptCodes.DISABLE_IF_TRUE
}

macro Not() {
	dc.b ScriptCodes.NOT_COND
}

macro IfFlag( flag ) {
	dc.b ScriptCodes.CHECK_FLAG
	dc.b flag
}

macro SetFlag( flag ) {
	dc.b ScriptCodes.SET_FLAG
	dc.b flag
}

macro CheckHover( left, right, top, bottom ) {
	dc.b ScriptCodes.CHECK_HOVER
	dc.b (left)/2, (right/2), top, bottom
}

macro CheckClick() { ; calling this will also consume the click!
	dc.b ScriptCodes.CHECK_CLICK
}

macro IfAction( action )
{
	dc.b ScriptCodes.CHECK_ACTION
	dc.b action
}

macro CreateObject( object, sprite ) {
	dc.b ScriptCodes.CREATE_OBJECT
	dc.b object, sprite
}

macro SetAnim( anim ) {
	dc.b ScriptCodes.SET_ANIM
	dc.w anim
}

macro SetObjectPos( x, y ) {
	dc.b ScriptCodes.SET_POS
	dc.w x
	dc.b y
}

macro SetObjectColor( color ) {
	dc.b ScriptCodes.SET_COLOR
	dc.b color
}

; sets color based on condition, preserves condition
macro SetObjectColorConditional( colorFalse, colorTrue ) {
	dc.b ScriptCodes.SET_COLOR_COND
	dc.b colorFalse, colorTrue
}

macro PauseFor( frames ) {
	dc.b ScriptCodes.WAIT
	dc.b frames
}

macro PauseUntilClick() {
	dc.b ScriptCodes.WAIT_CLICK
}

; shows some text
macro ScriptText( textRef, textLen, textCol ) {
	dc.b ScriptCodes.SHOW_TEXT
	dc.w textRef
	dc.b textLen, textCol
}

; make the player walk to a point and then run a script.
macro ScriptPlayerWalkTo( x, script ) {
	dc.b ScriptCodes.WALK_PLAYER
	dc.w x, script
}

macro LockPlayerInput( enable ) {
	dc.b ScriptCodes.LOCK_INPUT
	dc.b enable
}

macro ColorArea( x, y, width, height, col ) {
	dc.b ScriptCodes.COLOR_AREA
	dc.w x + y * 40 + ColorRAM
	dc.b col, width, height
}

macro ItemSelector( selector ) {
	dc.b ScriptCodes.ITEM_SELECTOR
	dc.w selector
}

macro IfHoldingItem( item ) {
	dc.b ScriptCodes.CHECK_HOLD_ITEM
	dc.b item
}

macro IfDroppedItem( item ) {
	dc.b ScriptCodes.CHECK_DROP_ITEM
	dc.b item
}

macro MixCauldron() {
	dc.b ScriptCodes.MIX_CAULDRON
}

macro ForcePlayer( state ) {
	dc.b ScriptCodes.PLAYER_STATE
	dc.b state
}

macro FillBottleFromCauldron() {
	dc.b ScriptCodes.BOTTLE_CAULDRON
}

macro InventoryExchange( original, new_item ) {
	dc.b ScriptCodes.EXCHANGE_ITEM
	dc.b new_item, original
}