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
        asl
        and #$3e
        jmp (IJumpTable)
IJumpTable
	.word IConditional ; 0000
        .word IJumpIRQ
        .word IJumpRTI
        .word IJumpRTS
        .word IJumpJSR
        .word IJumpAbs
        .word IJumpInd; 1100
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

IJumpRTI
IJumpRTS

IJumpInd
	ldy #0
	lda (var0),y
        sta AddrLo
        iny
        lda (var0),y
        sta AddrHi
        jsr MirrorAddr
        lda NESAddrLo
        ldx NESAddrHi
        bne Jump

IJumpIRQ
	lda #<ROM_RESET
        ldx #>ROM_RESET
        bne Jump

IJumpJSR
	lda ATRPC+1
        pha
        lda ATRPC
        pha
IJumpAbs
	lda var0
        ldx var1
        
Jump        
        sta ATRPC
        stx ATRPC+1   

.intdone

        jmp SetNESPC