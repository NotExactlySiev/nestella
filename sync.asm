LineSync: subroutine
	lda #0
        sta LineCycles
	; TODO: reflection and the latter 20 tiles should also be translated
	lda #2
        bit VSYNC
        beq .nvsync
        inc $201
        lda #-37
        sta ScanLine
        lda #3 ; sets the counter so the colors for each section are read halfway through
        sta PaletteCounter
        lda #1
        sta ColorSection
        inc ScanLine
        jmp InterruptDone 
.nvsync
	ldy ScanLine
        ; we don't do anything if in vblank
        cpy #192
        bcc .screen
        inc ScanLine
        jmp InterruptDone 
.screen
        ; visible scanlines 0-191
        tya
        lsr
        bcs .odd	; only odd scanlines are processed and drawn
	inc ScanLine
        jmp InterruptDone  
.odd

	lda LastDrawnPixel
        cmp #20
	bcs .nsplit
        
        ;;;;;;; finish this jesus
        
        jmp .linedone
.nsplit



.linedone

	lda ScanLine
	and #$7
        cmp #7	; have we read a entire row of tiles?
        beq .rowcomplete
        inc ScanLine
        jmp InterruptDone
.rowcomplete
        
        ; after 8 scanlines, copy the converted playfield data to buffer
        
	bit DrawBuffer0
        bne .n0
        FILL_BUFFER 0
	jmp .buffdone
        
.n0	bit DrawBuffer1
        bne .n1
        FILL_BUFFER 1
        jmp .buffdone
        
.n1	bit DrawBuffer2
        bne .n2
        FILL_BUFFER 2
        jmp .buffdone
.n2
	bit DrawBuffer3
        bne .n3
	FILL_BUFFER 3
        jmp .buffdone
.n3	
	bit DrawBuffer4
        bne .n4
	FILL_BUFFER 4
        jmp .buffdone
.n4	
	bit DrawBuffer5
        bne .n5
	FILL_BUFFER 5
        beq .buffdone
.n5	
	inc $210
.buffdone        

        ldx PaletteCounter
        dex
        bne .paldone
        ; after 6 tiles (48 scanlines) set the palettes
        
        lda COLUBK
	jsr ConvertColor
        sta BGColor
        
        lda COLUPF
        jsr ConvertColor
        sta PFColor
        
	ldx ColorSection
        stx UpdateColor
        inx
        stx ColorSection
        
	ldx #5
.paldone
	stx PaletteCounter

.syncdone
	
        inc ScanLine
	jmp InterruptDone
        
        

PlayfieldChange: subroutine
	lda ScanLine
        lsr
        bcs .odd
        jmp InterruptDone
.odd
	lda LineCycles
	; divide by 3 and shift left to roughly get what pixels should be drawn
	sta var2
        lsr
        lsr
        adc var2
        ror
        lsr
        adc var2
        ror
        lsr
        adc var2
        ror
        lsr
        adc var2
        ror
	tay
        
        ldx LastDrawnPixel
        sty LastDrawnPixel
        
        ; var2 is used to tell the function which side to update
        
        cpy #20
        bcc .left

        cpx #20
        bcc .split
        ; both points are in the right
        lda #1
        sta var2
        txa
        sec
        sbc #20
        tax
        tya
        sec
        sbc #20
        tay
        jsr ReadPlayfieldRight   
        jmp .readdone

.split
        ; it's split if we're here
	tya
        sec
        sbc #20
        tay
	stx var2
        ldx #0
        jsr ReadPlayfieldRight
        ldx var2
        ldy #19
.left
	; both points are in the left
        jmp ReadPlayfieldLeft
.readdone


CopyOld
	lda PF0
        sta PF0old
        lda PF1
        sta PF1old
        lda PF2
        sta PF2old

	jmp InterruptDone

; and it reads from pixel x to y
ReadPlayfieldLeft: subroutine
	lda PF0Masks,y
        eor PF0Masks,x
        and PF0old
        ora PFLeft0
        sta PFLeft0
        
	lda PF1Masks,y
        eor PF1Masks,x
        and PF1old
        ora PFLeft1
        sta PFLeft1
        
	lda PF2Masks,y
        eor PF2Masks,x
        and PF2old
        ora PFLeft2
        sta PFLeft2
        jmp CopyOld

ReadPlayfieldRight: subroutine
	lda PF0Masks,y
        eor PF0Masks,x
        and PF0old
        ora PFRight0
        sta PFRight0
        
	lda PF1Masks,y
        eor PF1Masks,x
        and PF1old
        ora PFRight1
        sta PFRight1
        
	lda PF2Masks,y
        eor PF2Masks,x
        and PF2old
        ora PFRight2
        sta PFRight2
        rts


PF0Masks:
	.byte %00000000, $00010000, %00110000, %01110000
        .byte %11110000, %11110000, %11110000, %11110000
        .byte %11110000, %11110000, %11110000, %11110000
        .byte %11110000, %11110000, %11110000, %11110000
        .byte %11110000, %11110000, %11110000, %11110000
        
PF1Masks:
	.byte %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %10000000, %11000000, %11100000
        .byte %11110000, %11111000, %11111100, %11111110
        .byte %11111111, %11111111, %11111111, %11111111
        .byte %11111111, %11111111, %11111111, %11111111
        
PF2Masks:
	.byte %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000
	.byte %00000001, %00000011, %00000111, %00001111
        .byte %00011111, %00111111, %01111111, %11111111
