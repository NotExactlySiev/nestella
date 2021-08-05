
	include "nesdefs.dasm"

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

INS_PHP	= $08
INS_PHA	= $48
INS_JMP_ABS	= $4c
INS_STA_ZPG	= $85
INS_LDA_IMM	= $a9



INT_SYNC	= 0
INT_TIME	= 2

INT_RETN	= 8
INT_IREQ	= 10
INT_JMPA	= 12
INT_JMPI	= 14
INT_COND	= 16


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
        

	jmp ResumeProgram





NMIHandler:
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
        rti


;;;;; COMMON SUBROUTINES


	include "interrupt.asm"

	include "blocks.asm"
	include "translate.asm"

	include "execute.asm"


; increments a 16 bit pointer
IncP16: subroutine
	sta var0
        lda #0
        sta var1
	tay
	clc
        lda (var0),y
        adc #1
        sta (var0),y
        iny
        lda (var0),y
        adc #0
        sta (var0),y
        rts

; 0 do nothing. implied or accumulator
; 1 do nothing. immediate
; 2 is a jump. implied
; 3 is a jump. 2 byte addr
; 4 memory read. 1 byte addr
; 5 memory write. 1 byte addr
; 6 memory read. 2 byte addr
; 7 memory write. 2 byte addr
; 8 conditional
; ff illegal opcode

	org $e000
InstTypes:
        .hex 02 04 ff ff ff 04 05 ff 00 01 00 ff ff 06 07 ff
        .hex 08 04 ff ff ff 04 05 ff 00 06 ff ff ff 06 07 ff
        .hex 03 04 ff ff 04 04 05 ff 00 01 00 ff 06 06 07 ff
        .hex 08 04 ff ff ff 04 05 ff 00 06 ff ff ff 06 07 ff
        .hex 02 04 ff ff ff 04 05 ff 00 01 00 ff 03 06 07 ff
        .hex 08 04 ff ff ff 04 05 ff 00 06 ff ff ff 06 07 ff
        .hex 02 04 ff ff ff 04 05 ff 00 01 00 ff 03 06 07 ff
        .hex 08 04 ff ff ff 04 05 ff 00 06 ff ff ff 06 07 ff
        .hex ff 05 ff ff 05 05 05 ff 00 ff 00 ff 07 07 07 ff
        .hex 08 05 ff ff 05 05 05 ff 00 07 00 ff ff 07 ff ff
        .hex 01 04 01 ff 04 04 04 ff 00 01 00 ff 06 06 06 ff
        .hex 08 04 ff ff 04 04 04 ff 00 06 00 ff 06 06 06 ff
        .hex 01 04 ff ff 04 04 05 ff 00 01 00 ff 06 06 07 ff
        .hex 08 04 ff ff ff 04 05 ff 00 06 ff ff ff 06 07 ff
        .hex 01 04 ff ff 04 04 05 ff 00 01 00 ff 06 06 07 ff
        .hex 08 04 ff ff ff 04 05 ff 00 06 ff ff ff 06 07 ff

	; how many minimum cycles each opcode takes
Cycles:
        .hex 07 06 ff ff ff 03 05 ff 03 02 02 ff ff 04 06 ff
        .hex 02 05 ff ff ff 04 06 ff 02 04 ff ff ff 04 07 ff
        .hex 06 06 ff ff 03 03 05 ff 04 02 02 ff 04 04 06 ff
        .hex 02 05 ff ff ff 04 06 ff 02 04 ff ff ff 04 07 ff
        .hex 06 06 ff ff ff 03 05 ff 03 02 02 ff 03 04 06 ff
        .hex 02 05 ff ff ff 04 06 ff 02 04 ff ff ff 04 07 ff
        .hex 06 06 ff ff ff 03 05 ff 04 02 02 ff 05 04 06 ff
        .hex 02 05 ff ff ff 04 06 ff 02 04 ff ff ff 04 07 ff
        .hex 03 06 ff ff 03 03 03 ff 02 ff 02 ff 04 04 04 ff
        .hex 02 06 ff ff 04 04 04 ff 02 05 02 ff ff 05 ff ff
        .hex 02 06 02 ff 03 03 03 ff 02 02 02 ff 04 04 04 ff
        .hex 02 05 ff ff 04 04 04 ff 02 04 02 ff 04 04 04 ff
        .hex 02 06 ff ff 03 03 05 ff 02 02 02 ff 04 04 03 ff
        .hex 02 05 ff ff ff 04 06 ff 02 04 ff ff ff 04 07 ff
        .hex 02 06 ff ff 03 03 05 ff 02 02 02 ff 04 04 06 ff
        .hex 02 05 ff ff ff 04 06 ff 02 04 ff ff ff 04 07 ff

InstSizes:
	.byte 1, 2, 1, 3, 2, 2, 3, 3, 2

	include "nesppu.dasm"

	org $f000
        incbin "rom.a26"
