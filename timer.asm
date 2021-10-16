ITimer: subroutine

	ldx IntA
        dex
        stx TimerCounter

	ldx BlockIndex
        lda JINTREL,x
        sta TimerInterval
        
	jmp InterruptDone