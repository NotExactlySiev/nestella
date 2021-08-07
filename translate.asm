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
	jsr MirrorAddr
        ; check if causes interrupt
	lda #1
        bit InstType
        beq .nint
        tax
        
        lda AddrHi
        bne .nint
        inx
        cpx AddrLo
        bne .nint
        ; it's a sync
        dex
        stx NESInstSize
        lda #7
        sta NESOpCode
	jmp EmitInterrupt
.nint
        rts

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
        
        lda #INS_JSR
        sta (TCachePtr),y
        iny
        
        lda #<InterruptHandler
        sta (TCachePtr),y
        iny
        
        lda #>InterruptHandler
        sta (TCachePtr),y
        iny
        
        ldx #0
.writepars
        lda NESOpCode,x
        sta (TCachePtr),y
        iny
	inx
        cpx NESInstSize
        bcc .writepars
        
        ; advance the cache pointer
        tya
        clc
        adc TCachePtr
        sta TCachePtr
        lda TCachePtr+1
        adc #0
        sta TCachePtr+1
        
        jmp TranslationDone
        
        