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
        
        