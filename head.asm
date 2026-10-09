.EMPTYFILL $FF

.IFNDEF BOARD_TYPE
	.PRINTT "No BOARD_TYPE set! Defaulting to BOARD_ROM\n"
	.DEFINE BOARD_TYPE BOARD_ROM
.ENDIF

.IFEQ BOARD_TYPE BOARD_ROM
	.ROMBANKSIZE $8000
	.ROMBANKS 1

	.DEFINE SLOT_ROM0 0
	.DEFINE SLOT_WRAM 1
	.DEFINE SLOT_HRAM 2
.ELSE
	.ROMBANKSIZE $4000
	.ROMBANKS 2

	.DEFINE SLOT_ROM0 0
	.DEFINE SLOT_ROMX 1
	.DEFINE SLOT_WRAM 2
	.DEFINE SLOT_HRAM 3
.ENDIF

.MEMORYMAP
	DEFAULTSLOT SLOT_ROM0

	.IFEQ BOARD_TYPE BOARD_ROM
		SLOT SLOT_ROM0 $0000 $8000
	.ELSE
		SLOT SLOT_ROM0 $0000 $4000
		SLOT SLOT_ROMX $4000 $4000
	.ENDIF

	SLOT SLOT_WRAM $C000 $2000
	SLOT SLOT_HRAM $FF80 $007F
.ENDME


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.RAMSECTION "SYSTEM" SLOT SLOT_HRAM
	SYSFLAGS   db
	RANDSEED   dw
	FRAMENUM   db
	JDOWN      db
	JPRESS     db
	VBLANK_INT dw
	STAT_INT   dw
	TIMER_INT  dw
	SERIAL_INT dw
	JOYPAD_INT dw

	TEMP       dsb 8
	TEXTBUF    dsb 24
.ENDS

.DEFINE SF_READY    7
.DEFINE SF_VBLANK   6
.DEFINE SF_INPUT    4
.DEFINE SF_AGB    $03
.DEFINE SF_CGB    $01
.DEFINE SF_DMG    $00

.DEFINE OAMDMA   $FFF8
.DEFINE OAMTABLE $DF00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Misc. defines
.DEFINE VRAM  $8000
.DEFINE VRAM1 $8800
.DEFINE VRAM2 $9000
.DEFINE BG0   $9800
.DEFINE BG1   $9C00

.DEFINE _JP_DOWN   7
.DEFINE _JP_UP     6
.DEFINE _JP_LEFT   5
.DEFINE _JP_RIGHT  4
.DEFINE _JP_START  3
.DEFINE _JP_SELECT 2
.DEFINE _JP_B      1
.DEFINE _JP_A      0

.DEFINE JP_DOWN   1<<_JP_DOWN
.DEFINE JP_UP     1<<_JP_UP
.DEFINE JP_LEFT   1<<_JP_LEFT
.DEFINE JP_RIGHT  1<<_JP_RIGHT
.DEFINE JP_START  1<<_JP_START
.DEFINE JP_SELECT 1<<_JP_SELECT
.DEFINE JP_B      1<<_JP_B
.DEFINE JP_A      1<<_JP_A

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Vectors
.org $0000 ; RST 0
	rst $38
	.db 0, 0, 0,"RST0"

.org $0008 ; RST 1
VSync:
	in SYSFLAGS
	set SF_READY, A
	out SYSFLAGS

-	sleep
;.org $0010 ; RST 2
	in SYSFLAGS
	and $C0
	jr NZ, -
	ret
	nop

.org $0018 ; RST 3
	rst $38
	.db 0, 0, 0,"RST3"

.org $0020 ; RST 4
	rst $38
	.db 0, 0, 0,"RST4"

.org $0028 ; RST 5 / ldir
MemCopy:
	ldi A, (HL)
	ld (DE), A
	dec BC
	ld A, B
	or C
	jr NZ, MemCopy

NopCall:
	ret

.org $0030 ; RST6
PointerCall:
	jp (HL)

VectorCall:
	ldi A, (HL)
	ld H, (HL)
	ld L, A

	rst PointerCall
	pop HL
	reti
	nop

.org $0038 ; RST7
	push AF
-	out rIE, $00
	sleep
	jr -

.org $0040 ; VBlank
	push AF
	in SYSFLAGS
	bit SF_READY, A
	jp HandleVBlank

.org $0048 ; STAT
	push HL
	ld HL, STAT_INT
	jr VectorCall
	.dw 0

.org $0050 ; Timer
	push HL
	ld HL, TIMER_INT
	jr VectorCall
	.dw 0

.org $0058 ; Serial
	push HL
	ld HL, SERIAL_INT
	jr VectorCall
	.dw 0

.org $0060 ; Joypad
	push HL
	ld HL, JOYPAD_INT
	jr VectorCall
	.dw 0

;---------------------------------------------------------------

HandleVBlank:
	jr Z, @end
	bit SF_VBLANK, A
	jr NZ, @end
	or $C0 ; set both flags
	out SYSFLAGS

	; Populate OAMs
	push BC
	ld A, >OAMTABLE
	ld BC, $2946
	call OAMDMA
	pop BC

	; Call handler
	push HL
	ld HL, VBLANK_INT
	ldi A, (HL)
	ld H, (HL)
	ld L, A
	or H
	call NZ, PointerCall

	ld HL, FRAMENUM
	inc (HL)

	; Clear VBlank flags
	in SYSFLAGS
	and $0F
	out SYSFLAGS

	pop HL

@end:
	pop AF
	reti

PutHex:
	push AF
	swap A
	call PutHexLo
	pop AF

PutHexLo:
	push DE
	ld D, $00
	or $F0
	ld E, A
	ld A, (DE)
	ldi (HL), A
	pop DE
	ret

.org $00F0
	.db "0123456789ABCDEF"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ROM Header
.org $0100
	jr Reset

.org $0104 ; NINTENDO logo
NintendoLogo:
	.db $CE, $ED, $66, $66, $CC, $0D, $00, $0B
	.db $03, $73, $00, $83, $00, $0C, $00, $0D
	.db $00, $08, $11, $1F, $88, $89, $00, $0E
	.db $DC, $CC, $6E, $E6, $DD, $DD, $D9, $99
	.db $BB, $BB, $67, $63, $6E, $0E, $EC, $CC
	.db $DD, $DC, $99, $9F, $BB, $B9, $33, $3E

.org $0134 ; Game title
	.IF ROM_TITLE.length > 11
		.FAIL "ROM_TITLE must be 11 chars or less!"
	.ENDIF

	.db ROM_TITLE

	.REPT 11-ROM_TITLE.length
		.db " "
	.ENDR

.org $013F ; "Manufacturer" code
	.db " TAC"

.org $0143 ; CGB support flag
	.IFDEF CGB_SUPPORT
		.db $80 ; yes
	.ELSE
		.db $00 ; no
	.ENDIF

.org $0144 ; "licensee" code
	.db "IX"

.org $0146 ; SGB support flag
	.IFDEF SGB_SUPPORT
		.db $03 ; yes
	.ELSE
		.db $00 ; no
	.ENDIF

.org $0147 ; Cartridge board type
	.db BOARD_TYPE

.org $0148 ; ROM size
	.db $00 ; 32KB

.org $0149 ; RAM size
	.IFDEF RAM_SIZE
		.db RAM_SIZE
	.ELSE
		.db RAM_NONE
	.ENDIF

.org $014A ; Region code
	.db $01 ; international

.org $014B ; "old licensee code"
	.db $33

.org $014C ; ROM version
	.IFDEF ROM_VERSION
		.db ROM_VERSION
	.ELSE
		.db $00
	.ENDIF

.org $014D ; Header checksum
	.COMPUTEGBCHECKSUM
	.COMPUTEGBCOMPLEMENTCHECK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code
.org $0150
Reset:
	ld SP, $E000
	di

.IFDEF CGB_SUPPORT
	cp $01 ; DMG/SGB?
	jr NZ, @checkGBA
	xor A
	jr @doneCheck

@checkGBA
	ld A, SF_CGB
	cp B
	jr NZ, @doneCheck

@isGBA:
	ld A, SF_AGB

@doneCheck:

.ELSE
	xor A
.ENDIF
	out SYSFLAGS

Start:
	xor A

	; Clear HRAM
	ld HL, FRAMENUM
	ld B, $FFFE-FRAMENUM
-	ldi (HL), A
	dec B
	jr NZ, -

	; Fill int handlers
	ld DE, NopCall
	ld HL, VBLANK_INT
	ld B, 5
-	ld (HL), E
	inc HL
	ld (HL), D
	inc HL
	dec B
	jr NZ, -

	; Wait VBlank
	out rIF
	inc A
	out rIE
	xor A
	sleep

	; Set registers
	out rIE      ; disable interrupts
	out rLCDC    ; disable LCD
	out rIF      ; clear iflags
	out rSNDCTRL ; disable Audio
	out rSC      ; disable SIO
	dec A        ; A = $FF
	out rJOYP    ; disable input

	; Move OAMs offscreen
	ld HL, OAMTABLE
	ld A, $A0
-	ld (HL), $F0
	inc L
	cp L
	jr NZ, -

	; Clear following stack space
-	ld (HL), $55
	inc L
	jr NZ, -

	; Copy OAMDMA routine
	ld HL, OAMDMAh
	ld DE, OAMDMA
	ld B, _sizeof_OAMDMAh
-	ldi A, (HL)
	ld (DE), A
	inc DE
	dec B
	jr NZ, -

	; Seed RNG
	call InitRand

	; Start!
	jp Main

OAMDMAh:
	outi
-	dec B
	jr NZ, -
	nop
	ret

InitRand:
	ld HL, RANDSEED+1

	ld A, ($014E)
	xor (HL)
	ldd (HL), A

	ld A, ($014F)
	xor (HL)
	ld (HL), A
	ret

; RNG routine based from:
;   https://github.com/Zeda/Z80-Optimized-Routines/blob/master/math/rng/rng8_very_very_fast.z80
; - Native Z80 counter register (R) replaced with GameBoy's own counter (TDIV)
GetRand:
	push HL
	ld HL, RANDSEED
	ldi A, (HL)
	ld H, (HL)
	ld L, A
	add HL, HL

	sbc A
	and $2D
	xor L
	ld L, A

	in rDIV
	add H

	ld (RANDSEED+1), A
	ld H, A
	ld A, L
	ld (RANDSEED), A

	ld A, H
	pop HL

	ret
