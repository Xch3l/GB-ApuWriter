.INCLUDE "defs.asm"

.DEFINE ROM_TITLE "ApuWriter"
;.DEFINE CGB_SUPPORT
;.DEFINE SGB_SUPPORT
.DEFINE BOARD_TYPE BOARD_ROM
.DEFINE ROM_SIZE 0 ; 32KB
;.DEFINE RAM_SIZE

.INCLUDE "macros.asm"
.INCLUDE "head.asm"

; Menu defs
.DEFINE MAX_LABEL_LENGTH 18

; Tile defs
.DEFINE SPRITE0          $05
.DEFINE SPRITE1          $06
.DEFINE DIVIDER_TILE     $07
.DEFINE CURSOR_ARROW     $08
.DEFINE CHANNEL_NOTE     $09
.DEFINE LCH_OFF          $0A ;   .   (left half dot)
.DEFINE LCH_ON           $0B ; ((.
.DEFINE RCH_OFF          $0C ;   .   (right half dot)
.DEFINE RCH_ON           $0D ;   .))
.DEFINE BOX_ICON         $0E ; empty box
.DEFINE TICK_ICON        $0F ; checkmark
.DEFINE PULSE_EIGTH      $10 ; _|¯|____
.DEFINE PULSE_FOURTH     $11 ; _|¯¯|___
.DEFINE PULSE_HALF       $12 ; _|¯¯¯|__
.DEFINE PULSE_3FOURTHS   $13 ; _|¯¯¯¯|_
.DEFINE RAMP_DOWN        $14 ; ¯\_
.DEFINE RAMP_UP          $15 ; _/¯
.DEFINE BLANK_TILE       $20
.DEFINE INVERTED_SPACE   $80|BLANK_TILE
.DEFINE INVERTED_NOTE    $80|CHANNEL_NOTE

.MACRO text ; macro to insert a null-terminated string as data
	.REPT NARGS
		.db \1
		.SHIFT
	.ENDR

	.db 0
.ENDM

.RAMSECTION "MAINRAM" SLOT SLOT_WRAM
	REPEAT_TIMEOUT db
	TEXTBUF2 dsb 96
	BCDBUF dw
.ENDS

.SECTION "MAINCODE" SLOT SLOT_ROM0

Main:
	out rLCDC, LCDC_WIN9C|LCDC_PAGE0|LCDC_OBJ|LCDC_BG
	out rBGP, $E4
	out rOBP0
	out rOBP1

	ld HL, VRAM
	ld DE, Monofont
	ld BC, _sizeof_Monofont

-	ld A, (DE)
	inc DE
	ldi (HL), A
	ldi (HL), A
	dec BC
	ld A, B
	or C
	jr NZ, -

	ld DE, Monofont
	ld BC, _sizeof_Monofont
-	ld A, (DE)
	inc DE
	cpl
	ldi (HL), A
	cpl
	ldi (HL), A
	dec BC
	ld A, B
	or C
	jr NZ, -

	ld HL, VRAM+$0040
	ld B, _sizeof_Sliders
-	ld A, (DE)
	ldi (HL), A
	inc DE
	dec B
	jr NZ, -

	; Clear 2nd text buffer
	ld HL, TEXTBUF2
	ld A, _sizeof_TEXTBUF2
-	ld (HL), $00
	inc HL
	dec A
	jr NZ, -

	ld DE, MainMenu
	call InitMenu

Loop:
	rst VSync
	jp Loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ScreenOff:
	in rLCDC
	bit _LCDC_ON, A
	ret Z

	and $7F
	ld B, A
-	sleep
	in rIF
	bit _IF_VBLANK, A
	jr Z, -

	ld A, B
	out rLCDC
	ret

ScreenOn:
	out rIF, $00
	in rLCDC
	or LCDC_ON
	out rLCDC
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ReadInput:
	in SYSFLAGS
	bit SF_INPUT, A
	jr Z, +

	in JDOWN
	ld B, A
	in JPRESS
	ld C, A
	ret

+	set SF_INPUT, A
	out SYSFLAGS

	ld HL, rJOYP
	ld (HL), $20 ; select DPAD
	in JDOWN     ; get previous state [12t]
	ld C, A      ; keep it [4t]
	ld A, (HL)   ; read DPAD state [=16t]
	ld (HL), $10 ; select Buttons
	and $0F      ; remove selector bits [8t]
	swap A       ; set to high bits [8t]
	ld B, A      ; keep it [4t]
	ld A, (HL)   ; read Buttons state [=20t]
	ld (HL), H   ; disable
	and $0F      ; remove selector bits
	or B         ; combine with prevous read
	cpl          ; invert
	out JDOWN    ; save it

	ld B, A      ; B = current read
	ld A, C
	xor B
	and B
	ld C, A      ; C = new buttons
	out JPRESS

	ld D, DEFAULT_REPEAT
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.DEFINE REPEAT_DELAY     15 ; ~1/4 second
.DEFINE DEFAULT_REPEAT    4 ; sensible retrigger default

; Repeats inputs according to a bitmask in A, with a delay set
; in D
InputRepeat:
	ld HL, REPEAT_TIMEOUT
	and B
	jr NZ, +
	ld (HL), REPEAT_DELAY
	ret

+	dec (HL)
	ret NZ

	ld (HL), D
	ld A, B
	ld C, A
	out JPRESS
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copies a string of text to VRAM (mostly used by menu interface)
;   DE = Source address pointer
;   HL = Target address
;   B  = Max length
CopyText:
	push DE
	push HL
	ld H, D
	ld L, E

	ldi A, (HL)
	ld H, (HL)
	ld L, A

	ld D, H
	ld E, L
	pop HL

	; Copy text
-	ld A, (DE)  ; get next char
	inc DE
	and A       ; check for \0
	jr Z, +     ;   skip if so
	ldi (HL), A ; write it
	dec B
	jr NZ, -

	; skip to next \0
-	ld A, (DE)
	inc DE
	and A
	jr NZ, -

+	pop DE
	inc DE
	inc DE
	ret

SetMenuTitle:
	ld HL, BG0
	ld B, MAX_LABEL_LENGTH
	ld (HL), INVERTED_SPACE
	inc HL

	push DE
	push HL
	ld H, D
	ld L, E

	ldi A, (HL)
	ld H, (HL)
	ld L, A

	ld D, H
	ld E, L
	pop HL

	; Copy (inverted) text
-	ld A, (DE)
	inc DE
	and A
	jr Z, +
	or $80
	ldi (HL), A
	dec B
	jr NZ, -

	; skip to next \0
-	ld A, (DE)
	inc DE
	and A
	jr NZ, -

+	; Fill remaining line
	ld A, INVERTED_SPACE
-	ldi (HL), A
	bit 5, L
	jr Z, -

	; Clear next line
	ld A, $20
-	ldi (HL), A
	bit 5, L
	jr NZ, -

	ldi (HL), A
	ldi (HL), A

	pop DE
	inc DE
	inc DE
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Converts a number (between 0 and 511) to its BCD representation
;   HL   Pointer to value
;  - or -
;   BC   Value
ConvertBCD:
	ld C, (HL)
	inc HL
	ld B, (HL)

ToBCD:
	ld A, C
	swap A
	and $0F
	bit 0, B
	jr Z, +
	dec B
	add 16
+	add A ; A * 2

	; Index into table of 16s
	push BC
	ld HL, BcdTable
	ld B, $00
	ld C, A
	add HL, BC
	pop BC

	; convert value
	ld A, C
	and 15
	add 0
	daa
	add (HL)
	daa
	ld C, A ; low byte
	inc HL

	ld A, B
	adc 0
	daa
	add (HL)
	daa
	ld B, A ; high byte

	ret

BcdTable:
	.dw $0000, $0016, $0032, $0048, $0064, $0080, $0096, $0112
	.dw $0128, $0144, $0160, $0176, $0192, $0208, $0224, $0240

	.dw $0256, $0272, $0288, $0304, $0320, $0336, $0352, $0368
	.dw $0384, $0400, $0416, $0432, $0448, $0464, $0480, $0496

.ENDS

;---------------------------------------------------------------

.RAMSECTION "POPUPRAM" SLOT SLOT_WRAM

.ENDS

.SECTION "POPUPCODE" SLOT SLOT_ROM0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Popup stuff (uses Window)
InitPopup:
	SetIFLAGS IF_VBLANK
	di
	sleep
	call ScreenOff

	ld HL, BG1 ; set BG pointer and tile
	ld A, DIVIDER_TILE

	; Make divider
	ld B, 32
-	ldi (HL), A
	dec B
	jr NZ, -

	; Write space
	ld A, $20
	ldi (HL), A

	; Write message
	ld C, 0 ; lines
@writeLine:
	ld B, 18 ; maxlen
-	ld A, (DE)
	inc DE

	and A ; null?
	jr Z, @clear
	cp '\n' ; newline?
	jr NZ, +

		push BC

		ld A, 18 ; get chars written
		sub B
		ld B, A

		ld A, 32 ; get count to write
		sub B
		ld B, A

		ld A, ' '
--	ldi (HL), A
		dec B
		jr NZ, --
		pop BC
		inc C
		jr @writeLine

+	ldi (HL), A
	dec B
	jr NZ, -

	; Skip until next NUL
-	ld A, (DE)
	inc DE
	and A
	jr NZ, -

	; Clear next lines
@clear:
-	ld (HL), ' '
	inc L
	cp L
	jr NZ, -

@calcLines:
	; Calc lines printed for slide-up
	ld A, C
	add A
	add A
	add A
	ld C, A
	ld A, $78
	sub C
	ld C, A

	; Enable Window and LCD
	out rWY, $98
	out rWX, $07
	in rLCDC
	set _LCDC_WINDOW, A
	out rLCDC
	call ScreenOn

	; Animate sliding up
	ld A, $90 ; WY
	ld B, $08

@nextStep:
	out rWY
	out rIF, $00
	sleep

	in rWY
	sub B
	dec B
	jr NZ, +
	inc B ;ld B, 2
+	cp C ;$70
	jr NC, @nextStep
	ld A, C
	out rWY;, $70 ; cover overshooting

	; Recover isource
	RestoreIFLAGS
	ei
	ret

ClosePopup:
	; Change isource
	SetIFLAGS IF_VBLANK ; vblank only
	di

	; Slide down
	ld B, 1
-	out rIF, $00
	sleep
	in rWY
	add B
	out rWY
	inc B
	cp $90
	jr C, -

	; Restore isource
	RestoreIFLAGS
	ei
	ret

.ENDS

.SECTION "DATA" SLOT SLOT_ROM0 SUPERFREE ALIGN 256

Monofont:
	.INCBIN "Monofont.1bpp"

Sliders:
	.INCBIN "sliders.2bpp"

strChnVolume:    text "Volume"
strChnLength:    text "Length"
strChnPanning:   text "Panning"
strChnAutostop:  text "Auto-stop"
strChnRetrigger: text "Retrigger"
strChnFrequency: text "Frequency"
strData:         .db  "Data:", '\n', "  "
strWaveform:     .db  "Waveform:", '\n', "  "
.ENDS

.INCLUDE "utils.asm"
.INCLUDE "MenuInterface.asm"
.INCLUDE "Menu_Main.asm"
.INCLUDE "Menu_Pulse1.asm"
.INCLUDE "Menu_Pulse2.asm"
.INCLUDE "Menu_Wave.asm"
.INCLUDE "Menu_Noise.asm"
