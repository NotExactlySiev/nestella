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
        tax
        beq .intdone
        adc ATRPC
        sta ATRPC
        ldy #0
        txa
        bpl .pos
        ldy #$ff
.pos
	tya
        adc ATRPC+1
        sta ATRPC+1
        bne .intdone

IJumpRTI
	pla
        sta IntS
IJumpRTS
        pla
        tay
        pla
	tax
        tya

        bvc Jump

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
	lda #<ROM_IRQ
        ldx #>ROM_IRQ
        bne Jump

IJumpJSR
	; push the return address into the stack and then absolute jump
	lda ATRPC+1
        pha
        lda ATRPC
        pha

IJumpAbs
	ldy #3
        lda (var0),y
        tax
        dey
        lda (var0),y
        
Jump        
        sta ATRPC
        stx ATRPC+1
	bne .intdone
        

ISync
	jsr LineSync

.intdone

        jmp SetNESPC
        
        
LineSync: subroutine
	lda #2
        bit VSYNC
        beq .nvsync
        lda #-37
        sta ScanLine
        bne .syncdone
.nvsync
	ldy ScanLine
        iny
        sty ScanLine
        ; we don't do anything if in vblank
        cpy #192
        bcs .syncdone
        ;visible scanlines 1-192

	ldy #2
        jmp .readpf

        ldy #0       
.readpf        
        lda PlayField,y
        rol PF0
        rol
        rol PF0
        rol
        sta PlayField,y
        iny
        cpy #$4
        bcc .readpf
        
        
        tya
        and #$7
        bne .nupdate
        ; 8 rows completed. draw the playfield bytes  
.nupdate

.syncdone
	rts