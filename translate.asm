TMemoryAccess: subroutine
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
        beq .mirrordone
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
