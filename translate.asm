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


TStack: subroutine
	jmp EmitInterrupt


	; all six jumps have unique interrupts, so we encode them
        ; in high byte of instruction type and send that to the IH
TJump: subroutine
	lda #1
        bit InstType
        beq .implied
        lda AddrLo
        sta NESAddrLo
        lda AddrHi
        sta NESAddrHi
        lda #3
.implied
        sta NESInstSize

	lda InstType
        lsr
        lsr
        lsr
        lsr
        sta NESOpCode
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
        
        