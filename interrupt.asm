InterruptHandler: subroutine
	php
        sta IntA
        stx IntX
        sty IntY
        pla
        sta IntP

        
	ldy BlockIndex

        
        lda JINTLO,y
        sta ATRPC
        lda JINTHI,y
        sta ATRPC+1
        

        lda JNESHI,y
        lsr
        lsr
        lsr
        sta IntrID
        lsr
        bcs .jors
        lsr
        bcs .sync
        ; Conditional Interrupt
	sta IntrID
        ldx JINTREL,y
        

.sync
	; Sync Interrupt


.jors	lsr
	bcs .stack
        ; Jump Interrupt

.stack
	; Stack Interrupt
	lsr
        bcc .rw
        lsr
        bcc .txs
	lda IntS
        sta IntX
        bvc .intdone
.txs
	lda IntX
        sta IntS
        bvc .intdone
.rw


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