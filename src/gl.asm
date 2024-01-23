;INCLUDE gl.inc

.DATA
globglGetProcAddress QWORD 0
PUBLIC globglGetProcAddress

glClearColor QWORD 0
PUBLIC glClearColor
glClear QWORD 0
PUBLIC glClear

.CONST
glClearColorStr db 'glClearColor',0
glClearStr db 'glClear',0


.CODE

glasm_init PROC
	; 28h shadow+call
	sub rsp, 28h

	lea rcx, glClearColorStr
	call qword ptr [globglGetProcAddress]
	mov [glClearColor], rax

	lea rcx, glClearStr
	call qword ptr [globglGetProcAddress]
	mov [glClear], rax

	add rsp, 28h
	ret
glasm_init endp

END