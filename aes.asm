
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

ColorSection	= $124

DrawAddr	= $130
DrawBuffer	= $132
BGColor		= $146
PFColor		= $147
UpdateColor	= $148


PaletteCounter	= $150 ; counts tiles and sets the palette after 6 tiles

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

CACHE_MAX_BLOCKS	= $40
CACHE_BLOCKS_END	= $7FF

INS_PHP		= $08
INS_JSR		= $20
INS_PHA		= $48
INS_NOP		= $ea
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
    
	lda #<ROM_RESET
        sta ATRPC
        lda #>ROM_RESET
        sta ATRPC+1
        
        ; initialize the cache NES values to maximum, so they immidiately end cache invalidation the first time
        ldx #CACHE_MAX_BLOCKS-1
.loop
        lda #$ff
        sta JNESHI,x
        sta JNESLO,x
        dex
        bpl .loop
        
        lda #<CodeBlocks
        sta CacheFree
        lda #>CodeBlocks
        sta CacheFree+1
	lda #CACHE_MAX_BLOCKS-1
        sta CacheOldest

	lda #<ROM_RESET
        sta TROMPtr
        lda #>ROM_RESET
        sta TROMPtr+1
        
        lda #$E3
        sta BranchHead


        ldy #5
        sty PaletteCounter
SetColors        
        lda #$23
        sta PPU_ADDR
        tya
        asl
        asl
        asl
        clc
        adc #$c9
        sta PPU_ADDR
        
        ldx #6
        lda Attributes,y
.write        
        sta PPU_DATA
        dex
        bne .write
        
        dey
        bpl SetColors
        
        
        lda #0
        sta PPU_ADDR
        sta PPU_ADDR
        
        
        lda #MASK_BG
        sta PPU_MASK	; enable rendering
        lda #CTRL_NMI
        sta PPU_CTRL	; enable NMI          
        
        
        
	jmp SetNESPC

Attributes:
	.byte $00, $50, $55, $AA, $FA, $FF


	org $d000
NMIHandler: subroutine
        pha
        tya
        pha
        txa
        pha
        
        ; count how many scanlines in each frame
        lda ScanLine
        sec
        sbc $202
        sta $203
        lda ScanLine
        sta $202
        
        
        lda DrawAddr
        beq .ndraw
        
        lda DrawAddr+1
        clc
        adc #$26
        sta var2
        lda DrawAddr
        adc #0
        sta PPU_ADDR
        lda var2
        sta PPU_ADDR
        
        ldx #0
.loop
        lda DrawBuffer,x
        sta PPU_DATA
        inx
        cpx #10
        bcc .loop
        
        lda #0
        sta DrawAddr
        
.ndraw
        
        ldx UpdateColor
        beq .ncolor
        
        txa
        asl
        asl
        tax
        inx
        lda #$3f
        sta PPU_ADDR
        stx PPU_ADDR
        
        lda BGColor
        sta PPU_DATA
        sta PPU_DATA
        lda PFColor
        sta PPU_DATA

	
.ncolor
        
        lda #0
        sta PPU_ADDR
        sta PPU_ADDR
        
        ;include "input.asm"
        
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

	include "sync.asm"

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

	org $effa
        ; Atari Vectors
        .hex 1E 84 00 F0 00 00

	org $f000
	incbin "rom.a26"

	incbin "tiles.chr"