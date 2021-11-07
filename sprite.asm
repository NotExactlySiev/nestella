ISpriteSync: subroutine
	ldx JINTPAR,y
        
        lda LineCycles
        asl
        clc
        adc LineCycles
        
        adc #67
        
        sta Sprite0H,x
        
        ; check for collisions
        lda Sprite0H
        sec
        sbc Sprite1H
        cmp #8
        bcc .p0p1
        cmp #$f8
        bcs .p0p1
        bcc .coldone     
.p0p1        
 	lda #$80
        ora $37
        sta $37
 
.coldone
	jmp InterruptDone