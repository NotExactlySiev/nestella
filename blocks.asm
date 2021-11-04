CreateBlock: subroutine
	lda NESPC
        sta TCachePtr
        lda NESPC+1
        sta TCachePtr+1
        ; maybe we can just store the index, if the blocks are not gonna be larger than 256 bytes
        ; this is kinda slow and not needed now that we can calculate the NESPC whenever we want
        ; actually on second thought that would make rolling over back to the start of the blocks hell
        ; but there has to be a better way to do all of this

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
        ; Always Interrupt
        jmp TAlwaysInterrupt
.nint
        beq .nmem
        ; Memory Access
        jmp TMemoryAccess
        
.nmem
	; No changes
	ldy InstType
        sty InstSize
        sty NESInstSize
	dey
.copy        
        lda (TROMPtr),y
        sta NESOpCode,y
        dey
        bpl .copy
        

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
        
        ; advance the pointers
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
        cmp #$f2
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
	ldx BlockIndex

InvalidateCache
	; TODO: if the generated code block is bigger than 34 bytes, the next block(s) are invalid
        ; (invalid blocks have bit 4 in their JATARI set to 0)

UpdateTable
	; complete the table entry
        lda NESAddrHi
        sta JRETHI,x
        lda NESAddrLo
        sta JRETLO,x
        lda BlockCycles
        sta JCYCLES,x

	

	; and then execute it
        jmp ResumeProgram
