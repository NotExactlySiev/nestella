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

ReadPlayfieldNormal: subroutine
	; Playfield Byte 0
	; Tile 0
        lda PF0
        ror
        rol PlayField
        ror PF0
        rol PlayField+10
        
	lda PF0
        ror
        rol PlayField
        ror PF0
        rol PlayField+10

	; Tile 1
        lda PF0
        ror
        rol PlayField+1
        ror PF0
        rol PlayField+11
        
        lda PF0
        ror
        rol PlayField+1
        ror PF0
        rol PlayField+11        

	; Playfield Byte 1
	; Tile 2
        lda PF1
        rol
        rol PlayField+2
        rol PF1
        rol PlayField+12
        
        lda PF1
        rol
        rol PlayField+2
        rol PF1
        rol PlayField+12
        
        ; Tile 3
        lda PF1
        rol
        rol PlayField+3
        rol PF1
        rol PlayField+13
        
        lda PF1
        rol
        rol PlayField+3
        rol PF1
        rol PlayField+13  
        
        ; Tile 4
        lda PF1
        rol
        rol PlayField+4
        rol PF1
        rol PlayField+14
        
        lda PF1
        rol
        rol PlayField+4
        rol PF1
        rol PlayField+14
        
        ; Tile 5
        lda PF1
        rol
        rol PlayField+5
        rol PF1
        rol PlayField+15
        
        lda PF1
        rol
        rol PlayField+5
        rol PF1
        rol PlayField+15  
        
        ; Playfield Byte 2
        ; Tile 6
        lda PF2
        ror
        rol PlayField+6
        ror PF2
        rol PlayField+16
        
        lda PF2
        ror
        rol PlayField+6
        ror PF2
        rol PlayField+16  
        
        ; Tile 7
        lda PF2
        ror
        rol PlayField+7
        ror PF2
        rol PlayField+17
        
        lda PF2
        ror
        rol PlayField+7
        ror PF2
        rol PlayField+17  
        
        ; Tile 8
        lda PF2
        ror
        rol PlayField+8
        ror PF2
        rol PlayField+18
        
        lda PF2
        ror
        rol PlayField+8
        ror PF2
        rol PlayField+18  
        
        ; Tile 9
        lda PF2
        ror
        rol PlayField+9
        ror PF2
        rol PlayField+19
        
        lda PF2
        ror
        rol PlayField+9
        ror PF2
        rol PlayField+19
        
        rts
        
ReadPlayfieldMirrored: subroutine
	; Playfield Byte 0
	; Tile 0
        lda PF0
        ror
        rol PlayField
        ror PF0
        rol PlayField+19
    
	lda PF0
        ror
        rol PlayField
        ror PF0
        rol PlayField+19

	; Tile 1
        lda PF0
        ror
        rol PlayField+1
        ror PF0
        rol PlayField+18
        
        lda PF0
        ror
        rol PlayField+1
        ror PF0
        rol PlayField+18        

	; Playfield Byte 1
	; Tile 2
        lda PF1
        rol
        rol PlayField+2
        rol PF1
        rol PlayField+17
        
        lda PF1
        rol
        rol PlayField+2
        rol PF1
        rol PlayField+17
        
        ; Tile 3
        lda PF1
        rol
        rol PlayField+3
        rol PF1
        rol PlayField+16
        
        lda PF1
        rol
        rol PlayField+3
        rol PF1
        rol PlayField+16 
        
        ; Tile 4
        lda PF1
        rol
        rol PlayField+4
        rol PF1
        rol PlayField+15
        
        lda PF1
        rol
        rol PlayField+4
        rol PF1
        rol PlayField+15
        
        ; Tile 5
        lda PF1
        rol
        rol PlayField+5
        rol PF1
        rol PlayField+14
        
        lda PF1
        rol
        rol PlayField+5
        rol PF1
        rol PlayField+14
        
        ; Playfield Byte 2
        ; Tile 6
        lda PF2
        ror
        rol PlayField+6
        ror PF2
        rol PlayField+13
        
        lda PF2
        ror
        rol PlayField+6
        ror PF2
        rol PlayField+13
        
        ; Tile 7
        lda PF2
        ror
        rol PlayField+7
        ror PF2
        rol PlayField+12
        
        lda PF2
        ror
        rol PlayField+7
        ror PF2
        rol PlayField+12
        
        ; Tile 8
        lda PF2
        ror
        rol PlayField+8
        ror PF2
        rol PlayField+11
        
        lda PF2
        ror
        rol PlayField+8
        ror PF2
        rol PlayField+11
        
        ; Tile 9
        lda PF2
        ror
        rol PlayField+9
        ror PF2
        rol PlayField+10
        
        lda PF2
        ror
        rol PlayField+9
        ror PF2
        rol PlayField+10
        
        rts