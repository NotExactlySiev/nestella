LineSync: subroutine
	; TODO: reflection and the latter 20 tiles should also be translated
	lda #2
        bit VSYNC
        beq .nvsync
        inc $201
        lda #-37
        sta ScanLine
        lda #5
        sta PaletteCounter
        lda #0
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
        ldx #0
        ldy #2
.loop
        lda PlayField-2,y
        rol PF0,x
        rol
        rol PF0,x
        rol
        sta PlayField-2,y
        
        iny
        tya
        and #$3
        bne .nnextpf
        inx
        cpx #3
        beq .out
.nnextpf
        jmp .loop

.out
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
        sta DrawAddr
        
        ldy ScanLine
        iny
        tya
        asl
        asl
        sta DrawAddr+1
        
        
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
        asl
        asl
        and #$30
        sta $2 ; we can use this as a temporary var
        lda COLUBK
        lsr
        lsr
        lsr
        lsr
        ora $2
        sta BGColor
        
        lda COLUPF
        asl
        asl
        and #$30
        sta $2 ; we can use this as a temporary var
        lda COLUPF
        lsr
        lsr
        lsr
        lsr
        ora $2
        sta PFColor

	inc ColorSection
	lda ColorSection
        sta UpdateColor
        
	ldx #5
.paldone
	stx PaletteCounter

.syncdone
	
        inc ScanLine
	rts