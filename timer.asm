ITimer: subroutine

	ldx IntA
        dex
        stx TimerCounter

	ldx BlockIndex
        lda JINTPAR,x
        sta TimerInterval
        
	jmp InterruptDone