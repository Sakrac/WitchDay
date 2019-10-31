; zero page stuff
pool zpVars $40-$ff
zpVars pool zpLocal 8		; common usage for temporary zero page
zpVars pool zpUtility 8		; utility functions that may be called from functions using zpLocal
zpVars pool zpInterrupt 8	; reserved for interrupts
zpVars zpSrc.w ; source for copying etc. used to pass arguments into functions
zpVars zpDst.w ; destination for copying etc. used to pass arguments into functions
zpVars zpScript.w ; current script location
zpVars zpSoundEvent.w ; 2 bytes temp zero page (BDoing)
zpVars zpSoundChannel ; 1 byte temp zero page (BDoing)
