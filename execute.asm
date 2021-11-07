	MAC SET_NESPC ; is this too slow or am i overthinking things? we don't need a LUT for this, right?
          txa
          asl
          asl
          asl
          asl
          sta NESPC
          txa
          lsr
          lsr
          lsr
          lsr
          ora #$04
          sta NESPC+1
        ENDM

	; TODO: make the index thing 6 bit everywhere

FindBlock: subroutine
	IF PERFORMANCE_MONITOR=1
	clc
        lda #1
        adc $158
        sta $158
        lda #0
        adc $159
        sta $159
        lda #0
        adc $15A
        sta $15A
	ENDIF

	; decode JATARI
        lda ATRPC
        and #$3f
        tax
        stx BlockIndex
        
        SET_NESPC
        
        ; Check if this is the correct block
        lda JATARI,x
        tay
        and #$c0
        ora Identity,x
        cmp ATRPC
        bne Overwrite
        tya
        ora #$c0
        cmp ATRPC+1
        bne Overwrite

	IF PERFORMANCE_MONITOR=1
        clc
        lda #1
        adc $148
        sta $148
        lda #0
        adc $149
        sta $149
        lda #0
        adc $14A
        sta $14A
	ENDIF
        
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
        
        ; is this memory block part of a previous code block? if so,
        ; it's invalidation time
        lda JATARI,x
        and #$30
        cmp #$20
        beq .invalidate
        cmp #$10
        beq .invalidate
        bne .create
.invalidate
	; we go back until we reach either a tail block or a head block
        ; (it shouldn't be possible to get an empty block i don't think)
.prev
	dex
        bpl .nwrap
        ldx #$3F
.nwrap
        lda JATARI,x
        and #$30
        cmp #$10
        beq .prev
	
	; invalidate the block if it's valid
        ; if not it's already been invalidated
	lda #$20
        sta JATARI,x
 
.create
	ldx BlockIndex
	lda ATRPC
        sta TROMPtr
        and #$c0
        tay
        
        lda ATRPC+1
        sta TROMPtr+1
        and #$3f
        ora Identity,y
        sta JATARI,x
	        
        jmp CreateBlock


