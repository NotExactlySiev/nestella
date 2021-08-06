InterruptHandler: subroutine
	php
        sta IntA
        stx IntX
        sty IntY
        pla
        sta IntS
        pla
        sta var0
        pla
        sta var1
        
        ldy #1
        lda (var0),y
        iny
        
        sta IntrID
          
        lda ATRPC
        clc
        adc BlockSize
        sta ATRPC
        lda ATRPC+1
        adc #0
        sta ATRPC+1
   

        lda IntrID
        sec
        rol
        and #$1f
        tax

        lda IJumpTable,x
        pha
        dex
        lda IJumpTable,x
        pha
        rts
        
IJumpTable
	.word IConditional-1 ; 0000
        .word IJumpIRQ-1
        .word IJumpRTI-1
        .word IJumpRTS-1
        .word IJumpJSR-1
        .word IJumpAbs-1
        .word IJumpInd-1 ; 1100
        .word ISync-1 ; 1110

IConditional
	lda IntrID
        sta BranchCode
        lda (var0),y
        sta BranchShift
        
        lda IntS
        pha
        
        lda #0
        plp	; set the proccessor as it was when the interrupt happened
        jsr BranchCode
        
        clc
        lda BranchShift
        beq .intdone
        adc ATRPC
        sta ATRPC
        lda ATRPC+1
        sbc #0
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
	ldy #1
        lda (var0),y
        tax
        dey
        lda (var0),y
        
Jump        
        sta ATRPC
        stx ATRPC+1
	bne .intdone
        

ISync
	lda #2
        bit VSYNC
        beq .nvsync
        lda #-37
        sta ScanLine
        bne .intdone
.nvsync
	ldy ScanLine
        iny
        ; we don't do anything if in vblank
        cpy #192
        bcs .intdone
        ;visible scanlines 1-192
        tya
        and #$7
        bne .roll
        ; 8 rows completed. draw the playfield bytes
        
        
.roll
	; add this row to the playfield bytes


.intdone

        jmp SetNESPC