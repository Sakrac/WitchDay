	org $8000

	// size of char data
	dc.b CharData_Size>>3

	// 500 bytes of color data
	incbin "../../bin/witchhouse.col"

	// 100 bytes of screen map
	incbin "../../bin/witchhouse.scr"

CharData:
	incbin "../../bin/witchhouse.chr"
const CharData_Size = * - CharData


