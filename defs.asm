;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ROM Board type defs (SRAM = battery backed RAM)

;       ID                       ; Max ROM ; Max RAM ; Notes
.DEFINE BOARD_ROM            $00 ; 32KB    ; none    ; 
.DEFINE BOARD_MBC1           $01 ; 2MB     ; none    ; 
.DEFINE BOARD_MBC1_RAM       $02 ; 2MB     ; 32KB    ; 
.DEFINE BOARD_MBC1_SRAM      $03 ; 2MB     ; 32KB    ; 
.DEFINE BOARD_MBC2           $05 ; 256KB   ; 256b    ; 512x4bit SRAM
.DEFINE BOARD_MBC2_SRAM      $06 ; 256KB   ; 256b    ; 512x4bit SRAM
.DEFINE BOARD_ROM_RAM        $08 ; 32KB    ; 8KB     ; 
.DEFINE BOARD_ROM_SRAM       $09 ; 32KB    ; 8KB     ; 
.DEFINE BOARD_MMM01          $0B ; 8MB     ; none    ; 
.DEFINE BOARD_MMM01_RAM      $0C ; 8MB     ; 128KB   ; 
.DEFINE BOARD_MMM01_SRAM     $0D ; 8MB     ; 128KB   ; 
.DEFINE BOARD_MBC3_RTC       $0F ; 2MB     ; none    ; 
.DEFINE BOARD_MBC3_RTC_SRAM  $10 ; 2MB     ; 64KB    ; 
.DEFINE BOARD_MBC3           $11 ; 2MB     ; none    ; 
.DEFINE BOARD_MBC3_RAM       $12 ; 2MB     ; 64KB    ; 
.DEFINE BOARD_MBC3_SRAM      $13 ; 2MB     ; 64KB    ; 
.DEFINE BOARD_MBC5           $19 ; 8MB     ; none    ; 
.DEFINE BOARD_MBC5_RAM       $1A ; 8MB     ; 128KB   ; 
.DEFINE BOARD_MBC5_SRAM      $1B ; 8MB     ; 128KB   ; 
.DEFINE BOARD_MBC5_RUMB      $1C ; 8MB     ; none    ; 
.DEFINE BOARD_MBC5_RUMB_RAM  $1D ; 8MB     ; 128KB   ; 
.DEFINE BOARD_MBC5_RUMB_SRAM $1E ; 8MB     ; 128KB   ; 
.DEFINE BOARD_MBC6           $20 ;         ; 32KB    ; implies SRAM; used in 1 game
.DEFINE BOARD_MBC7           $22 ;         ; 256b    ; implies Accelerometer, Rumble and Serial EEPROM
.DEFINE BOARD_POCKETCAM      $FC ;         ;         ; 
.DEFINE BOARD_TAMA5          $FD ;         ;         ; 
.DEFINE BOARD_HuC3           $FE ;         ; 32KB    ; implies RTC, IR and SRAM
.DEFINE BOARD_HuC1_SRAM      $FF ;         ; 32KB    ; implies IR and SRAM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; (S)RAM Size defs
.DEFINE RAM_NONE  $00
.DEFINE RAM_8KB   $02
.DEFINE RAM_32KB  $03 ; 4x8KB banks
.DEFINE RAM_64KB  $05 ; 8x8KB banks
.DEFINE RAM_128KB $04 ; 16x8KB banks

.INCLUDE "..\.common\regs.asm"
