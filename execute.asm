	MAC SET_NESPC ; is this too slow or am i overthinking things? we don't need a LUT for this, right?
          txa
          asl
          asl
          asl
          asl
          asl
          sta NESPC
          txa
          lsr
          lsr
          lsr
          ora #$04
          sta NESPC+1
        ENDM

FindBlock: subroutine
        lda ATRPC
        and #$1f
        tax
        stx BlockIndex
        
        SET_NESPC
        
        lda JATARI,x
        tay
        and #$e0
        ora Identity,x
        cmp ATRPC
        bne Overwrite
        tya
        ora #$e0
        cmp ATRPC+1
        bne Overwrite

ResumeProgram       
	lda IntP
        pha
        lda IntA        
        ldx IntX
        ldy IntY
        plp
        jmp (NESPC)

Overwrite
	; if the block wasn't cached prepare for translation
	lda ATRPC
        sta TROMPtr
        and #$e0
        tay
        
        lda ATRPC+1
        sta TROMPtr+1
        and #$1f
        ora Identity,y
        sta JATARI,x
	        
        jmp CreateBlock


