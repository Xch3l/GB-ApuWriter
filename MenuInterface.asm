.DEFINE MENU_LINE1  BG0+$040
.DEFINE MENU_LINE2  BG0+$060
.DEFINE MENU_LINE3  BG0+$080
.DEFINE MENU_LINE4  BG0+$0A0
.DEFINE MENU_LINE5  BG0+$0C0
.DEFINE MENU_LINE6  BG0+$0E0
.DEFINE MENU_LINE7  BG0+$100
.DEFINE MENU_LINE8  BG0+$120
.DEFINE MENU_LINE9  BG0+$140
.DEFINE MENU_LINE10 BG0+$160
.DEFINE MENU_LINE11 BG0+$180
.DEFINE MENU_LINE12 BG0+$1A0
.DEFINE MENU_LINE13 BG0+$1C0
.DEFINE MENU_LINE14 BG0+$1E0
.DEFINE MENU_LINE15 BG0+$200

.RAMSECTION "MENURAM" SLOT SLOT_WRAM
	MenuRef:     dw ; $0000
	MenuIndex:   db ; $00
	MenuOptions: db ; $00
	MenuUpdate:  dw ; NopRetn
	MenuLoop:    dw ; NopRetn
	MenuSelect:  dw ; NopRetn
.ENDS

.SECTION "MENUCODE" SLOT SLOT_ROM0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Menu interface
MenuVBlank:
	; Run current menu's "update" routine
	ld HL, MenuUpdate
	ldi A, (HL)
	ld H, (HL)
	ld L, A
	call PointerCall

	out rIE, IF_VBLANK
	ret

ReturnSubmenu:
	pop AF ; remove previous call
	pop AF ; restore previous option
	pop DE ; restore last menu
	jr InitMenu+1

InitSubmenu:
	pop HL ; remove previous call

	; Keep previous menu
	ld HL, MenuRef
	ldi A, (HL)
	ld H, (HL)
	ld L, A
	ld A, (MenuIndex)
	push HL ; save previous menu
	push AF ; save last selected option

; HL = Menu ptr
InitMenu:
	xor A

	; Init menu
	ld HL, MenuRef
	ld (HL), E
	inc HL
	ld (HL), D
	inc HL
	ldi (HL), A ; set option index

	di
	call ScreenOff

	; Load info
	ld A, (DE)
	ld C, A ; keep option count
	ldi (HL), A
	inc DE

	ld B, 4 ; copy pointers
-	ld A, (DE)
	ldi (HL), A
	inc DE
	dec B
	jr NZ, -

	; Load title
	call SetMenuTitle

	; Load option labels
-	ld B, MAX_LABEL_LENGTH
		call CopyText

		ld A, 14
		add B
		ld B, A
		ld A, $20
--	ldi (HL), A
		dec B
		jr NZ, --

	dec C
	jr NZ, -

	; Clear the rest
	;ld A, $20 ; take it from before
-	ldi (HL), A
	bit 2, H
	jr Z, -

	; Clear OAMs
	ld HL, OAMTABLE
	ld A, L
-	ld (HL), $F0
	add 4
	ld L, A
	cp $A0
	jr NZ, -

	; Capture options ptr
	ld HL, MenuSelect
	ld (HL), E
	inc HL
	ld (HL), D

	out rIF, $00
	out rIE, IF_VBLANK
	in rLCDC
	set _LCDC_ON, A
	out rLCDC;, LCDC_ON|LCDC_OBJ|LCDC_BG

	SetInt VBLANK_INT, MenuVBlank
	ei

LoopMenu:
	rst VSync
	call ReadInput

	ld HL, MenuOptions
	ld B, (HL) ; get option count
	dec HL
	ld A, (HL) ; get current index

	push HL
	ld HL, OAMTABLE

	swap A
	rra
	add 32

	ldi (HL), A ; y

	ld DE, CursorX
	in FRAMENUM
	rra
	rra
	rra
	and 3
	add E
	ld E, A
	jr NC, +
	inc D
+	ld A, (DE)
	ldi (HL), A ; x

	ld (HL), CURSOR_ARROW ; t
	inc HL
	ld (HL), $00 ; a
	pop HL
	ld A, (HL) ; reload index

	; Check for up/down on dpad
	bit _JP_DOWN, C
	jr Z, +
	inc A
	cp B
	jr C, ++
	xor A
	jr ++

+	bit _JP_UP, C
	jr Z, +
	sub 1
	jr NC, ++
	ld A, B
	dec A
++	ld (HL), A ; save index

	; Check for A button
+	bit _JP_A, C
	jr Z, +

	ld B, $00
	add A
	ld C, A

	ld HL, MenuSelect
	ldi A, (HL)
	ld H, (HL)
	ld L, A
	add HL, BC

	ldi A, (HL)
	ld H, (HL)
	ld L, A

	;sleep
	call PointerCall
	jp LoopMenu

+	; on-menu loop handler
	ld HL, MenuLoop
	ldi A, (HL)
	ld H, (HL)
	ld L, A
	call PointerCall
	jp LoopMenu

CursorX:
	.db 14, 15, 17, 16

MenuJumpTable:
	pop HL

	ld A, (MenuIndex)
	add A
	ld C, A

	ld B, $00
	add HL, BC

	ldi A, (HL)
	ld H, (HL)
	ld L, A
	jp (HL)

strMenuReturn: text "Return"

.ENDS
