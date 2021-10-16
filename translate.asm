MirrorAddr: subroutine
	ldy AddrHi
        ldx AddrLo
        
	tya
        and #$10
        beq .ncart
        ; xxx1 xxxx xxxx xxxx -> 1111 xxxx xxxx xxxx Done
	tya
        ora #$f0
        ; if > $fffa, redirect to the original vectors at $effa
        cmp #$ff
        bne .nvectors
        cpx #$fa
        bcc .nvectors
        lda #$ef
.nvectors
        tay
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
        lda InstType
        and #2
        beq .ntiawrite
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
        ; 0000 0010 1xxx xxxx -> 0000 0001 0000 mxxx
	; IO
        ldy #1
        txa
        and #$7
	
        ; and add 8 if is a write instruction
	sta var0
        
        lda InstType
        and #2
	asl
        asl
        ora var0
        
	tax
        
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
        bpl .copyaddr

	jsr MirrorAddr
        
        lda OpCode
        sta NESOpCode
        
        ; check if causes interrupt
        ; reads don't interrupt
        lda #2
        bit InstType
        beq .nint
        
        ; indexed writes don't interrupt
        lda #$10
        bit OpCode
        bne .nint
        
        ; only zero page interrupts
        lda NESAddrHi
        bne .io


        lda NESAddrLo
        cmp #$2
        bne .nwsync
        ; it's a sync
        ; use NESAddrHi and Lo for the interrupt return address since we no longer need those variables
        lda #$10
	bne AccessInterrupt

.nwsync
	cmp #$d
        bcc .nint
        cmp #$10
        bcs .nint
        
        ldy #0
.loop
        lda NESOpCode,y
        sta (TCachePtr),y
        iny
        cpy InstSize
        bcc .loop
	lda #$30
        bne AccessInterrupt


.io
	lda NESAddrLo
	cmp #$10
        bcs .nint
        tax
        lda Timer-$c,x ; get the timer interval from table
        cmp #$10
        bcs .nint
        ; if it's bigger than 16 it's not an interrupt
        ; if it is smaller, then we have our timer interval
        ldx BlockIndex
        sta JINTREL,x
        ldy #0
        lda #$50
        
        

AccessInterrupt
	ora BlockNESPCHi
        sta BlockNESPCHi
        lda InstSize
        bne ReturnNextOp

.nint

	lda InstSize
        sta NESInstSize
        lda OpCode
	sta NESOpCode
        jmp InstructionDone
Timer	.byte $0, $1, $8, $80 ; i don't know if this is good or fucking stupid but i'm doing it

TAlwaysInterrupt: subroutine ; why aren't we putting values in the table here? 
			     ; instead of putting them in a var and then in table?
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
        ldx BlockIndex
        ldy #1
        lda (TROMPtr),y
        sta JINTREL,x
        
	dey
        lda #2
	bne ReturnNextOp
    
.ncond	lsr
	bcc .nstack
        
        ; Stack interrupt
        ldy #0
        lda #1
        bne ReturnNextOp

        
.nstack
	; Jump interrupt
	lsr
        bcs .ntable
        
        ldy #1
        lda (TROMPtr),y
        sta AddrLo
        iny
        lda (TROMPtr),y
        sta AddrHi
        
        jsr MirrorAddr
        
        sec
        lda TROMPtr
        sbc ATRPC
        clc
        adc #3
        ldx BlockIndex
        
        sta JINTREL,x
 
	ldy #0
        jmp EmitInterrupt

.ntable
	lda #1
        ldy #0

; set the return address to right where it was left off
ReturnNextOp:
	clc
        adc TROMPtr
        sta NESAddrLo
        lda TROMPtr+1
        adc #0
        sta NESAddrHi

EmitInterrupt: subroutine

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
        
        