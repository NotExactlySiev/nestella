NMIHandler: subroutine
        pha
        tya
        pha
        txa
        pha
        
        lda #00
        sta PPU_CTRL
        
        inc $202
        
        ; count how many scanlines in each nes frame
                        
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
	;DRAW_BUFFER 1
        ;DRAW_BUFFER 2
        ;DRAW_BUFFER 3
        ;DRAW_BUFFER 4
        ;DRAW_BUFFER 5
        
        ldx #$20
        stx PPU_ADDR
        inx
        stx PPU_ADDR
        lda $201
        sta PPU_DATA
        lda $203
        sta PPU_DATA
        
        lda $202
        and #$3
        bne .noam
        lda #$2
        sta OAM_DMA
.noam

        lda #0
        sta PPU_ADDR
        sta PPU_ADDR
        sta UpdateColor
        
        jsr ConvertInputs
        
        lda #CTRL_NMI | CTRL_SPR_1000
        ldx PPU_STATUS
        sta PPU_CTRL
        
        pla
        tax
        pla
        tay
        pla
        rti