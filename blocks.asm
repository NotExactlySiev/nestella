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
        lda BlockNESPCHi
        sta JNESHI,x

InvalidateCache
	jmp .cachedone ; TEMPORARY!!!!

	; compare every cache entry and remove them if they are overwritten
        ; var0 and var1 hold the pointer to the end of current block
        and #$7	; this is inefficient!!!!
        sta var0 ; store NESHI of the current block and the block that's being checked in v0 and v1 if needed
        
	; we need two different algorithms for rolled over and non rolled over blocks
        ldy BlockIndex
        lda RollOver
	beq .method2
.method1
        	dey
                bpl .nend
		ldy #CACHE_BLOCKS-1
.nend		; is the start of the block before the end of the current block OR after the start?
		lda JNESHI,y
                and #$7
        	cmp var0
                bcc .check2
                bne .isin
		lda JNESLO,y
                cmp JNESLO,x
                bcs .isin
.check2
        	lda JNESHI,y
                and #$7
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
		ldy #CACHE_BLOCKS-1
.nend2		; is the start of the block before the end of the current block AND after the start?
		lda JNESHI,y
                and #$7
                cmp var0
                bcc .cachedone
                bne .check4
                lda JNESLO,y
                cmp JNESLO,x
                bcc .method2
                beq .cachedone ; we shouldn't be here
.check4
		lda JNESHI,y
                and #$7
		cmp TCachePtr+1
                bcc .isin
                bne .cachedone
                lda JNESLO,y
                cmp TCachePtr
                bcs .cachedone
.isin
	lda #0
        sta JATRHI,y
        bit RollOver
        beq .method2
        bne .method1

.cachedone


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
        lda BlockCycles
        sta JCYCLES,x

	; and then execute it
        jmp ResumeProgram
