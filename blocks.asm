CreateBlock: subroutine
	lda #0
        sta BlockSize
        sta BlockCycles
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
        
        jmp .loop

TranslationDone
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
