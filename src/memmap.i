const VRAM = $4000
const VRAM_SET = 2 ; 0:$c000, 1:$8000, 2:$4000, 3:$0000
const ColorRAM = $d800

// 
const GameFont = VRAM
const GameScreen = VRAM + $800

const NumTextFontChars = 68
const NumInventoryChars = 6 * 4 ; max 6 items in inventory

const InventoryFirst = NumTextFontChars
const MapCharFirst = InventoryFirst + NumInventoryChars

// sprite indices
const Player_SPR = $c00>>6	; do sprites in idx space instead 
const Cursor_SPR = Player_SPR + 1
const CursorDrag_SPR = Cursor_SPR + 1 ; show next to cursor while dragging objects
const Object_SPR = CursorDrag_SPR + 1 ; in-game objects for each screen, possibly up to 6 allowed? maybe raster splitting for flying objects?

const BitReverse = $fe00