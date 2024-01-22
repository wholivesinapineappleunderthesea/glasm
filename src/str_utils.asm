;INCLUDE str_utils.inc

.CODE
widestringlen PROC
	xor eax, eax
cont:
	mov dx, word ptr [rcx + rax]
	add rax, 2
	test dx, dx
	jnz cont
	shr rax, 1
	ret
widestringlen ENDP
END