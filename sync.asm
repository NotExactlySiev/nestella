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
        sta DrawAddrLo
        
        
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
        
        
ReadPlayfieldNormal: subroutine
	; Playfield Byte 0
	; Tile 0
        lda PF0
        ror
        rol PlayField
        ror PF0
        rol PlayField+10
        
	lda PF0
        ror
        rol PlayField
        ror PF0
        rol PlayField+10

	; Tile 1
        lda PF0
        ror
        rol PlayField+1
        ror PF0
        rol PlayField+11
        
        lda PF0
        ror
        rol PlayField+1
        ror PF0
        rol PlayField+11        

	; Playfield Byte 1
	; Tile 2
        lda PF1
        rol
        rol PlayField+2
        rol PF1
        rol PlayField+12
        
        lda PF1
        rol
        rol PlayField+2
        rol PF1
        rol PlayField+12
        
        ; Tile 3
        lda PF1
        rol
        rol PlayField+3
        rol PF1
        rol PlayField+13
        
        lda PF1
        rol
        rol PlayField+3
        rol PF1
        rol PlayField+13  
        
        ; Tile 4
        lda PF1
        rol
        rol PlayField+4
        rol PF1
        rol PlayField+14
        
        lda PF1
        rol
        rol PlayField+4
        rol PF1
        rol PlayField+14
        
        ; Tile 5
        lda PF1
        rol
        rol PlayField+5
        rol PF1
        rol PlayField+15
        
        lda PF1
        rol
        rol PlayField+5
        rol PF1
        rol PlayField+15  
        
        ; Playfield Byte 2
        ; Tile 6
        lda PF2
        ror
        rol PlayField+6
        ror PF2
        rol PlayField+16
        
        lda PF2
        ror
        rol PlayField+6
        ror PF2
        rol PlayField+16  
        
        ; Tile 7
        lda PF2
        ror
        rol PlayField+7
        ror PF2
        rol PlayField+17
        
        lda PF2
        ror
        rol PlayField+7
        ror PF2
        rol PlayField+17  
        
        ; Tile 8
        lda PF2
        ror
        rol PlayField+8
        ror PF2
        rol PlayField+18
        
        lda PF2
        ror
        rol PlayField+8
        ror PF2
        rol PlayField+18  
        
        ; Tile 9
        lda PF2
        ror
        rol PlayField+9
        ror PF2
        rol PlayField+19
        
        lda PF2
        ror
        rol PlayField+9
        ror PF2
        rol PlayField+19
        
        rts
        
ReadPlayfieldMirrored: subroutine
	; Playfield Byte 0
	; Tile 0
        lda PF0
        ror
        rol PlayField
        ror PF0
        rol PlayField+19
    
	lda PF0
        ror
        rol PlayField
        ror PF0
        rol PlayField+19

	; Tile 1
        lda PF0
        ror
        rol PlayField+1
        ror PF0
        rol PlayField+18
        
        lda PF0
        ror
        rol PlayField+1
        ror PF0
        rol PlayField+18        

	; Playfield Byte 1
	; Tile 2
        lda PF0
        rol
        rol PlayField+2
        rol PF0
        rol PlayField+17
        
        lda PF0
        rol
        rol PlayField+2
        rol PF0
        rol PlayField+17
        
        ; Tile 3
        lda PF0
        rol
        rol PlayField+3
        rol PF0
        rol PlayField+16
        
        lda PF0
        rol
        rol PlayField+3
        rol PF0
        rol PlayField+16 
        
        ; Tile 4
        lda PF0
        rol
        rol PlayField+4
        rol PF0
        rol PlayField+15
        
        lda PF0
        rol
        rol PlayField+4
        rol PF0
        rol PlayField+15
        
        ; Tile 5
        lda PF0
        rol
        rol PlayField+5
        rol PF0
        rol PlayField+14
        
        lda PF0
        rol
        rol PlayField+5
        rol PF0
        rol PlayField+14
        
        ; Playfield Byte 2
        ; Tile 6
        lda PF2
        ror
        rol PlayField+6
        ror PF2
        rol PlayField+13
        
        lda PF2
        ror
        rol PlayField+6
        ror PF2
        rol PlayField+13
        
        ; Tile 7
        lda PF2
        ror
        rol PlayField+7
        ror PF2
        rol PlayField+12
        
        lda PF2
        ror
        rol PlayField+7
        ror PF2
        rol PlayField+12
        
        ; Tile 8
        lda PF2
        ror
        rol PlayField+8
        ror PF2
        rol PlayField+11
        
        lda PF2
        ror
        rol PlayField+8
        ror PF2
        rol PlayField+11
        
        ; Tile 9
        lda PF2
        ror
        rol PlayField+9
        ror PF2
        rol PlayField+10
        
        lda PF2
        ror
        rol PlayField+9
        ror PF2
        rol PlayField+10
        
        rts