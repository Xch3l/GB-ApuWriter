.RAMSECTION "WAVE_RAM" SLOT SLOT_WRAM
	WAV_DATA   .dsb 5
	WAV_ENABLE db ; FF1A NR30
	WAV_LENGTH db ; FF1B NR31
	WAV_VOLUME db ; FF1C NR32
	WAV_FREQL  db ; FF1D NR33
	WAV_FREQH  db ; FF1E NR34

	WAVEFORM dsb 16 ; FF30-FF3F
	PEARLSEL db
.ENDS

.SECTION "WAVE_MENU" SLOT SLOT_ROM0

strWAV_MenuTitle: text "Wave"
;                       ::::::::::::::
strWAV_EnableDAC: text "Enable DAC"
strWAV_EditWave:  text "Edit waveform"

MenuWave:
	.db 9 ; option count
	.dw @vblank ; menu vblank
	.dw @loop   ; menu loop
	.dw strWAV_MenuTitle  ; menu title strptr

	; menu label strptrs
	.dw strChnPanning
	.dw strWAV_EnableDAC
	.dw strChnVolume
	.dw strChnLength
	.dw strChnFrequency
	.dw strChnAutostop
	.dw strChnRetrigger
	.dw strWAV_EditWave
	.dw strMenuReturn

	; menu callback ptrs
	.dw @togglePanning   ; 0: set panning
	.dw @toggleDAC       ; 1: toggle DAC
	.dw NopCall          ; 2: set volume
	.dw NopCall          ; 3: set length
	.dw NopCall          ; 4: set frequency
	.dw @toggleAutostop  ; 5: toggle autostop
	.dw @toggleRetrigger ; 6: toggle retrigger
	.dw EditWave         ; 7: edit wave
	.dw ReturnSubmenu

@vblank:
	ld HL, TEXTBUF

	ldi A, (HL) ; is playing
	ld (BG0+18), A
	ldi A, (HL) ; panning left
	ld (MENU_LINE1+17), A
	ldi A, (HL) ; panning right
	ld (MENU_LINE1+18), A
	ldi A, (HL) ; DAC enable
	ld (MENU_LINE2+18), A
	ld DE, MENU_LINE4+17 ; length
	ld B, 2
	call CopyBytes
	ldi A, (HL) ; volume
	ld (MENU_LINE3+18), A
	ldi A, (HL) ; autostop
	ld (MENU_LINE6+18), A
	ldi A, (HL) ; retrigger
	ld (MENU_LINE7+18), A
	ld DE, MENU_LINE5+16
	ld B, 3
	call CopyBytes
	ldi A, (HL) ; extra bit
	ld (MENU_LINE13+18), A

	ld HL, MENU_LINE11+2
	ld DE, MENU_LINE12+2
	ld B, 16
	ld A, $04
-	ldi (HL), A
	ld (DE), A
	inc DE
	dec B
	jr NZ, -

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
	.dw @setPanning      ; 0: set panning
	.dw @toggleDAC       ; 1: toggle DAC
	.dw @setVolume       ; 2: set volume
	.dw @setLength       ; 3: set length
	.dw @setFrequency    ; 4: set frequency
	.dw @toggleAutostop  ; 5: toggle autostop
	.dw @toggleRetrigger ; 6: toggle retrigger
	.dw NopCall          ; 7: edit wave
	.dw NopCall

@jtretn:
	call @setapu

@setbuf:
	ld HL, TEXTBUF

	; Is playing?
	in $FF26 ; NR52
	bit 2, A
	ld A, INVERTED_SPACE
	jr Z, +
	ld A, INVERTED_NOTE
+	ldi (HL), A

	; Parse panning
	in $FF25
	ld B, A

	ld A, LCH_OFF
	bit 6, B
	jr Z, +
	inc A
+	ldi (HL), A

	ld A, RCH_OFF
	bit 2, B
	jr Z, +
	inc A
+	ldi (HL), A

	; Parse enable bit
	ld BC, WAV_DATA
	ld A, (BC) ; DAC enable
	inc BC
	bit 7, A
	ld A, BOX_ICON
	jr Z, +
	inc A
+	ldi (HL), A

	; Parse length timer
	ld A, (BC)
	inc BC
	call PutHex

	; Parse volume
	ld A, (BC)
	inc BC
	inc BC
	swap A
	rra
	and $03
	call PutHexLo

	; Parse control flags
	ld A, (BC)
	ld D, A

	ld A, BOX_ICON
	bit 6, D
	jr Z, +
	inc A
+	ldi (HL), A

	ld A, BOX_ICON
	bit 7, D
	jr Z, +
	inc A
+	ldi (HL), A

	; Parse sample rate
	ld A, (BC)
	dec BC
	and 7
	call PutHexLo
	ld A, (BC)
	call PutHex

	ld (HL), $20

@drawWavePattern:
	; Draw wave pattern
	ld HL, OAMTABLE+16
	ld DE, WAVEFORM
	ld B, 16

-	ld A, (DE)
	swap A
	call SetPearl

	ld A, (DE)
	call SetPearl

	inc DE
	dec B
	jr NZ, -

	jp ShuffleOAMs

@setapu:
	out $FF1A, 0 ; disable DAC

	ld HL, WAVEFORM
	ld BC, $1030
	call WriteRegs

	ld HL, WAV_DATA
	ld BC, $051A
	jp WriteRegs

@showData:
	; Hide sprites
	in rLCDC
	res _LCDC_OBJ, A
	out rLCDC

	; Print register data
	ld HL, TEXTBUF2 ; set label
	ld DE, strData
	ld B, _sizeof_strData
-	ld A, (DE)
	inc DE
	ldi (HL), A
	dec B
	jr NZ, -

	ld DE, WAV_DATA ; print data
	ld B, 5
-	ld A, (DE)
	call PutHex
	ld (HL), ' '
	inc HL
	inc DE
	dec B
	jr NZ, -
	ld (HL), $00

	call @dataHold

@mmPrintWave:
	; Print waveform
	ld HL, TEXTBUF2
	ld DE, strWaveform
	ld B, _sizeof_strWaveform
-	ld A, (DE)
	inc DE
	ldi (HL), A
	dec B
	jr NZ, -

	ld DE, WAVEFORM
	ld C, 4
-	ld B, 4
--	ld A, (DE)
		call PutHex

		ld A, B
		cp 1
		jr Z, +
		ld A, ' '
		ldi (HL), A
		ldi (HL), A
+
		inc DE
		dec B
		jr NZ, --

		ld A, C
		cp 1
		jr Z, +
		ld (HL), '\n'
		inc HL
		ld A, ' '
		ldi (HL), A
		ldi (HL), A

+	dec C
	jr NZ, -
	ld (HL), $00

	call @dataHold

	; Show sprites
	in rLCDC
	set _LCDC_OBJ, A
	out rLCDC

	ret

@dataHold:
	ld DE, TEXTBUF2
	call InitPopup

-	rst VSync
	call ReadInput
	and JP_A|JP_B
	jr Z, -

	jp ClosePopup


;---------------------------------------------------------------

@togglePanning:
	in $FF25 ; NR51
	xor $44
	out $FF25
	jp @setapu

@toggleDAC ; toggle DAC
	ld HL, WAV_ENABLE
	ld B, $80
	call ToggleBits
	jp @setapu

@toggleAutostop ; toggle autostop
	ld HL, WAV_FREQH
	ld B, $40
	call ToggleBits
	jp @setapu

@toggleRetrigger ; toggle retrigger
	ld HL, WAV_FREQH
	ld B, $80
	call ToggleBits
	jp @setapu

;---------------------------------------------------------------

@setPanning:
	in $FF25 ; NR51
	bit _JP_LEFT, E
	jr Z, +
	xor $40
+	bit _JP_RIGHT, E
	jr Z, +
	xor $04
+	out $FF25 ; NR51
	jp @setapu

@setVolume:
	ld HL, WAV_VOLUME
	ld A, (HL)
	bit _JP_LEFT, E
	jr Z, +
	sub $20
	jr ++
+	add $20
++
	and $60
	ld (HL), A
	jp @setapu

@setLength:
	ld HL, WAV_LENGTH
	bit _JP_LEFT, E
	jr Z, +
	dec (HL)
	jp @setapu
+	inc (HL)
	jp @setapu

@setFrequency:
	ld HL, WAV_FREQL
	ld C, (HL)
	inc HL
	ld B, (HL)

	ld A, (HL)
	and $F8
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPearl:
	and $0F
	ld C, A

	ld A, $7D
	sub C
	ldi (HL), A ; y

	ld A, L
	and $FC
	add 8
	ldi (HL), A ; x

	ld A, L
	sub 18
	rra
	rra
	and 31
	ld C, A

	ld A, (PEARLSEL)
	cp C
	ld A, SPRITE0
	jr NZ, +
	inc A
+	ldi (HL), A ; t

	xor A
	ldi (HL), A ; a

	ret

EditWave:
	ld HL, PEARLSEL
	ld A, (HL)
	and 31
	ld (HL), A

	ld A, $F0 ; hide arrow sprite
	ld (OAMTABLE), A

@loop:
	rst VSync
	call ReadInput
	ld HL, PEARLSEL

	ld A, JP_START|JP_A
	and C
	jr Z, +
	call MenuWave@setapu
	jr @loop

+	bit _JP_B, C
	jr Z, +
	set 7, (HL)
	ret

+	ld A, (HL)

	bit _JP_LEFT, C
	jr Z, +
	dec A
	jr ++
+	bit _JP_RIGHT, C
	jr Z, ++
	inc A
++
	and 31
	ld (HL), A

	; Get index
	ld HL, WAVEFORM
	ld DE, $100F ; set mask
	rra
	jr NC, +
	ld DE, $01F0

+	add L
	ld L, A
	jr NC, +
	inc H
+	ld A, (HL) ; get sample pair

	and E
	ld B, A
	ld A, (HL)

	bit _JP_UP, C
	jr Z, +
	add D
	jr ++
+	bit _JP_DOWN, C
	jr Z, ++
	sub D

++
	swap E
	and E
	or B
	ld (HL), A

	; Print value
	bit 4, D
	jr Z, +
	swap A
+	ld HL, TEXTBUF+12
	call PutHexLo

	; Set pearls
	ld HL, OAMTABLE+16
	ld DE, WAVEFORM
	ld B, 16

-	ld A, (DE)
	swap A
	call SetPearl

	ld A, (DE)
	call SetPearl

	inc DE
	dec B
	jr NZ, -

	call ShuffleOAMs
	jp @loop

ShuffleOAMs:
	; Clear remaining OAMs
	ld A, L
	and $FC

-	ld L, A
	ld (HL), $F0
	add $04
	cp $A0
	jr NZ, -

	call GetRand ;FRAMENUM
	cp $A0
	jr C, +
	add $60
+	and $FC

	ld HL, OAMTABLE
	ld D, H
	ld E, A
	ld B, 40

-	ld C, (HL)
	ld A, (DE)
	ldi (HL), A
	ld A, C
	ld (DE), A
	inc DE

	dec B
	jr NZ, -

	ret

.ENDS
