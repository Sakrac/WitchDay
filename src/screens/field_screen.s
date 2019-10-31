	org $8000

	// size of char data
	dc.b CharData_Size>>3

	// 500 bytes of color data
	incbin "../../bin/gamelayout.col"

	// 100 bytes of screen map
	incbin "../../bin/gamelayout.scr"

CharData:
	incbin "../../bin/gamelayout.chr"
const CharData_Size = * - CharData


