	ldx #0
        stx JOYPAD1
        inx
        stx JOYPAD1
        
        lda JOYPAD1
        ror
        ror
	and #$80
        sta INPT4
        