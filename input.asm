ConvertInputs: subroutine
	ldx #1
        stx JOYPAD1
        dex
        stx JOYPAD1
        
        lda JOYPAD1
        and #1
        eor #1
        sta $10A
        bit JOYPAD1
        bit JOYPAD1
        bit JOYPAD1
        
        lda #0
        clc
        ror JOYPAD1
        rol
        ror JOYPAD1
        rol
        ror JOYPAD1
        rol
        ror JOYPAD1
        rol
        asl
        asl
        asl
        asl
        eor #$f0
        sta $100
        rts