;XDEF Spr_Boy_Sad
;XDEF Spr_Bull_Idle
XDEF Spr_Cursor
XDEF Player_Anim_Idle
XDEF Player_Anim_Walk
XDEF Player_Anim_Dance
XDEF Player_Anim_Cauldron

; put the data in code for now
SECTION Code, code

; Player Animation
Player_Anim_Idle:
	dc.w Spr_Witch_Walk
	dc.b 21, 2
	dc.b 0, 255
	dc.b -1

Player_Anim_Walk:
	dc.w Spr_Witch_Walk
	dc.b 21, 2
	dc.b 0, 6
	dc.b 1, 6
	dc.b 2, 6
	dc.b 3, 6
	dc.b 4, 6
	dc.b -1

Player_Anim_Dance:
	dc.w Spr_Witch_Dance
	dc.b 21, 2
	dc.b 0, 8
	dc.b 1, 8
	dc.b 2, 30
	dc.b 1, 8
	dc.b 0, 8
	dc.b 1, 8
	dc.b 2, 8
	dc.b 1, 8
	dc.b 0, 30
	dc.b 1, 8
	dc.b 0, 8
	dc.b 1, 8
	dc.b 2, 30
	dc.b 1, 8
	dc.b 0, 8
	dc.b 1, 8
	dc.b 2, 8
	dc.b 1, -1
	dc.b -1

Player_Anim_Cauldron:
	dc.w Spr_Witch_Cauldron
	dc.b 21, 2
	dc.b 0, 10
	dc.b 1, 10
	dc.b 0, 8
	dc.b 1, 8
	dc.b 0, 6
	dc.b 1, 6
	dc.b 0, 4
	dc.b 1, 4
	dc.b 0, -1
	dc.b -1

Spr_Witch_Walk: ; 2x21x5
	incbin "../bin/walk.bin"

Spr_Witch_Dance: ; 2x21x3
	incbin "../bin/dance.bin"

Spr_Witch_Cauldron: ; 2x21x3
	incbin "../bin/cauldron.bin"

Spr_Cursor: ; 1x21
	incbin "../bin/cursor.bin"

