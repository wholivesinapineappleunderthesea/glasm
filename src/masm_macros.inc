ALIGN_TO_8 MACRO value
	EXITM <((value + 07h) AND NOT 07h)>
ENDM
ALIGN_TO_16 MACRO value
    EXITM <((value + 0Fh) AND NOT 0Fh)>
ENDM