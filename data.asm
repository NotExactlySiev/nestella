; 0000 00xx instruction of size xx
; 0000 01xy memory access instruction. x write op, y not zero page
; 100c cccc interrupt. ccccc interrupt code
; x1xx xxxx illegal opcode
; BRK is not included

InstTypes:
        .hex ff 04 ff ff ff 04 06 ff 9b 02 01 ff ff 05 07 ff
        .hex 80 04 ff ff ff 04 06 ff 01 05 ff ff ff 05 07 ff 91
        .hex 04 ff ff 04 04 06 ff 93 02 01 ff 05 05 07 ff
        .hex 84 04 ff ff ff 04 06 ff 01 05 ff ff ff 05 07 ff
        .hex 8d 04 ff ff ff 04 06 ff 8b 02 01 ff 81 05 07 ff
        .hex 88 04 ff ff ff 04 06 ff 01 05 ff ff ff 05 07 ff
        .hex 85 04 ff ff ff 04 06 ff 83 02 01 ff 89 05 07 ff
        .hex 8c 04 ff ff ff 04 06 ff 01 05 ff ff ff 05 07 ff
        .hex ff 06 ff ff 06 06 06 ff 01 ff 01 ff 07 05 07 ff
        .hex 90 06 ff ff 06 06 06 ff 01 07 87 ff ff 07 ff ff
        .hex 02 04 02 ff 04 04 04 ff 01 02 01 ff 05 07 05 ff
        .hex 94 04 ff ff 04 04 04 ff 01 05 8f ff 05 05 05 ff
        .hex 02 04 ff ff 04 04 06 ff 01 02 01 ff 05 05 07 ff
        .hex 98 04 ff ff ff 04 06 ff 01 05 ff ff ff 05 07 ff
        .hex 02 04 ff ff 04 04 06 ff 01 02 01 ff 05 05 07 ff
        .hex 9c 04 ff ff ff 04 06 ff 01 05 ff ff ff 05 07 ff

	; how many minimum cycles each opcode takes
Cycles:
        .hex ff 06 ff ff ff 03 05 ff 03 02 02 ff ff 04 06 ff
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

