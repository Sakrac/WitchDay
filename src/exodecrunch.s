;-----------------------------------------------------------------------
; Exomizer decruncher for Witch Day -
;   This is a modified version of the original implementation, the
;   purpose of the modification is to assemble with the x65 assembler and
;   share more resources within Witch Day. To use Exomizer in a different
;   project please download an unmodified version from
;   https://bitbucket.org/magli143/exomizer/wiki/Home
;
; Original copyright and license notice follows
;-----------------------------------------------------------------------
;
; Copyright (c) 2002 - 2005 Magnus Lind.
;
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from
; the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
;   1. The origin of this software must not be misrepresented; you must not
;   claim that you wrote the original software. If you use this software in a
;   product, an acknowledgment in the product documentation would be
;   appreciated but is not required.
;
;   2. Altered source versions must be plainly marked as such, and must not
;   be misrepresented as being the original software.
;
;   3. This notice may not be removed or altered from any distribution.
;
;   4. The names of this software and/or it's copyright holders may not be
;   used to endorse or promote products derived from this software without
;   specific prior written permission.
;
; -------------------------------------------------------------------
; The decruncher jsr:s to the get_crunched_byte address when it wants to
; read a crunched byte. This subroutine has to preserve x and y register
; and must not modify the state of the carry flag.
; -------------------------------------------------------------------
;.import get_crunched_byte
; -------------------------------------------------------------------
; this function is the heart of the decruncher.
; It initializes the decruncher zeropage locations and precalculates the
; decrunch tables and decrunches the data
; This function will not change the interrupt status bit and it will not
; modify the memory configuration.
; -------------------------------------------------------------------
;.export decrunch

; -------------------------------------------------------------------
; if literal sequences is not used (the data was crunched with the -c
; flag) then the following line can be uncommented for shorter code.
;LITERAL_SEQUENCES_NOT_USED = 1
; -------------------------------------------------------------------
; zero page addresses used
; -------------------------------------------------------------------

include zeropage.i
DecrunchBegin:

const decrunch_table = $fffa - 156

XDEF decrunchFrom
XDEF decrunch

SECTION Code,code

zpUtility zp_len_lo
zpUtility zp_src_lo.w
zpUtility zp_bits_hi
zpUtility zp_bitbuf.t

const zp_src_hi = zp_src_lo + 1

const zp_dest_lo = zp_bitbuf + 1
const zp_dest_hi = zp_dest_lo + 1

const tabl_bi = decrunch_table
const tabl_lo = decrunch_table + 52
const tabl_hi = decrunch_table + 104

const LITERAL_SEQUENCES_NOT_USED = 0

; <Witch Day: comments left unmodified, code has been modified>
; -------------------------------------------------------------------
; no code below this comment has to be modified in order to generate
; a working decruncher of this source file.
; However, you may want to relocate the tables last in the file to a
; more suitable address.
; -------------------------------------------------------------------

get_crunched_byte:
{
	{
		lda decrunch_address+1
		bne %
		dec decrunch_address+2
	}
	dec decrunch_address+1
decrunch_address:
	lda $1234		; needs to be set correctly before
	rts				; decrunch_file is called.get_crunched_byte:
}

decrunchFrom:
{
	sta decrunch_address+1
	stx decrunch_address+2
} ; FALLTHROUGH

; -------------------------------------------------------------------
; jsr this label to decrunch, it will in turn init the tables and
; call the decruncher
; no constraints on register content, however the
; decimal flag has to be #0 (it almost always is, otherwise do a cld)
decrunch:
; -------------------------------------------------------------------
; init zeropage, x and y regs. (12 bytes)
;
	ldy #0
	ldx #3
	{
		jsr get_crunched_byte
		sta zp_bitbuf - 1,x
		dex
		bne !
	}

; -------------------------------------------------------------------
; calculate tables (50 bytes)
; x and y must be #0 when entering
;
nextone:
	inx
	tya
	and #$0f
	beq shortcut		; starta på ny sekvens

	txa					; this clears reg a
	lsr a				; and sets the carry flag
	ldx tabl_bi-1,y
	{
		rol a
		rol zp_bits_hi
		dex
		bpl !			; c = 0 after this (rol zp_bits_hi)
	}

	adc tabl_lo-1,y
	tax

	lda zp_bits_hi
	adc tabl_hi-1,y
shortcut:
	sta tabl_hi,y
	txa
	sta tabl_lo,y

	ldx #4
	jsr get_bits		; clears x-reg.
	sta tabl_bi,y
	iny
	cpy #52
	bne nextone
	ldy #0
	beq begin
; -------------------------------------------------------------------
; get bits (29 bytes)
;
; args:
;   x = number of bits to get
; returns:
;   a = #bits_lo
;   x = #0
;   c = 0
;   z = 1
;   zp_bits_hi = #bits_hi
; notes:
;   y is untouched
; -------------------------------------------------------------------
get_bits:
	lda #$00
	sta zp_bits_hi
	cpx #$01
	bcc bits_done
bits_next:
	lsr zp_bitbuf
	bne ok
	pha
literal_get_byte:
	jsr get_crunched_byte
	bcc literal_byte_gotten
	ror a
	sta zp_bitbuf
	pla
ok:
	rol a
	rol zp_bits_hi
	dex
	bne bits_next
bits_done:
	rts
; -------------------------------------------------------------------
; main copy loop (18(16) bytes)
;
copy_next_hi:
	dex
	dec zp_dest_hi
	dec zp_src_hi
copy_next:
	dey
if !LITERAL_SEQUENCES_NOT_USED
	bcc literal_get_byte
endif
	lda (zp_src_lo),y
literal_byte_gotten:
	sta (zp_dest_lo),y
copy_start:
	tya
	bne copy_next
begin:
	txa
	bne copy_next_hi
; -------------------------------------------------------------------
; decruncher entry point, needs calculated tables (21(13) bytes)
; x and y must be #0 when entering
;
if LITERAL_SEQUENCES_NOT_USED
	dey
else
	inx
	jsr get_bits
	tay
	bne literal_start1
endif
begin2:
	inx
	jsr bits_next
	lsr a
	iny
	bcc begin2
if LITERAL_SEQUENCES_NOT_USED
	beq literal_start
endif
	cpy #$11
if !LITERAL_SEQUENCES_NOT_USED
	bcc sequence_start
	beq bits_done
; -------------------------------------------------------------------
; literal sequence handling (13(2) bytes)
;
	ldx #$10
	jsr get_bits
literal_start1:
	sta <zp_len_lo
	ldx <zp_bits_hi
	ldy #0
	bcc literal_start
sequence_start:
else
	bcs bits_done
endif

; -------------------------------------------------------------------
; calulate length of sequence (zp_len) (11 bytes)
;
	ldx tabl_bi - 1,y
	jsr get_bits
	adc tabl_lo - 1,y	; we have now calculated zp_len_lo
	sta zp_len_lo
; -------------------------------------------------------------------
; now do the hibyte of the sequence length calculation (6 bytes)
	lda zp_bits_hi
	adc tabl_hi - 1,y	; c = 0 after this.
	pha
; -------------------------------------------------------------------
; here we decide what offset table to use (20 bytes)
; x is 0 here
;
	bne nots123
	ldy zp_len_lo
	cpy #$04
	bcc size123
nots123:
	ldy #$03
size123:
	ldx tabl_bit - 1,y
	jsr get_bits
	adc tabl_off - 1,y	; c = 0 after this.
	tay			; 1 <= y <= 52 here
; -------------------------------------------------------------------
; Here we do the dest_lo -= len_lo subtraction to prepare zp_dest
; but we do it backwards:	a - b == (b - a - 1) ^ ~0 (C-syntax)
; (16(16) bytes)
	lda zp_len_lo
literal_start:			; literal enters here with y = 0, c = 1
	sbc zp_dest_lo
	bcc noborrow
	dec zp_dest_hi
noborrow:
	eor #$ff
	sta zp_dest_lo
	cpy #$01		; y < 1 then literal
if LITERAL_SEQUENCES_NOT_USED
	bcc literal_get_byte
else
	bcc pre_copy
endif

; -------------------------------------------------------------------
; calulate absolute offset (zp_src) (27 bytes)
;
	ldx tabl_bi,y
	jsr get_bits;
	adc tabl_lo,y
	bcc skipcarry
	inc zp_bits_hi
	clc
skipcarry:
	adc zp_dest_lo
	sta zp_src_lo
	lda zp_bits_hi
	adc tabl_hi,y
	adc zp_dest_hi
	sta zp_src_hi
; -------------------------------------------------------------------
; prepare for copy loop (8(6) bytes)
;
	pla
	tax
if LITERAL_SEQUENCES_NOT_USED
	ldy <zp_len_lo
	bcc copy_start
else
	sec
pre_copy:
	ldy <zp_len_lo
	jmp copy_start
endif
; -------------------------------------------------------------------
; two small static tables (6(6) bytes)
;
tabl_bit:
	.byte 2,4,4
tabl_off:
	.byte 48,32,16
; -------------------------------------------------------------------
; end of decruncher
; -------------------------------------------------------------------
