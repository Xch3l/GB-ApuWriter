.RAMSECTION "PULSE1_RAM" SLOT SLOT_WRAM
	PU1_DATA   .dsb 5
	PU1_SWEEP  db ; FF10 NR10
	PU1_LENGTH db ; FF11 NR11
	PU1_ENV    db ; FF12 NR12
	PU1_FREQL  db ; FF13 NR13
	PU1_FREQH  db ; FF14 NR14
.ENDS

.SECTION "PULSE1_MENU" SLOT SLOT_ROM0

strPU1_MenuTitle: text "Pulse 1"
;                       ::::::::::::::
strPU1_SweepRate: text "Sweep rate"
strPU1_SweepDir:  text "Sweep ramp"
strPU1_SweepStep: text "Sweep step"
strPU1_Duty:      text "Duty"
strPU1_EnvDir:    text "Env.ramp"
strPU1_EnvSweep:  text "Env.rate"

MenuPulse1:
	.db 13 ; option count
	.dw @vblank ; menu vblank
	.dw @loop   ; menu loop
	.dw strPU1_MenuTitle  ; menu title strptr

	; menu label strptrs
	.dw strChnPanning
	.dw strChnVolume
	.dw strChnLength
	.dw strChnFrequency
	.dw strPU1_Duty
	.dw strPU1_EnvDir
	.dw strPU1_EnvSweep
	.dw strPU1_SweepRate
	.dw strPU1_SweepDir
	.dw strPU1_SweepStep
	.dw strChnAutostop
	.dw strChnRetrigger
	.dw strMenuReturn

	; menu callback ptrs
	.dw @togglePanning   ;  0: toggle panning
	.dw NopCall          ;  1: set volume
	.dw NopCall          ;  2: set length
	.dw NopCall          ;  3: set frequency
	.dw NopCall          ;  4: set duty
	.dw @toggleEnvDir    ;  5: toggle envelope dir
	.dw NopCall          ;  6: set envelope rate
	.dw NopCall          ;  7: set sweep rate
	.dw @toggleSweepDir  ;  8: toggle sweep dir
	.dw NopCall          ;  9: set sweep step
	.dw @toggleAutostop  ; 10: toggle autostop
	.dw @toggleRetrigger ; 11: toggle retrigger
	.dw ReturnSubmenu

@vblank:
	ld HL, TEXTBUF

	ldi A, (HL) ; play state
	ld (BG0+18), A
	ldi A, (HL) ; left panning
	ld (MENU_LINE1+17), A
	ldi A, (HL) ; right panning
	ld (MENU_LINE1+18), A
	ldi A, (HL) ; sweep step
	ld (MENU_LINE10+18), A
	ldi A, (HL) ; sweep dir
	ld (MENU_LINE9+18), A
	ldi A, (HL) ; sweep rate
	ld (MENU_LINE8+18), A
	ldi A, (HL) ; duty
	ld (MENU_LINE5+18), A
	ld DE, MENU_LINE3+17 ; length
	ld B, 2
	call CopyBytes
	ldi A, (HL) ; env. sweep rate
	ld (MENU_LINE7+18), A
	ldi A, (HL) ; env. sweep ramp
	ld (MENU_LINE6+18), A
	ldi A, (HL) ; volume
	ld (MENU_LINE2+18), A
	ldi A, (HL) ; retrigger
	ld (MENU_LINE12+18), A
	ldi A, (HL) ; autostop
	ld (MENU_LINE11+18), A
	ld DE, MENU_LINE4+16 ; frequency
	ld B, 3
	jp CopyBytes

	ret

@loop:
	call ReadInput

	bit _JP_START, C ; Apply settings
	jr Z, +
	call @setapu
	jr @setbuf

+	bit _JP_SELECT, C ; Display data
	jr Z, +
	call @showData
	jr @loop

+	bit _JP_B, B ; Reapply button presses
	jr Z, +
	ld C, B

+	ld A, JP_LEFT|JP_RIGHT ; Check for inc/dec buttons
	and C
	jr Z, @setbuf

	ld E, C
	ld HL, @jtretn
	push HL

	call MenuJumpTable
	.dw @setPanning      ; 0
	.dw @setVolume       ; 1
	.dw @setLength       ; 2
	.dw @setFrequency    ; 3
	.dw @setDuty         ; 4
	.dw @toggleEnvDir    ; 5
	.dw @setEnvRate      ; 6
	.dw @setEnvSweepRate ; 7
	.dw @toggleSweepDir  ; 8
	.dw @setSweepStep    ; 9
	.dw @toggleAutostop  ; 10
	.dw @toggleRetrigger ; 11
	.dw NopCall ; return

@jtretn:
	call @setapu

@setbuf:
	ld HL, TEXTBUF

	in $FF26 ; NR52
	bit 0, A
	ld A, INVERTED_SPACE
	jr Z, +
	ld A, INVERTED_NOTE
+	ldi (HL), A

	; Parse panning
	in $FF25 ; ld A, (APU_PANNING)
	ld B, A

	ld A, LCH_OFF
	bit 4, B
	jr Z, +
	inc A
+	ldi (HL), A

	ld A, RCH_OFF
	bit 0, B
	jr Z, +
	inc A
+	ldi (HL), A

	; Parse sweep
	ld BC, PU1_DATA
	ld A, (BC) ; sweep step
	and 7
	call PutHexLo

	ld A, (BC) ; sweep dir
	bit 3, A
	ld A, RAMP_UP
	jr Z, +
	dec A
+	ldi (HL), A

	ld A, (BC) ; sweep rate
	inc BC
	swap A
	and 7
	call PutHexLo

	; Parse duty and length
	ld A, (BC) ; duty
	rlca
	rlca
	and $03
	or $10
	ldi (HL), A

	ld A, (BC) ; length
	inc BC
	and $3F
	call PutHex

	; Parse envelope
	ld A, (BC) ; env. sweep rate
	and 7
	call PutHexLo

	ld A, (BC) ; env. sweep ramp
	bit 3, A
	ld A, RAMP_DOWN
	jr Z, +
	inc A
+	ldi (HL), A

	ld A, (BC) ; volume
	inc BC
	inc BC
	swap A
	and $0F
	call PutHexLo

	; Parse flags
	ld A, (BC) ; retrigger
	bit 7, A
	ld A, BOX_ICON
	jr Z, +
	inc A
+	ldi (HL), A

	ld A, (BC) ; autostop
	bit 6, A
	ld A, BOX_ICON
	jr Z, +
	inc A
+	ldi (HL), A

	; Parse frequency
	ld A, (BC)
	dec BC
	and 7
	call PutHexLo

	ld A, (BC)
	call PutHex

	ret

@setapu:
	ld HL, PU1_DATA
	ld BC, $0510 ; NR10
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

	ld DE, PU1_DATA ; print data
	ld B, 5
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
	xor $11
	out $FF25
	jp @setapu

@toggleEnvDir:
	ld HL, PU1_ENV
	ld B, $08
	call ToggleBits
	jp @setapu

@toggleSweepDir:
	ld HL, PU1_SWEEP
	ld B, $08
	call ToggleBits
	jp @setapu

@toggleAutostop:
	ld HL, PU1_FREQH
	ld B, $40
	call ToggleBits
	jp @setapu

@toggleRetrigger:
	ld HL, PU1_FREQH
	ld B, $80
	call ToggleBits
	jp @setapu

;----------------------------------------------------------------

@setPanning:
	in $FF25 ; NR51
	bit _JP_LEFT, E
	jr Z, +
	xor $10
+	bit _JP_RIGHT, E
	jr Z, +
	xor $01
+	out $FF25 ; NR51
	jp @setapu

@setVolume:
	ld HL, PU1_ENV
	ld A, (HL)
	bit _JP_LEFT, E
	jr Z, +
	sub $10
	jr ++
+	add $10
	jr ++

@setDuty:
	ld HL, PU1_LENGTH
	ld A, (HL)
	bit _JP_LEFT, E
	jr Z, +
	sub $40
	jr ++
+	add $40
++
	call SaveReg
	jp @setapu

@setLength:
	ld HL, PU1_LENGTH
	ld A, (HL)
	and $C0
	ld B, A
	ld A, (HL)

	bit _JP_LEFT, E
	jr Z, +
	dec A
	jr ++
+	inc A
++

	and $3F
	or B
	ld (HL), A
	jp @setapu

@setEnvRate:
	ld HL, PU1_ENV
	ld B, (HL)
	ld A, B
	and $F8
	ld (HL), A

	bit _JP_LEFT, E
	jr Z, +
	dec B
	jr ++

+	inc B
	jr ++

@setSweepStep:
	ld HL, PU1_SWEEP
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

@setEnvSweepRate:
	ld HL, PU1_SWEEP
	ld A, (HL)

	bit _JP_LEFT, E
	jr Z, +
	sub $10
	jr ++
+	add $10
++

	ld (HL), A
	jp @setapu

@setFrequency:
	ld HL, PU1_FREQL
	ld C, (HL)
	inc HL
	ld B, (HL)

	ld A, (HL)
	and $C0
	ldd (HL), A

	bit _JP_LEFT, E
	jr Z, +
	dec BC
	jr ++
+	inc BC
++

	ld (HL), C
	inc HL

	ld A, B
	and $07
	or (HL)
	ld (HL), A

	jp @setapu

.ENDS