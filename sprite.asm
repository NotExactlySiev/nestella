ISpriteSync: subroutine
	ldx JINTREL,y
        
        lda LineCycles
        asl
        clc
        adc LineCycles
        
        adc #67
        
        sta Sprite0H,x
        
	jmp InterruptDone