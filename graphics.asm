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
        
        lda ScanLine
        asl
        asl
        clc
        adc #$8A
        sta .BUFF_ADDR_LO
        lda .BUFF_ADDR_HI
        adc #0
        sta .BUFF_ADDR_HI
        
        ; Tiles
        ldy #0
        ldx #19
.copy
        lda Playfield,x
        sta .BUFF_DATA,x
        tya
        sta Playfield,x
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
        

	; these could be defined with arguments maybe for left and right
        
	MAC UPDATE_TILES_LEFT
        lda PFLeft0
        lsr
        lsr
        lsr
        lsr
        ror
        rol Playfield
        ror
        rol Playfield
        
        ror
        rol Playfield+1
        ror
        rol Playfield+1
        
        lda PFLeft1
        rol
        rol Playfield+2
        rol
        rol Playfield+2
        
        rol
        rol Playfield+3
        rol
        rol Playfield+3
        
        rol
        rol Playfield+4
        rol
        rol Playfield+4
        
        rol
        rol Playfield+5
        rol
        rol Playfield+5
        
        lda PFLeft2
        ror
        rol Playfield+6
        ror
        rol Playfield+6
        
        ror
        rol Playfield+7
        ror
        rol Playfield+7
        
        ror
        rol Playfield+8
        ror
        rol Playfield+8
        
        ror
        rol Playfield+9
        ror
        rol
        rol Playfield+9
        ENDM
        
	MAC UPDATE_TILES_RIGHT_MIRRORED
        lda PFRight0
        lsr
        lsr
        lsr
        lsr
        ror
        rol Playfield+10
        ror
        rol Playfield+10
        
        ror
        rol Playfield+11
        ror
        rol Playfield+11
        
        lda PFRight1
        rol
        rol Playfield+12
        rol
        rol Playfield+12
        
        rol
        rol Playfield+13
        rol
        rol Playfield+13
        
        rol
        rol Playfield+14
        rol
        rol Playfield+14
        
        rol
        rol Playfield+15
        rol
        rol Playfield+15
        
        lda PFRight2
        ror
        rol Playfield+16
        ror
        rol Playfield+16
        
        ror
        rol Playfield+17
        ror
        rol Playfield+17
        
        ror
        rol Playfield+18
        ror
        rol Playfield+18
        
        ror
        rol Playfield+19
        ror
        rol Playfield+19
        ENDM
        
	MAC UPDATE_TILES_RIGHT
        lda PFRight0
        lsr
        lsr
        lsr
        lsr
        ror
        rol Playfield+19
        ror
        rol Playfield+19
        
        ror
        rol Playfield+18
        ror
        rol Playfield+18
        
        lda PFRight1
        rol
        rol Playfield+17
        rol
        rol Playfield+17
        
        rol
        rol Playfield+16
        rol
        rol Playfield+16
        
        rol
        rol Playfield+15
        rol
        rol Playfield+15
        
        rol
        rol Playfield+14
        rol
        rol Playfield+14
        
        lda PFRight2
        ror
        rol Playfield+13
        ror
        rol Playfield+13
        
        ror
        rol Playfield+12
        ror
        rol Playfield+12
        
        ror
        rol Playfield+11
        ror
        rol Playfield+11
        
        ror
        rol Playfield+10
        ror
        rol Playfield+10
        ENDM
        
