SetNESPC: subroutine
	ldx #$ff
FindJump:
	inx
        lda JATRHI,x
        bne .ntrans
        inc Mode
        bne .trans
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
              
.trans
	; if the block wasn't cached prepare for translation
	lda ATRPC
        sta TROMPtr
        sta JATRLO,x
        
        lda ATRPC+1
        sta TROMPtr+1
        sta JATRHI,x
	
        lda TCachePtr
        sta JNESLO,x
        lda TCachePtr+1
        sta JNESHI,x
        stx BlockIndex
        
        ; block is addressed in the table. now we make the block	
        jmp CreateBlock

ResumeProgram: subroutine
	ldx BlockIndex
        lda JNESLO,x
        sta NESPC
        lda JNESHI,x
        sta NESPC+1
        lda JSIZE,x
        sta BlockSize
        lda JCYCLES
        sta BlockCycles
        
	lda IntS
        pha
        plp
        lda IntA        
        ldx IntX
        ldy IntY
        jmp (NESPC)