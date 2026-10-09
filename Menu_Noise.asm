.RAMSECTION "NOISE_RAM" SLOT SLOT_WRAM
	NOI_DATA   .dsb 4
	NOI_LENGTH db ; FF20 NR41
	NOI_ENV    db ; FF21 NR42
	NOI_FREQ   db ; FF22 NR43
	NOI_CTRL   db ; FF23 NR44
.ENDS

.SECTION "NOISE_MENU" SLOT SLOT_ROM0

strNOI_MenuTitle: text "Noise"
;               ::::::::::::::
strNOI_EnvSweep: text "Env. rate"
strNOI_EnvDir:   text "Env. ramp"
strNOI_ClkDiv:   text "Divider"
strNOI_Mode:     text "Short"
strNOI_ClkShift: text "Rate"

MenuNoise:
	.db 11 ; option count
	.dw @vblank ; menu vblank
	.dw @loop   ; menu loop
	.dw strNOI_MenuTitle  ; menu title strptr

	; menu label strptrs
	.dw strChnPanning
	.dw strChnVolume
	.dw strChnLength
	.dw strNOI_ClkDiv
	.dw strNOI_ClkShift
	.dw strNOI_Mode
	.dw strNOI_EnvSweep
	.dw strNOI_EnvDir
	.dw strChnAutostop
	.dw strChnRetrigger
	.dw strMenuReturn

	; menu callback ptrs
	.dw @togglePanning   ; 0: toggle panning
	.dw NopCall          ; 1: set volume
	.dw NopCall          ; 2: set length
	.dw NopCall          ; 3: set clock div
	.dw NopCall          ; 4: set clock shift
	.dw @toggleMode      ; 5: toggle mode
	.dw NopCall          ; 6: set env. sweep
	.dw @toggleEnvDir    ; 7: toggle env. ramp
	.dw @toggleAutostop  ; 8: toggle autostop
	.dw @toggleRetrigger ; 9: toggle retrigger
	.dw ReturnSubmenu

@vblank:
	ld HL, TEXTBUF

	ldi A, (HL) ; play state
	ld (BG0+18), A
	ldi A, (HL) ; left panning
	ld (MENU_LINE1+17), A
	ldi A, (HL); right panning
	ld (MENU_LINE1+18), A
	ld DE, MENU_LINE3+17 ; length
	ld B, 2
	call CopyBytes
	ldi A, (HL) ; env. sweep rate
	ld (MENU_LINE7+18), A
	ldi A, (HL) ; env. ramp dir
	ld (MENU_LINE8+18), A
	ldi A, (HL) ; volume
	ld (MENU_LINE2+18), A
	ldi A, (HL) ; clock divider
	ld (MENU_LINE4+18), A
	ldi A, (HL) ; shift mode
	ld (MENU_LINE6+18), A
	ldi A, (HL) ; clock shift
	ld (MENU_LINE5+18), A
	ldi A, (HL) ; retrigger
	ld (MENU_LINE10+18), A
	ldi A, (HL) ; autostop
	ld (MENU_LINE9+18), A

	ret

@loop:
	call ReadInput

	bit _JP_START, C ; apply settings
	jr Z, +
	call @setapu
	jr @setbuf

+	bit _JP_SELECT, C ; display data
	jr Z, +
	call @showData
	jr @loop

+	bit _JP_B, B ; reapply button presses
	jr Z, +
	ld C, B

+	ld A, JP_LEFT|JP_RIGHT ; check for inc/dec buttons
	and C
	jr Z, @setbuf

	ld E, C
	ld HL, @jtretn
	push HL

	call MenuJumpTable
	.dw @setPanning
	.dw @setVolume
	.dw @setLength
	.dw @setClockDiv
	.dw @setClockShift
	.dw @toggleMode
	.dw @setEnvSweep
	.dw @toggleEnvDir
	.dw @toggleAutostop
	.dw @toggleRetrigger
	.dw NopCall

@jtretn:
	call @setapu

@setbuf:
	ld HL, TEXTBUF

	in $FF26 ; NR52
	bit 3, A
	ld A, INVERTED_SPACE
	jr Z, +
	ld A, INVERTED_NOTE
+	ldi (HL), A

	; Parse panning
	in $FF25
	ld B, A

	ld A, LCH_OFF
	bit 7, B
	jr Z, +
	inc A
+	ldi (HL), A

	ld A, RCH_OFF
	bit 3, B
	jr Z, +
	inc A
+	ldi (HL), A

	; Parse length
	ld BC, NOI_DATA
	ld A, (BC)
	inc BC
	and $3F
	call PutHex

	; Parse envelope
	ld A, (BC) ; env. sweep rate
	and $07
	call PutHexLo

	ld A, (BC) ; env. ramp dir
	bit 3, A
	ld A, RAMP_DOWN
	jr Z, +
	inc A
+	ldi (HL), A

	ld A, (BC) ; volume
	inc BC
	swap A
	and $0F
	call PutHexLo

	; Parse LFSR
	ld A, (BC) ; clock divider
	and $07
	call PutHexLo

	ld A, (BC) ; shift mode
	bit 3, A
	ld A, BOX_ICON
	jr Z, +
	inc A
+	ldi (HL), A

	ld A, (BC) ; clock shift
	inc BC
	swap A
	and $0F
	call PutHexLo

	; Parse flags
	ld A, (BC)
	ld B, A

	ld A, BOX_ICON ; autostop
	bit 7, B
	jr Z, +
	inc A
+	ldi (HL), A

	ld A, BOX_ICON ; retrigger
	bit 6, B
	jr Z, +
	inc A
+	ldi (HL), A

	ret

@setapu:
	ld HL, NOI_DATA
	ld BC, $0420
	jp WriteRegs

@showData:
	ld A, $F0 ; hide pointer
	ld (OAMTABLE), A

	ld HL, TEXTBUF2 ; set label
	ld DE, strData
	ld B, _sizeof_strData
-	ld A, (DE)
	inc DE
	ldi (HL), A
	dec B
	jr NZ, -

	ld DE, NOI_DATA
	ld B, 4
-	ld A, (DE)
	call PutHex
	ld (HL), ' '
	inc HL
	inc DE
	dec B
	jr NZ, -
	ld (HL), $00

	ld DE, TEXTBUF2
	call InitPopup

-	rst VSync
	call ReadInput
	and JP_A|JP_B
	jr Z, -

	jp ClosePopup

;----------------------------------------------------------------

@togglePanning:
	in $FF25 ; NR51
	xor $88
	out $FF25
	jp @setapu

@toggleMode:
	ld HL, NOI_FREQ
	ld B, $08
	call ToggleBits
	jp @setapu

@toggleEnvDir:
	ld HL, NOI_ENV
	ld B, $08
	call ToggleBits
	jp @setapu

@toggleAutostop:
	ld HL, NOI_CTRL
	ld B, $40
	call ToggleBits
	jp @setapu

@toggleRetrigger:
	ld HL, NOI_CTRL
	ld B, $80
	call ToggleBits
	jp @setapu

;----------------------------------------------------------------

@setPanning:
	in $FF25
	bit _JP_LEFT, E
	jr Z, +
	xor $80
+	bit _JP_RIGHT, E
	jr Z, +
	xor $08
+	out $FF25
	jp @setapu

@setVolume:
	ld HL, NOI_ENV
	ld A, (HL)
	bit _JP_LEFT, E
	jr Z, +
	sub $10
	jr ++
+	add $10
++
	call SaveReg
	jp @setapu

@setLength:
	ld HL, NOI_LENGTH
	ld A, (HL)
	bit _JP_LEFT, E
	jr Z, +
	dec A
	jr ++
+	inc A
++
	and $3F
	ld (HL), A
	jp @setapu

@setClockDiv:
	ld HL, NOI_FREQ
	jr @setEnvSweep+3

@setClockShift:
	ld HL, NOI_FREQ
	ld A, (HL)

	bit _JP_LEFT, E
	jr Z, +
	sub $10
	jr ++
+	add $10
++
	ld (HL), A
	jp @setapu

@setEnvSweep:
	ld HL, NOI_ENV
	ld B, (HL)
	ld A, B
	and $F8
	ld (HL), A

	bit _JP_LEFT, E
	jr Z, +
	dec B
	jr ++

+	inc B
++

	ld A, B
	and $07
	or (HL)
	ld (HL), A
	jp @setapu

.ENDS
