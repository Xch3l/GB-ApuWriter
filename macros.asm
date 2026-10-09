;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Pseudo opcodes
.MACRO out
	.IF NARGS == 2
		.IF \2 == 0
			xor A
		.ELSE
			ld A, \2
		.ENDIF
	.ENDIF

	ldh (\1&255), A
.ENDM

.MACRO in
	ldh A, (\1&255)
.ENDM

.MACRO outi
	.IF NARGS == 1
		.IF \1 == 0
			xor A
		.ELSE
			ld A, \1
		.ENDIF
	.ENDIF

	.db $E2 ; ld ($FF00+C), A
.ENDM

.MACRO ini
	.db $F2 ; ld A, ($FF00+C)
.ENDM

.MACRO sleep
	halt
	nop
.ENDM

.MACRO suspend
	stop
	nop
.ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.MACRO SetIFLAGS
	in rIE
	push AF

	.IF NARGS == 1
		out rIE, \1
	.ENDIF

	out rIF, 0 ; clear pending
.ENDM

.MACRO RestoreIFLAGS
	pop AF
	out rIE
	out rIF, 0 ; clear pending
.ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.MACRO SetInt ARGS int, ptr
	ld HL, int
	ld (HL), <ptr
	inc HL
	ld (HL), >ptr
.ENDM
