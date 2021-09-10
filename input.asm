ConvertInputs: subroutine
	ldx #8
	lda #$ff
.clear
        dex
        sta $100,x
	bne .clear
        
        lda #0
        sta $101
        sta $103
	sta $104

	ldx #1
        stx JOYPAD1
        dex
        stx JOYPAD1
        

        bit JOYPAD1
        bit JOYPAD1
        lda JOYPAD1
        and #1
        eor #$3f
        sta $102
        
        bit JOYPAD1
        
        
        lda #0
        clc
        ror JOYPAD1
        ror
        ror JOYPAD1
        ror
        ror JOYPAD1
        ror
        ror JOYPAD1
        ror
        eor #$ff
        sta $100
        
        lda #$ff
        sta INPT4
        sta INPT5
        
        rts