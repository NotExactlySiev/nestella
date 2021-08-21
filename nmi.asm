NMIHandler: subroutine
        pha
        tya
        pha
        txa
        pha
        
        lda #00
        sta PPU_CTRL
        
        ; count how many scanlines in each frame
        lda ScanLine
        sec
        sbc $202
        sta $203
        lda ScanLine
        sta $202
        
        ; draw the buffer if there's anything in it
        lda DrawAddrHi
        beq .ndraw

        lda DrawAddrHi
        sta PPU_ADDR
        lda DrawAddrLo
        sta PPU_ADDR
        
        ldx #0
.loop
        lda DrawBuffer,x
        sta PPU_DATA
        inx
        cpx #20
        bcc .loop
        
        lda #0
        sta DrawAddrHi
        
.ndraw
        
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