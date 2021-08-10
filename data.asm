; 0 do nothing. implied or accumulator
; 1 do nothing. immediate
; 2 is a jump. implied
; 3 is a jump. 2 byte addr
; 4 memory read. 1 byte addr
; 5 memory write. 1 byte addr
; 6 memory read. 2 byte addr
; 7 memory write. 2 byte addr
; 8 conditional
; 10 stack operation
; ff illegal opcode
; TODO come up with a better categorization you idiot

InstTypes:
        .byte %10000001
        .byte %10000000
        .byte %10010001
        .byte %10000100

	; how many minimum cycles each opcode takes
Cycles:
        .hex 07 06 ff ff ff 03 05 ff 03 02 02 ff ff 04 06 ff
        .hex 02 05 ff ff ff 04 06 ff 02 04 ff ff ff 04 07 ff
        .hex 06 06 ff ff 03 03 05 ff 04 02 02 ff 04 04 06 ff
        .hex 02 05 ff ff ff 04 06 ff 02 04 ff ff ff 04 07 ff
        .hex 06 06 ff ff ff 03 05 ff 03 02 02 ff 03 04 06 ff
        .hex 02 05 ff ff ff 04 06 ff 02 04 ff ff ff 04 07 ff
        .hex 06 06 ff ff ff 03 05 ff 04 02 02 ff 05 04 06 ff
        .hex 02 05 ff ff ff 04 06 ff 02 04 ff ff ff 04 07 ff
        .hex 03 06 ff ff 03 03 03 ff 02 ff 02 ff 04 04 04 ff
        .hex 02 06 ff ff 04 04 04 ff 02 05 02 ff ff 05 ff ff
        .hex 02 06 02 ff 03 03 03 ff 02 02 02 ff 04 04 04 ff
        .hex 02 05 ff ff 04 04 04 ff 02 04 02 ff 04 04 04 ff
        .hex 02 06 ff ff 03 03 05 ff 02 02 02 ff 04 04 03 ff
        .hex 02 05 ff ff ff 04 06 ff 02 04 ff ff ff 04 07 ff
        .hex 02 06 ff ff 03 03 05 ff 02 02 02 ff 04 04 06 ff
        .hex 02 05 ff ff ff 04 06 ff 02 04 ff ff ff 04 07 ff

InstSizes:
	.byte 1, 2, 1, 3, 2, 2, 3, 3, 2

