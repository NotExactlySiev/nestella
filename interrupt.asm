InterruptHandler: subroutine
	sta IntrID
        pla
        sta IntS
        pla
        sta IntA
        stx IntX
        sty IntY
          
        lda ATRPC
        clc
        adc BlockSize
        sta ATRPC
        lda ATRPC+1
        adc #0
        sta ATRPC+1
        
        lda IntrID
        and #$1f
        jmp (IJumpTable)
IJumpTable
	.word IConditional ; 0000
        .word ; 0010
        .word ; 0100
        .word ; 0110
        .word ; 1000
        .word ; 1010
        .word IJump; 1100
        .word ; 1110

IConditional
	lda IntrID
        sta BranchCode
        lda var0
        sta BranchShift
        
        lda IntS
        pha
        
        lda #0
        plp	; set the proccessor as it was when the interrupt happened
        jsr BranchCode
        
        lda #$ff
        bit BranchShift
        bmi .neg
        lda #0
.neg
	sta var3 ; use this as a temporary second byte for sign extension
        
        clc
        lda ATRPC
        adc BranchShift
        sta ATRPC
        lda ATRPC+1
        adc var3
        sta ATRPC+1
        bne .intdone

IJump
	lda IntrID
        lsr
        lsr
        lsr
        
        

.intdone

        jmp SetNESPC