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

        ; reading playfield data
        ; I did write some nice ass code here but apparently the bit order differs for each playfield byte
        ; so fuck it we're gonna do it the quick and dirty way. two different branches for mirrored and repeated


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
        
        lda PF0

	lda PF0
        sta PF0old
        lda PF1
        sta PF1old
        lda PF2
        sta PF2old


	jmp InterruptDone
        
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
