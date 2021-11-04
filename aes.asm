
	include "nesdefs.dasm"
        include "vcs.h"

;;;;; VARIABLES



; 40 - 45 atari registers

var0		= $46 ; used by interrupt handler!!!!!
var1		= $47 ; used by interrupt handler!!!!! be careful
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




BGColor		= $110
PFColor		= $111
UpdateColor	= $112
ColorSection	= $113 ; which quarter of the screen we're in
PaletteCounter	= $114 ; counts tiles and sets the palette after 6 tiles
Playfield	= $115 ; - $128

; six 24 byte buffers should be enough jesus christ
DrawBuffer0	= $130
DrawBuffer1	= $148
DrawBuffer2	= $160
DrawBuffer3	= $178
DrawBuffer4	= $190
DrawBuffer5	= $1A8 ; - $1BF

PF0old		= $1C0
PF1old		= $1C1
PF2old		= $1C2

PFLeft0		= $1C3
PFLeft1		= $1C4
PFLeft2		= $1C5
PFRight0	= $1C6
PFRight1	= $1C7
PFRight2	= $1C8
LineCycles	= $1C9 ; how many cycles since the scanline started
LastDrawnPixel	= $1CA
FreeSprite	= $1CB

TimerCycles	= $1CC ; 10 bit value, stored a bit weird
TimerCounter	= $1CE
TimerInterval	= $1CF

;;;---
ATRPC		= $2F1
IntS		= $2F3
NESPC		= $2F5
BlockIndex	= $2F7

CacheFree	= $2F9
CacheOldest	= $2FB

; cache table
JATRLO	= $300
JATRHI	= $340
JNESLO	= $380
JNESHI	= $3C0
JCYCLES	= $400
JINTLO	= $440
JINTHI	= $480
JINTREL	= $4C0

CodeBlocks	= $500

CACHE_BLOCKS	= $8
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
    
	lda #0
        sta OAM_ADDR
    
	lda #<ROM_RESET
        sta ATRPC
        lda #>ROM_RESET
        sta ATRPC+1
        
        ; initialize the cache NES values to maximum, so they immidiately end cache invalidation the first time
        ldx #CACHE_BLOCKS-1
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
	lda #CACHE_BLOCKS-1
        sta CacheOldest

	lda #<ROM_RESET
        sta TROMPtr
        lda #>ROM_RESET
        sta TROMPtr+1
        
        lda #$E3
        sta BranchHead

	lda #-22
        sta LineCycles
        
        lda #0
        sta TimerCycles
        lda #0
        sta TimerCounter
        lda #$d
        sta $104

	; temporary static sprite palette
	lda #$3f
        sta PPU_ADDR
        lda #$11
        sta PPU_ADDR
        lda #$06
        sta PPU_DATA
	sta PPU_DATA
        sta PPU_DATA

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
        sta PPU_SCROLL
        sta PPU_SCROLL
        
        
        lda #MASK_BG | MASK_SPR
        sta PPU_MASK	; enable rendering
        lda #CTRL_NMI | CTRL_SPR_1000
        sta PPU_CTRL	; enable NMI          
        
        
        
	jmp SetNESPC

Attributes:
	.byte $00, $50, $55, $AA, $FA, $FF



;;;;; COMMON SUBROUTINES


	include "sprite.asm"
	include "timer.asm"
	include "graphics.asm"
	include "interrupt.asm"
	include "blocks.asm"
	include "translate.asm"
	include "execute.asm"
	include "sync.asm"
        include "input.asm"

	org $d000
	include "nmi.asm"


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
        .hex ff ff 00 f0 a2 ff

	org $f000
        incbin "rom.a26"
	incbin "tiles.chr"