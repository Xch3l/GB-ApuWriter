.RAMSECTION "MAINMENU_RAM" SLOT SLOT_WRAM
	RAM_INITD db
.ENDS

.SECTION "MAINMENU" SLOT SLOT_ROM0

strMainMenuTitle: text "Main Menu"
strEditPulse1: text "Edit Pulse 1"
strEditPulse2: text "Edit Pulse 2"
strEditWave:   text "Edit Wave"
strEditNoise:  text "Edit Noise"

MainMenu:
	.db 4 ; option count
	.dw @vblank ; menu vblank
	.dw @loop   ; menu loop
	.dw strMainMenuTitle  ; menu title strptr
	; menu label strptrs
	.dw strEditPulse1
	.dw strEditPulse2
	.dw strEditWave
	.dw strEditNoise
	; menu callback ptrs
	.dw @initMenu1
	.dw @initMenu2
	.dw @initMenu3
	.dw @initMenu4

@vblank:
	ld A, ($FF26)
	ld B, A

	; Display note icon for channels currenly playing (according to hw)
	ld A, $20
	bit 0, B
	jr Z, +
	ld A, CHANNEL_NOTE
+	ld (MENU_LINE1+18), A

	ld A, $20
	bit 1, B
	jr Z, +
	ld A, CHANNEL_NOTE
+	ld (MENU_LINE2+18), A

	ld A, $20
	bit 2, B
	jr Z, +
	ld A, CHANNEL_NOTE
+	ld (MENU_LINE3+18), A

	ld A, $20
	bit 3, B
	jr Z, +
	ld A, CHANNEL_NOTE
+	ld (MENU_LINE4+18), A

	ret

@loop:
	ld HL, RAM_INITD
	ld A, $5A
	cp (HL)
	call NZ, @initRAM

	call ReadInput
	bit _JP_START, C
	ret Z

	call MenuPulse1@setapu
	call MenuPulse2@setapu
	call MenuWave@setapu
	call MenuNoise@setapu
	ret

@initRAM:
	ldi (HL), A

	; Enable audio hw
	out $FF26, $80
	out $FF25, $FF ; set panning
	ldi (HL), A
	out $FF24, $77 ; set master volume

	; Init ram
	ld HL, @apuData

	ld DE, PU1_DATA
	ld B, 5
	call CopyBytes

	ld DE, PU2_DATA
	ld B, 4
	call CopyBytes

	ld DE, WAV_DATA
	ld B, 21
	call CopyBytes

	ld DE, NOI_DATA
	ld B, 4
	call CopyBytes

	ret

@apuData:
	.db $00, $00, $73, $00, $C4 ; Pulse 1
	.db      $00, $73, $00, $C4 ; Pulse 2
	.db $80, $F0, $20, $00, $C4 ; Wave
	.db $01, $23, $45, $67, $89, $AB, $CD, $EF ; Waveform
	.db $FE, $DC, $BA, $98, $76, $54, $32, $10
	.db      $00, $73, $00, $C0 ; Noise

@initMenu1:
	ld DE, MenuPulse1
	call InitSubmenu

@initMenu2:
	ld DE, MenuPulse2
	call InitSubmenu

@initMenu3:
	ld DE, MenuWave
	call InitSubmenu

@initMenu4:
	ld DE, MenuNoise
	call InitSubmenu

.ENDS
