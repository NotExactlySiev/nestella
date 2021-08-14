MirrorAddr: subroutine
	ldy AddrHi
        ldx AddrLo
        
	tya
        and #$10
        beq .ncart
        ; xxx1 xxxx xxxx xxxx -> 1111 xxxx xxxx xxxx Done
	tya
        ora #$f0
        sta NESAddrHi
        bne .mirrordone
.ncart
	; xxx0 xxxx xxxx xxxx -> 0000 xxxx xxxx xxxx
	tya
        and #$f
        tay
	txa
        bmi .ntia
        ; 0000 xxxx 0xxx xxxx -> 0000 0000 0xxx xxxx
        ldy #0
        ror InstType
        bcc .ntiawrite
        ; -> 0000 0000 00xx xxxx Done
        txa
        and #$3f
        tax
        bpl .mirrordone
.ntiawrite
	; 0000 0000 0000 xxxx -> 0000 0000 0011 xxxx Done
	txa
        and #$f
        ora #$30
        tax
        bpl .mirrordone
.ntia
	tya
        and #$02
        tay
        ; 0000 00x0 1xxx xxxx
        beq .mirrordone
        ; 0000 0010 1xxx xxxx -> 0000 0001 mxxx
	; IO
        ldy #1
        txa
        and #$7
	
        ; and add 8 if is a write instruction
        ror InstType
        bcc .nwrite
        ora #$8
.nwrite
.mirrordone
	stx NESAddrLo
        sty NESAddrHi

	rts


TMemoryAccess: subroutine
	lda InstType
        and #$1
        ora #$2
        sta InstSize
	tay
        
        dey
.copyaddr        
        lda (TROMPtr),y
        sta OpCode,y
	dey
        bne .copyaddr

	jsr MirrorAddr
        
        ; check if causes interrupt
        lda #2
        bit InstType
        beq .nint
        tax
        
        lda NESAddrHi
        bne .nint
        cpx NESAddrLo
        bne .nint
        ; it's a sync
        ; use NESAddrHi and Lo for the interrupt return address since we no longer need those variables
        lda #$10
        ora BlockNESPCHi
        sta BlockNESPCHi
        clc
        lda TROMPtr
        adc InstSize
        sta NESAddrLo
        lda TROMPtr+1
        adc #0
        sta NESAddrHi
	jmp EmitInterrupt
.nint
	lda InstSize
        sta NESInstSize
        jmp InstructionDone


TAlwaysInterrupt: subroutine
	lda InstType
        asl
        asl
        asl
        ora BlockNESPCHi
        sta BlockNESPCHi
        lda InstType
        lsr
        bcs .ncond
        ; Conditional interrupt
        lda #2
        bne .nextop
    
.ncond	lsr
	bcc .nstack
        
        ; Stack interrupt
        lda #1
        bne .nextop

        
.nstack 
	; Jump interrupt
	lsr
        bcs .ntable
        
        ldy #1
        lda (TROMPtr),y
        sta NESAddrLo
        iny
        lda (TROMPtr),y
        sta NESAddrHi
        lda #3
        bne .nextop
        
.ntable
	lda #1
.nextop
        clc
        adc TROMPtr
        sta NESAddrLo
        lda TROMPtr+1
        adc #0
        sta NESAddrHi

EmitInterrupt: subroutine
	ldy #0        
        
        lda #INS_JMP_ABS
        sta (TCachePtr),y
        iny
        
        lda #<InterruptHandler
        sta (TCachePtr),y
        iny
        
        lda #>InterruptHandler
        sta (TCachePtr),y
        iny
        
        ; advance the cache pointer
        tya
        clc
        adc TCachePtr
        sta TCachePtr
        lda TCachePtr+1
        adc #0
        sta TCachePtr+1
        
        jmp TranslationDone
        
        