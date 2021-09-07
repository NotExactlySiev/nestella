NMIHandler: subroutine
        pha
        tya
        pha
        txa
        pha
        
        lda #00
        sta PPU_CTRL
        
        ; count how many scanlines in each nes frame
        lda ScanLine
        sec
        sbc $202
        sta $203
        lda ScanLine
        sta $202
                        
        ldx UpdateColor
        beq .ncolor
        
        dex
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

	; draw the buffers if there's anything in them
        DRAW_BUFFER 0
	DRAW_BUFFER 1
        DRAW_BUFFER 2
        DRAW_BUFFER 3
        DRAW_BUFFER 4
        DRAW_BUFFER 5
        
        ldx #$20
        stx PPU_ADDR
        inx
        stx PPU_ADDR
        lda $201
        sta PPU_DATA
        
        lda #0
        sta PPU_ADDR
        sta PPU_ADDR
        sta UpdateColor
        
        jsr ConvertInputs
        
        lda #$80
        ldx PPU_STATUS
        sta PPU_CTRL
        
        pla
        tax
        pla
        tay
        pla
        rti