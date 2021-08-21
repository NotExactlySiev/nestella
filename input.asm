ConvertInputs: subroutine
	ldx #0
        stx JOYPAD1
        inx
        stx JOYPAD1
        
        lda JOYPAD1
        and #1
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
        sta $108
        sta $100
        rts