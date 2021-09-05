SetNESPC: subroutine
	ldx #$40
FindJump:
	dex
        bmi FreeCache
        lda JATRHI,x
        beq .trans
.ntrans 
        
	lda JATRLO,x
        cmp ATRPC
        bne FindJump
        lda JATRHI,x
        cmp ATRPC+1
        bne FindJump
        ; we found the jump addr!
        stx BlockIndex
        jmp ResumeProgram

FreeCache
	ldx CacheOldest
        txa
        dex
        bpl .nover
        ldx #$3F
.nover
	stx CacheOldest
        tax
.trans
	; if the block wasn't cached prepare for translation
	lda ATRPC
        sta TROMPtr
        sta JATRLO,x
        
        lda ATRPC+1
        sta TROMPtr+1
        sta JATRHI,x
	
        lda CacheFree
        sta TCachePtr
        sta JNESLO,x
        lda CacheFree+1
        sta TCachePtr+1
        sta BlockNESPCHi
        stx BlockIndex
        
        ; block is addressed in the table. now we make the block	
        jmp CreateBlock

ResumeProgram: subroutine
	ldx BlockIndex
        lda JNESLO,x
        sta NESPC
        lda JNESHI,x
        and #$7
        sta NESPC+1
        lda JCYCLES,x
        sta BlockCycles
        
	lda IntP
        pha
        lda IntA        
        ldx IntX
        ldy IntY
        plp
        jmp (NESPC)