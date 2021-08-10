
	include "nesdefs.dasm"
        include "vcs.h"

;;;;; VARIABLES

; 40 - 45 atari registers

var0		= $4A
var1		= $4B
var2		= $4C
var3		= $4D


; 54 - 57 atari registers

ScanLine	= $58 ; which scanline we're currently on
LineCycles	= $59 ; how many cycles since the scanline started

Sprite0H	= $5A
Sprite1H	= $5B
Sprite2H	= $5C
Sprite3H	= $5D
Sprite4H	= $5E



; Interrupt Handler

IntrID		= $65
BranchHead	= $66

IntA		= $67
IntX		= $68
IntY		= $69
IntS		= $6A

; Temporary Pointers

TCachePtr	= $6B
TROMPtr		= $6D
RollOver	= $6F

; FREE
PlayField	= $70



; TIA I/O registers and timers
IORead		= $100
IOWrite		= $108

; Translator
OpCode		= $3C1
AddrLo		= $3C2
AddrHi		= $3C3
InstSize	= $3C5
InstType	= $3C6

NESInstSize	= $3C7
NESOpCode	= $3C9
NESAddrLo	= $3CA
NESAddrHi	= $3CB

;;;---
BlockCycles	= $3CE
ATRPC		= $3D1
NESPC		= $3D5
BlockIndex	= $3D7

CacheFree	= $3D9
CacheOldest	= $3DB

; jumps table, segmented into 4 parts for low/high bytes
JATRLO	= $300
JATRHI	= $340
JNESLO	= $380
JNESHI	= $3C0
JSIZE	= $400
JCYCLES	= $440
JINTLO	= $480
JINTHI	= $4C0

CodeBlocks	= $500


INS_PHP		= $08
INS_JSR		= $20
INS_PHA		= $48
INS_NOP		= $ea
INS_JMP_ABS	= $4c
INS_STA_ZPG	= $85
INS_LDA_IMM	= $a9

ROM_RESET	= $f000
ROM_IRQ		= $f10f

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
        
        ldx #$3f
.loop
        lda #$ff
        sta JNESHI,x
        dex
        bpl .loop
        
        lda #<CodeBlocks
        sta CacheFree
        lda #>CodeBlocks
        sta CacheFree+1
	lda #$3f
        sta CacheOldest

        lda #$f0
        sta TROMPtr+1
        
        lda #$e3
        sta BranchHead
        
	jmp SetNESPC




	org $d000
NMIHandler:
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
        rti


;;;;; COMMON SUBROUTINES


	include "interrupt.asm"
	include "blocks.asm"
	include "translate.asm"
	include "execute.asm"


	org $e000

	include "data.asm"
        
	include "nesppu.dasm"

	.org $e300
	bpl .branched
	rts
        .byte
        bmi .branched
	rts
        .byte
        bvc .branched
	rts
        .byte
        bvs .branched
	rts
        .byte
        bcc .branched
	rts
        .byte
        bcs .branched
	rts
        .byte
        bne .branched
	rts
        .byte
        beq .branched
	rts
.branched
	txa
        rts



	org $f000
	incbin "rom.a26"
        incbin "rom.a26"

	incbin "tiles.chr"