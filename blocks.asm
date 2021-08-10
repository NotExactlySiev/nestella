CreateBlock: subroutine
	lda #0
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
	; implied simple instruction. interrupt if stack operation
        ; other wise copy with the default value


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
        
	; we need two different algorithms for rolled over and non rolled over blocks
        ldy BlockIndex
        lda RollOver
	beq .method2
.method1
        	dey
                bpl .nend
		ldy #$3F
.nend		; is the start of the block before the end of the current block OR after the start?
		lda JNESHI,y
        	cmp JNESHI,x
                bcc .check2
                bne .isin
		lda JNESLO,y
                cmp JNESLO,x
                bcs .isin
.check2
        	lda JNESHI,y
                cmp TCachePtr+1
                bcc .isin
                bne .cachedone
                lda JNESLO,y
                cmp TCachePtr
                bcc .isin
                bcs .cachedone
                
.method2
		dey
                bpl .nend2
		ldy #$3F
.nend2		; is the start of the block before the end of the current block AND after the start?
		lda JNESHI,y
                cmp JNESHI,x
                bcc .cachedone
                bne .check4
                lda JNESLO,y
                cmp JNESLO,x
                bcc .method2
                beq .cachedone ; we shouldn't be here
.check4
		lda JNESHI,y
		cmp TCachePtr+1
                bcc .isin
                bne .method2
                lda JNESLO,y
                cmp TCachePtr
                bcs .cachedone
.isin
	lda #0
        sta JATRHI,y
        bit RollOver
        bne .back2
        beq .method1
.back2
	bne .method2

.cachedone

UpdateTable
	lda TCachePtr
        sta CacheFree
        lda TCachePtr+1
        sta CacheFree+1

	ldx BlockIndex
	lda BlockCycles
        sta JCYCLES,x

	; and then execute it
        jmp ResumeProgram
