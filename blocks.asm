CreateBlock: subroutine
	lda #0
        sta BlockCycles
        sta RollOver
.loop
        ldy #0
        lda (TROMPtr),y
        sta OpCode
        tax
        
        lda Cycles,x
        clc
        adc BlockCycles
        sta BlockCycles
        
	lda InstTypes,x
        sta InstType


        ; translate
	lda #$4
        bit InstType
        bpl .nint
        ; Instant Interrupt
.nint
        beq .nmem
        ; Memory Access
        jmp TMemoryAccess
        
.nmem
	; No changes
	lda InstType
        sta NESInstSize

InstructionDone

        ldy #0
        sty AddrHi
	ldy NESInstSize
        dey
AppendInstruction              
        lda NESOpCode,y
        sta (TCachePtr),y
        dey
        bpl AppendInstruction
        
.instdone
	lda InstSize
        clc
        adc TROMPtr
        sta TROMPtr
        lda TROMPtr+1
        adc #0
        sta TROMPtr+1
        
        ldx NESInstSize
        txa
        clc
        adc TCachePtr
        sta TCachePtr
        lda TCachePtr+1
        adc #0
        sta TCachePtr+1
        ; if we're at the end of the cache memory, we have to roll over and overwrite old cache
        cmp #$7
        bne .nrollover
        lda TCachePtr
        cmp #$F8
        bcc .nrollover
        
        ldy #0
        lda #INS_JMP_ABS
        sta (TCachePtr),y
        iny
        sty RollOver
        
        lda #<CodeBlocks
        tax
        sta (TCachePtr),y
        iny
        
        lda #>CodeBlocks
        sta (TCachePtr),y
        sta TCachePtr+1
        stx TCachePtr
	
        
.nrollover
        jmp .loop

TranslationDone

UpdateTable
	lda TCachePtr
        sta CacheFree
        lda TCachePtr+1
        sta CacheFree+1

	; complete the table entry
        ldx BlockIndex
        lda NESAddrHi
        sta JINTHI,x
        lda NESAddrLo
        sta JINTLO,x
        lda BlockNESPCHi
        sta JNESHI,x
        lda BlockCycles
        sta JCYCLES,x

	; and then execute it
        jmp ResumeProgram
