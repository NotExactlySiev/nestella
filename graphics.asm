	MAC FILL_BUFFER
.BUFF_ADDR_HI set DrawBuffer0 + ({1} * 24)
.BUFF_ADDR_LO set .BUFF_ADDR_HI+1
.BUFF_DATA    set .BUFF_ADDR_HI+2
        lda ScanLine
        rol
        rol
        rol
        and #$3
        ora #$20
        sta .BUFF_ADDR_HI
        
        ldy ScanLine
        iny
        tya
        asl
        asl
        clc
        adc #$86
        sta .BUFF_ADDR_LO
        lda .BUFF_ADDR_HI
        adc #0
        sta .BUFF_ADDR_HI
        
        ; Tiles
        ldy #0
        ldx #19
.copy
        lda PlayField,x
        sta .BUFF_DATA,x
        tya
        sta PlayField,x
        dex
        bpl .copy
	ENDM

        MAC DRAW_BUFFER
.BUFF_ADDR_HI set DrawBuffer0 + ({1} * 24)
.BUFF_ADDR_LO set .BUFF_ADDR_HI+1
.BUFF_DATA    set .BUFF_ADDR_HI+2
        lda .BUFF_ADDR_HI
        beq .ndraw

        lda .BUFF_ADDR_HI
        sta PPU_ADDR
        lda .BUFF_ADDR_LO
        sta PPU_ADDR
        
        ldx #0
.loop
        lda .BUFF_DATA,x
        sta PPU_DATA
        inx
        cpx #20
        bcc .loop
        
        lda #0
        sta .BUFF_ADDR_HI
.ndraw
	ENDM

ConvertColor: subroutine
	; swap chroma and luma, if it's 0 just return black instead of grey
        sta var3
	bne .nblack
        lda #$0d
        rts
.nblack
        asl
        asl
        and #$30
        sta $2 ; we can use this as a temporary var
        lda var3
        lsr
        lsr
        lsr
        lsr
        cmp #$d
        bcc .nblackest
        lda #$c
.nblackest
        ora $2
	rts