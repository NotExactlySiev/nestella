LineSync: subroutine
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
        jmp .syncdone
.nvsync
	ldy ScanLine
        ; we don't do anything if in vblank
        cpy #192
        bcc .screen
        jmp .syncdone
.screen
        ; visible scanlines 0-191
        tya
        lsr
        bcs .odd	; only odd scanlines are processed and drawn
	jmp .syncdone     
.odd

        ; reading playfield data
        ; I did write some nice ass code here but apparently the bit order differs for each playfield byte
        ; so fuck it we're gonna do it the quick and dirty way. two different branches for mirrored and repeated
	lda PF0
        lsr
        lsr
        lsr
        lsr
        sta PF0

        lda CTRLPF
        and #1
        bne .mirrored
        jsr ReadPlayfieldNormal
	jmp .readdone
.mirrored
	jsr ReadPlayfieldMirrored
.readdone

	lda ScanLine
	and #$7
        cmp #7
        bne .syncdone
        
        ; after 8 scanlines, copy the converted playfield data to buffer
        
        ; PPU Address
        lda ScanLine
        rol
        rol
        rol
        and #$3
        ora #$20
        sta DrawAddrHi
        
        ldy ScanLine
        iny
        tya
        asl
        asl
        clc
        adc #$86
        sta DrawAddrLo
        lda DrawAddrHi
        adc #0
        sta DrawAddrHi
        
        ; Tiles
        ldy #0
        ldx #0
.copy 
        lda PlayField,x
        sta DrawBuffer,x
        tya
        sta PlayField,x
        inx
        cpx #20
        bne .copy                

	
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
	rts
        
        
