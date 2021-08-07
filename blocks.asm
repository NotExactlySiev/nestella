CreateBlock: subroutine
	lda #0
        sta BlockSize
        sta BlockCycles
        sta RollOver
.loop
        ldy #0
        lda (TROMPtr),y
        sta OpCode
        sta NESOpCode
        tax
        
        lda Cycles,x
        clc
        adc BlockCycles
        sta BlockCycles
        
	lda InstTypes,x
        sta InstType
        and #$f
        tax
        
        lda InstSizes,x
        sta InstSize
        sta NESInstSize
        tay
        clc
        adc BlockSize
        sta BlockSize

	; copy the addr bytes of the instruction
CopyAddr
	dey
        beq .out
        lda (TROMPtr),y
        sta AddrLo-1,y
        bvc CopyAddr
.out

        ; translate
	lda #$8
        bit InstType
        beq .ncond
        ; conditional (or illegal) instruction
        jmp TConditional
        
        bne .transdone
        
.ncond	lsr
	bit InstType
        beq .nmem
        jsr TMemoryAccess
        bvc .transdone

.nmem	lsr
	bit InstType
        beq .njump
        jmp TJump
        
        bne .transdone
        
.njump	lsr
	bit InstType
        beq .nimm
        lda AddrLo
        sta NESAddrLo
        
        bne .transdone
.nimm
	; implied simple instruction. just copy with default values
        
        

.transdone
        
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

RemoveOverwrittenEntries
	; compare every cache entry and remove them if they are overwritten
        ; var0 and var1 hold the pointer to the end of current block
        ldx BlockIndex
        lda JSIZE,x
        clc
        adc JNESLO,x
        sta var0
        lda JNESHI,x
        adc #0
        sta var1
        
        ldy #$40
.nextentry
        dey
        lda JNESHI,y
        cmp JNESHI,x
        bcc .nextentry
        bne .isbigger
        lda JNESLO,y
        cmp JNESLO,x
        bcc .nextentry
.isbigger
	
        lda JNESHI,y
        cmp var1
        bcc .nextentry
        bne .isinrange
	lda JNESLO,y
.isinrange

        
UpdateTable
	lda TCachePtr
        sta CacheFree
        lda TCachePtr+1
        sta CacheFree+1

	ldx BlockIndex
        lda BlockSize
        sta JSIZE,x
	lda BlockCycles
        sta JCYCLES,x

	; and then execute it
        jmp ResumeProgram
