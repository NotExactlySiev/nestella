
	include "nesdefs.dasm"
        include "vcs.h"

;;;;; VARIABLES

; 40 - 45 atari registers

var0		= $46
var1		= $47
var2		= $48
var3		= $49

; Translator

NESInstSize	= $4A
NESOpCode	= $4B
NESAddrLo	= $4C
NESAddrHi	= $4D

OpCode		= $4E
AddrLo		= $4F
AddrHi		= $50
InstSize	= $51

InstType	= $52
; 54 - 57 atari registers
BlockCycles	= $58
BlockNESPCHi	= $59 ; this will also contain the interrupt type in it, so it's
		      ; stored in the table after the block is fully translated

; Rendering

ScanLine	= $5A ; which scanline we're currently on
LineCycles	= $5B ; how many cycles since the scanline started

Sprite0H	= $5C
Sprite1H	= $5D
Sprite2H	= $5E
Sprite3H	= $5F
Sprite4H	= $60



; Interrupt Handler

IntrID		= $61
BranchHead	= $62

IntA		= $63
IntX		= $64
IntY		= $65
IntP		= $66

; Temporary Pointers

TCachePtr	= $69
TROMPtr		= $6B
RollOver	= $6D

; - 7F Plafield Blocks


; TIA I/O registers and timers
IORead		= $100
IOWrite		= $108

PlayField	= $110


;;;---
ATRPC		= $2D1
IntS		= $180
NESPC		= $2D5
BlockIndex	= $2D7

CacheFree	= $2D9
CacheOldest	= $2DB

; jumps table, segmented into 4 parts for low/high bytes
JATRLO	= $300
JATRHI	= $340
JNESLO	= $380
JNESHI	= $3C0
JCYCLES	= $400
JINTLO	= $440
JINTHI	= $480
JINTREL	= $4C0

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

	lda #00
        sta TROMPtr
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