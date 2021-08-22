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

ReadPlayfieldLeft: subroutine
	inc PlayfieldHalf
	; Playfield Byte 0
        lda PF0
        
        ; Tile 0        
        ror
        rol PlayField
        ror
        rol PlayField
        
        ; Tile 1
        ror
        rol PlayField+1
        ror
        rol PlayField+1
        
        ; Playfield Byte 1
        lda PF1

        ; Tile 2
        rol
        rol PlayField+2
        rol
        rol PlayField+2
        
        rol
        rol PlayField+3
        rol
        rol PlayField+3
        
        rol
        rol PlayField+4
        rol
        rol PlayField+4
        
        rol
        rol PlayField+5
        rol
        rol PlayField+5
        
        ; PlayField Byte 2
        lda PF2
        
        ; Tile 6
        ror
        rol PlayField+6
        ror
        rol PlayField+6
        
        ror
        rol PlayField+7
        ror
        rol PlayField+7
        
        ror
        rol PlayField+8
        ror
        rol PlayField+8
        
        ror
        rol PlayField+9
        ror
        rol PlayField+9
        
        rts


ReadPlayfieldRightNormal: subroutine
	; Playfield Byte 0
        lda PF0
        
        ; Tile 0        
        ror
        rol PlayField+10
        ror
        rol PlayField+10
        
        ; Tile 1
        ror
        rol PlayField+11
        ror
        rol PlayField+11
        
        ; Playfield Byte 1
        lda PF1

        ; Tile 2
        rol
        rol PlayField+12
        rol
        rol PlayField+12
        
        rol
        rol PlayField+13
        rol
        rol PlayField+13
        
        rol
        rol PlayField+14
        rol
        rol PlayField+14
        
        rol
        rol PlayField+15
        rol
        rol PlayField+15
        
        ; PlayField Byte 2
        lda PF2
        
        ; Tile 6
        ror
        rol PlayField+16
        ror
        rol PlayField+16
        
        ror
        rol PlayField+17
        ror
        rol PlayField+17
        
        ror
        rol PlayField+18
        ror
        rol PlayField+18
        
        ror
        rol PlayField+19
        ror
        rol PlayField+19

        rts	
        
ReadPlayfieldRightMirrored: subroutine
	; Playfield Byte 0
        lda PF0
        
        ; Tile 0        
        ror
        rol PlayField+19
        ror
        rol PlayField+19
        
        ; Tile 1
        ror
        rol PlayField+18
        ror
        rol PlayField+18
        
        ; Playfield Byte 1
        lda PF1

        ; Tile 2
        rol
        rol PlayField+17
        rol
        rol PlayField+17
        
        rol
        rol PlayField+16
        rol
        rol PlayField+16
        
        rol
        rol PlayField+15
        rol
        rol PlayField+15
        
        rol
        rol PlayField+14
        rol
        rol PlayField+14
        
        ; PlayField Byte 2
        lda PF2
        
        ; Tile 6
        ror
        rol PlayField+13
        ror
        rol PlayField+13
        
        ror
        rol PlayField+12
        ror
        rol PlayField+12
        
        ror
        rol PlayField+11
        ror
        rol PlayField+11
        
        ror
        rol PlayField+10
        ror
        rol PlayField+10

        rts