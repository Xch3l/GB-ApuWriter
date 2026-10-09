.SECTION "APUEDIT_UTIL" SLOT SLOT_ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inverts a variable's value (in HL) with a bitmask (in B)
; HL = RAM ptr
; B  = bits
ToggleBits:
	ld A, (HL)
	xor B
	ld (HL), A
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writes A to the addr at HL
SaveReg:
	ld (HL), A
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writes data from (HL) to regs
WriteRegs:
-	ldi A, (HL)
	outi
	inc C
	dec B
	jr NZ, -
	ret

.ENDS
