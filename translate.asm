MirrorAddr: subroutine
	lda AddrHi
        and #$10
        beq .ncart
	lda AddrHi
        ora #$f0
        sta NESAddrHi
        bne .mirrordone
.ncart
	bit AddrLo
        bmi .ntia
        bpl .inzp
.ntia
	lda AddrHi
        and #$02
        bne .nram
.inzp
	lda #0
        sta NESAddrHi
        lda AddrLo
        sta NESAddrLo
        bvc .mirrordone
.nram
	; IO
        lda #1
        sta NESAddrHi
        lda AddrLo
        and #$7
        sta NESAddrLo
        tax
	
        ; and add 8 if is a write instruction
        lda #1
        bit InstType
        beq .nwrite
	txa
        ora #$8
        sta NESAddrLo
.nwrite
.mirrordone
	rts


TMemoryAccess: subroutine
	jsr MirrorAddr
        ; check if causes interrupt

        rts

	; all six jumps have unique interrupts, so we encode them
        ; in high byte of instruction type and send that to the IH
TJump: subroutine
	lda #1
        sta NESInstSize
        bit InstType
        beq .
	jmp EmitInterrupt

TConditional: subroutine
	lda #2
        sta NESInstSize ; these are used here as parameters for the interrupt emitter
	lda OpCode
        sta NESOpCode
        lda AddrLo
	sta NESAddrLo

EmitInterrupt: subroutine
	ldy #0
                
        lda #INS_PHA
        sta (TCachePtr),y
        iny
        
        lda #INS_PHP
        sta (TCachePtr),y
        iny
        
        dec NESInstSize
        bmi .parsdone
        
        ldx #0
.writepars

        lda #INS_LDA_IMM
        sta (TCachePtr),y
        iny
        
	lda NESAddrLo,x
        sta (TCachePtr),y
        iny
        
        lda #INS_STA_ZPG
        sta (TCachePtr),y
        iny
        
        lda #var0
        stx var0
        clc
        adc var0
        sta (TCachePtr),y
        iny
        
        inx
        cpx NESInstSize
        bcc .writepars      
.parsdone

	lda #INS_LDA_IMM
        sta (TCachePtr),y
        iny
        
        lda NESOpCode
        sta (TCachePtr),y
        iny
        
        lda #INS_JMP_ABS
        sta (TCachePtr),y
        iny
        
        lda #<InterruptHandler
        sta (TCachePtr),y
        iny
        
        lda #>InterruptHandler
        sta (TCachePtr),y
        
        ; advance the cache pointer
        tya
        sec
        adc TCachePtr
        sta TCachePtr
        lda TCachePtr+1
        adc #0
        sta TCachePtr+1
        
        jmp TranslationDone
        
        