XDEF BitShiftInv
XDEF BitIndex

SECTION Code, code

BitShiftInv:
	rept 8 { dc.b 255 - (1<<rept) }

BitIndex:
    rept 8 { dc.b 1<<rept }
