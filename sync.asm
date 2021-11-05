ILineSync: subroutine
	lda #-22
        sta LineCycles
	; TODO: reflection and the latter 20 tiles should also be translated
	lda #2
        bit VSYNC
        beq .nvsync
        
        inc $201 ; frame counter
        
        lda $202 ; how many frames did this one frame take?
        sta $203
        lda #0
        sta $202
        
        lda #$ec
        sta FreeSprite
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
        ldx FreeSprite
        
        lda GRP0
        beq .nsprite0
        
        
        sta $201,x
        tya
        clc
        adc #39
        sta $200,x
        lda Sprite0H
        
        sta $203,x
        
        dex
        dex
        dex
        dex
        bne .nwrap
        ldx #$ec
.nwrap

.nsprite0
        lda GRP1
        beq .nsprite1
        
        sta $201,x
        tya
        clc
        adc #39
        sta $200,x
        lda Sprite1H
        
        sta $203,x
        
        dex
        dex
        dex
        dex
        bne .nwrap1
        ldx #$ec
.nwrap1
.nsprite1        
        stx FreeSprite
        
        tya
        lsr
        bcs .odd	; only odd scanlines are processed and drawn
	inc ScanLine
        jmp InterruptDone  
.odd

	; read the rest of the line since the PFx bytes aren't gonna change
	jsr FinishLine

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
        ;FILL_BUFFER 1
        jmp .buffdone
        
.n1	;bit DrawBuffer2
        bne .n2
        ;FILL_BUFFER 2
        jmp .buffdone
.n2
	;bit DrawBuffer3
        bne .n3
	;FILL_BUFFER 3
        jmp .buffdone
.n3	
	;bit DrawBuffer4
        bne .n4
	;FILL_BUFFER 4
        jmp .buffdone
.n4	
	;bit DrawBuffer5
        bne .n5
	;FILL_BUFFER 5
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
        
        

IPlayfieldChange: subroutine
	lda ScanLine
        lsr
        bcc CopyOld
        
	lda LineCycles
        bmi CopyOld
        
	; multiply by 3 and divide by 4        
        asl
        clc
        adc LineCycles
        sec
        lsr
        lsr
        
        tay

        
	cpy LastDrawnPixel
        bcs .nwrap
        tya
        pha
        jsr FinishLine
        pla
        tay
.nwrap

        ldx LastDrawnPixel
        sty LastDrawnPixel
	; now that x and y are set with the correct pixel numbers, this subroutine reads
        ; pixels in that range and updates the playfield buffer bytes
	jsr ReadPlayfieldRange

CopyOld
	lda PF0
        sta PF0old
        lda PF1
        sta PF1old
        lda PF2
        sta PF2old

	jmp InterruptDone


; finish drawing the last scanline, clear buffers for the next
FinishLine: subroutine
	ldx LastDrawnPixel
        ldy #39
        jsr ReadPlayfieldRange

	lda #0
        sta LastDrawnPixel
        
        UPDATE_TILES_LEFT
        lda CTRLPF
        ror
        bcc .nmirror
        UPDATE_TILES_RIGHT_MIRRORED
        jmp .linedone
.nmirror
        UPDATE_TILES_RIGHT
.linedone
	lda #0
        sta PFRight0
        sta PFRight1
        sta PFRight2
        sta PFLeft0
        sta PFLeft1
        sta PFLeft2
	rts


; these subroutines read the playfield data after x and y are set
ReadPlayfieldRange: subroutine
        cpy #20
        bcc .left

        cpx #20
        bcc .split
        ; both points are in the right
        txa
        sec
        sbc #20
        tax
        tya
        sec
        sbc #20
        tay
        jsr ReadPlayfieldRight   
        rts

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
        rts

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
