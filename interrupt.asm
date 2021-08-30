InterruptHandler: subroutine
	nop
	php
        sta IntA
        stx IntX
        sty IntY
        pla
        sta IntP

        
	ldy BlockIndex
	lda JCYCLES,y
        clc
        adc LineCycles
        sta LineCycles
        
        lda JINTLO,y
        sta var0
        lda JINTHI,y
        sta var1
        
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
        asl
        asl
	sta IntrID
        lda #$e3
        sta IntrID+1
        
        lda IntP
        pha
        lda #0
        ldx JINTREL,y
        plp
        jsr JumpToBranchCheck
        
        ldx #0
        tay
        bpl .pos
        ldx #$ff
.pos
        stx var2 ; used as bit extension
        
        clc
        adc var0
        sta var0
        lda var1
        adc var2
        sta var1
        jmp InterruptDone
        

.sync
	; Sync Interrupt
        lsr
        bcs .leftpf
        jmp ILineSync
.leftpf
        jsr IPlayfieldChange
        jmp InterruptDone

.jors	lsr
	bcs .stack
        ; Jump Interrupt
	lsr
        bcc .table
        ; -- RTS
        jsr PullStack
        sta var0
        jsr PullStack
        sta var1
        jmp InterruptDone
.table
	lsr
        bcc .direct
        ; -- JMP()
        ldy #0
        lda (var0),y
        pha
        iny
        lda (var0),y
        sta var1
        pla
        sta var0
        jmp InterruptDone
.direct
	lsr
        bcc .npush
        ; -- JSR
        lda ATRPC
        clc
        adc JINTREL,y
        sta ATRPC
        lda ATRPC+1
        adc #0
        jsr PushStack
        lda ATRPC
        jsr PushStack
.npush	
	; -- JMP
        jmp InterruptDone


.stack
	; Stack Interrupt
	lsr
        bcc .rw
        lsr
        bcc .txs
        ; TSX
	lda IntS
        sta IntX
        jmp InterruptDone
.txs
	; TXS
	lda IntX
        sta IntS
        jmp InterruptDone
.rw
	lsr
        bcc .pull
        ; PHx
        ldx IntA
        lsr
        bcc .ac
        ldx IntP
.ac
	txa
        jsr PushStack
	jmp InterruptDone
.pull
	; PLx
	sta var2
        jsr PullStack
        bit var2
        bne .proc
        ; PLA
        sta IntA
        jmp InterruptDone
.proc
	; PLP
	sta IntP

InterruptDone
	lda var0
        sta ATRPC
        lda var1
        sta ATRPC+1

        jmp SetNESPC
        
        
        
PushStack: subroutine
	sta var2
        lda IntS
        sta AddrLo
        lda #1
        sta AddrHi
        jsr MirrorAddr
        dec IntS
        
        ldy #0
        lda var2
        sta (NESAddrLo),y
        rts
        
PullStack: subroutine
        inc IntS
	lda IntS
        sta AddrLo
        lda #1
        sta AddrHi
        jsr MirrorAddr
        
        ldy #0
        lda (NESAddrLo),y
        rts
        
JumpToBranchCheck: subroutine
	jmp (IntrID)