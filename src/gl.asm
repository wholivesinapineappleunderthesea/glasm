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

glasm_beginframe PROC
	; 28h shadow+call
	sub rsp, 28h
	; red xmm0 = 1.f
	mov eax, 3F800000h
	movd xmm0, eax
	; green xmm1 = 0.f
	mov eax, 0h
	movd xmm1, eax
	; blue xmm2 = 0.f
	mov eax, 0h
	movd xmm2, eax
	; alpha xmm3 = 1.f
	mov eax, 3F800000h
	movd xmm3, eax
	
	call [glClearColor]

	mov ecx, 04100h ; GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT
	call [glClear]

	add rsp, 28h
	ret
glasm_beginframe endp
	; 28h shadow+call
	sub rsp, 28h

	add rsp, 28h

glasm_endframe PROC
	ret
glasm_endframe endp

END