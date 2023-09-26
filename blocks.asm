CreateBlock: subroutine
	lda NESPC
        sta TCachePtr
        lda NESPC+1
        sta TCachePtr+1
        ; maybe we can just store the index, if the blocks are not gonna be larger than 256 bytes
        ; this is kinda slow and not needed now that we can calculate the NESPC whenever we want
        ; actually on second thought that would make rolling over back to the start of the blocks hell
        ; but there has to be a better way to do all of this

	lda #0
        sta var3        ; block size so far
        sta BlockCycles
        sta RollOver
.loop
        ldy #0
        lda (TROMPtr),y
        sta OpCode
        tax
        
        lda Cycles,x
        clc
        adc BlockCycles
        sta BlockCycles
        
	lda InstTypes,x
        sta InstType


        ; translate
	lda #$4
        bit InstType
        bpl .nint
        ; Always Interrupt

        ;; EXPERIMENT!!! if it's a branch going back into the same block, just copy
        lda InstType
        lsr
        bcs .nfancy
        ;; check if goes back
        ldy #1
        lda (TROMPtr),y
        bpl .nfancy
        iny     ; set to 2 it's gonna be instruction size
        clc
        adc var3
        ; it works! just copy it!
        bpl SimpleCopy
        
.nfancy
        ;; EXPERIMENT OVER!!!
        jmp TAlwaysInterrupt
.nint
        beq .nmem
        ; Memory Access
        jmp TMemoryAccess
        
.nmem
	; No changes
	ldy InstType
SimpleCopy
        sty InstSize
        sty NESInstSize
	dey
.copy        
        lda (TROMPtr),y
        sta NESOpCode,y
        dey
        bpl .copy
        

InstructionDone
        ldy #0
        sty AddrHi
	ldy NESInstSize
        dey
AppendInstruction
        lda NESOpCode,y
        sta (TCachePtr),y
        dey
        bpl AppendInstruction
        
        ; advance the pointers
	lda InstSize
        clc
        adc TROMPtr
        sta TROMPtr
        lda TROMPtr+1
        adc #0
        sta TROMPtr+1
        
        ldx NESInstSize
        txa
        clc
        adc TCachePtr
        sta TCachePtr
        lda TCachePtr+1
        adc #0
        sta TCachePtr+1

        txa
        clc
        adc var3
        sta var3
        
        ; if we're at the end of the cache memory, we have to roll over and overwrite old cache
        cmp #$7
        bne .nrollover
        lda TCachePtr
        cmp #$f2
        bcc .nrollover
        
        ldy #0
        lda #INS_JMP_ABS
        sta (TCachePtr),y
        iny
        sty RollOver
        
        lda #<CodeBlocks
        tax
        sta (TCachePtr),y
        iny
        
        lda #>CodeBlocks
        sta (TCachePtr),y
        sta TCachePtr+1
        stx TCachePtr        
.nrollover

        jmp .loop

TranslationDone
	ldx BlockIndex

InvalidateCache
	; bits 4 and 5 in JATARI have special meaning
        ;
        ; xx00xxxx this block is empty
        ; xx11xxxx this block has valid code (only this type can be executed)
        ; xx01xxxx this black was fully overwritten 
        ; xx10xxxx this block was overwritten and the code ended here
        ;
        ; after writing to a block, we check to see if we've overwritten any blocks after it
        ; and mark their JATARI bits approprietly. also, when creating a new block, first we should
        ; check to see if that block was already part of a previous code block (bits are 01 or 10) and
        ; if so, we go back and invalidate that block too. we only have to go back 1- if the block we're
        ; about to create was previously overwritten, and 2- until we reach a block that's either valid (11)
        ; in which case it'll be invalidated, or is overwritten by the tail end of a code block (10)
        ; in which case the code containing the current block has already been invalidated.
        
        ; divide the size of this block by 16 to see if we're overflowing
        sec
        lda TCachePtr
        sbc NESPC
        lsr
        lsr
        lsr
        lsr
        tay
        beq .cachedone

.next
        inx
        dey
        beq .tail
        lda #%00010000
        sta JATARI,x
        bne .next
        

.tail
	lda #%00100000
        sta JATARI,x
        
.cachedone

UpdateTable
	ldx BlockIndex

	; complete the table entry
        lda NESAddrHi
        sta JRETHI,x
        lda NESAddrLo
        sta JRETLO,x
        lda BlockCycles
        sta JCYCLES,x

	

	; and then execute it
        jmp ResumeProgram
