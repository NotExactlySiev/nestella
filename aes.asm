
	include "nesdefs.dasm"
        include "vcs.h"

;;;;; VARIABLES

; 40 - 45 atari registers

var0		= $4A
var1		= $4B
var2		= $4C
var3		= $4D

Mode		= $50 ; running, translating, interrupt

; 54 - 57 atari registers

ATRPC		= $60
NESPC		= $62
TableIdx	= $64

; Interrupt Handler

IntrID		= $65
BranchShift	= $66

IntA		= $67
IntX		= $68
IntY		= $69
IntS		= $6A

; Translator

BlockPC		= $6E

TCachePtr	= $70
TROMPtr		= $72

BlockIndex	= $74

OpCode		= $75
AddrLo		= $76
AddrHi		= $77
InstSize	= $78
InstType	= $79

NESOpCode	= $7A
NESAddrLo	= $7B
NESAddrHi	= $7C
NESInstSize	= $7D

BlockSize	= $7E
BlockCycles	= $7F

; TIA I/O registers and timers
IORead		= $100
IOWrite		= $108

; jumps table, segmented into 4 parts for low/high bytes
Jumps	= $300
JATRLO	= $300
JATRHI	= $340
JNESLO	= $380
JNESHI	= $3C0
JSIZE	= $400
JCYCLES	= $440

CodeBlocks	= $480
BranchCode	= $7FB


INS_PHP	= $08
INS_PHA	= $48
INS_NOP	= $ea
INS_JMP_ABS	= $4c
INS_STA_ZPG	= $85
INS_LDA_IMM	= $a9

ROM_RESET	= $f000

	seg.u ZEROPAGE
	org $0

;;;;; NES CARTRIDGE HEADER


	NES_HEADER 0,1,1,0 ; mapper 0, 1 PRGs, 1 CHR, horiz. mirror

;;;;; START OF CODE
Start:
	NES_INIT
	jsr ClearRAM
	lda #$3f	; $3F -> A register
        sta PPU_ADDR	; write high byte first
	lda #$00	; $00 -> A register
        sta PPU_ADDR    ; $3F00 -> PPU address
        lda #$1c	; $1C = light blue color
        sta PPU_DATA    ; $1C -> PPU data
; activate PPU graphics
        lda #MASK_BG	; A = $08
        sta PPU_MASK	; enable rendering
        lda #CTRL_NMI	; A = $80
        sta PPU_CTRL	; enable NMI      
	lda #$00
        sta ATRPC
        lda #$f0
        sta ATRPC+1
        
        lda #<CodeBlocks
        sta TCachePtr
        lda #>CodeBlocks
        sta TCachePtr+1

        lda #$f0
        sta TROMPtr+1
        
	ldx #$4
CopyBranchCode
        lda BranchTemplate,x
        sta BranchCode,x
        dex
        bpl CopyBranchCode

	jmp SetNESPC




	org $d000
NMIHandler:
	php
        pha
        tya
        pha
        txa
        pha
        
	PPU_SETADDR $3f00
	lda $9
        lsr
        and #$30
        sta $80
        lda $9
        and #$0f
        ora $80
        
        sta PPU_DATA
        lda #0
        sta PPU_ADDR
        sta PPU_ADDR
        
        pla
        tax
        pla
        tay
        pla
        plp
        rti


;;;;; COMMON SUBROUTINES


	include "interrupt.asm"
	include "blocks.asm"
	include "translate.asm"
	include "execute.asm"


	org $e000

	include "data.asm"
        
	include "nesppu.dasm"

	org $f000
        incbin "rom.a26"

	incbin "tiles.chr"