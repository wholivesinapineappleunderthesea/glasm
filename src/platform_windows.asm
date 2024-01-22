;INCLUDE platform_windows.inc

EXTERN GetModuleHandleW: PROC
EXTERN GetModuleFileNameW: PROC
EXTERN ExitProcess: PROC

EXTERN GetProcessHeap: PROC
EXTERN HeapAlloc: PROC
EXTERN HeapFree: PROC

; POINT
POINT STRUCT
	x SDWORD ?
	y SDWORD ?
POINT ENDS

; WNDCLASSEXW
WNDCLASSEXW STRUCT
	cbSize DWORD ?
	style DWORD ?
	lpfnWndProc QWORD ?
	cbClsExtra DWORD ?
	cbWndExtra DWORD ?
	hInstance QWORD ?
	hIcon QWORD ?
	hCursor QWORD ?
	hbrBackground QWORD ?
	lpszMenuName QWORD ?
	lpszClassName QWORD ?
	hIconSm QWORD ?
WNDCLASSEXW ENDS

; MSG
MSG STRUCT 16
	hwnd QWORD ?
	message DWORD ?
	wParam QWORD ?
	lParam QWORD ?
	time DWORD ?
	pt POINT <>
	lPrivate DWORD ?
MSG ENDS

EXTERN RegisterClassExW: PROC
EXTERN CreateWindowExW: PROC
EXTERN DefWindowProcW: PROC
EXTERN DestroyWindow: PROC
EXTERN ShowWindow: PROC
EXTERN UpdateWindow: PROC
EXTERN PeekMessageW: PROC
EXTERN TranslateMessage: PROC
EXTERN DispatchMessageW: PROC

.DATA
globModuleSize DWORD 0
PUBLIC globModuleSize

globModuleHandle QWORD 0
PUBLIC globModuleHandle

globModuleFolderPath WORD 512 DUP(0)
PUBLIC globModuleFolderPath
globModuleFolderPathLen WORD 0
PUBLIC globModuleFolderPathLen

globModuleFileName WORD 512 DUP(0)
PUBLIC globModuleFileName
globModuleFileNameLen WORD 0
PUBLIC globModuleFileNameLen

globProcHeapHandle QWORD 0
PUBLIC globProcHeapHandle

globWindowHandle QWORD 0
PUBLIC globWindowHandle

.CONST
winClassName DW 'g', 'l', 'a', 's', 'm', '0', '1', 0

.CODE
win_init PROC
	sub rsp, 28h ; shadow space

	; set globModuleHandle
	xor rcx, rcx
	call GetModuleHandleW
	mov globModuleHandle, rax

	; set globModuleSize
	mov ecx, dword ptr [rax + 3Ch] ; e_lfanew
	mov eax, dword ptr [rax + rcx + 50h] ; SizeOfImage
	mov globModuleSize, eax

	; get module path
	xor rcx, rcx ; hModule
	lea rdx, globModuleFolderPath ; lpFilename
	mov r8, 512 ; nSize
	call GetModuleFileNameW
	mov edx, eax ; nSize

	; walk back to last \
	lea rcx, globModuleFolderPath
cont_backslash:
	dec edx
	mov r8w, word ptr [rcx + rdx * 2]
	cmp r8w, 5Ch
	jne cont_backslash

	lea rcx, [rcx + rdx * 2]
	mov word ptr [rcx], 0 ; null-terminate, remove last \
	sub eax, edx 
	mov globModuleFileNameLen, r8w
	mov globModuleFolderPathLen, ax

	; save 
	mov r9, rsi
	mov rax, rdi
	
	; copy module file name
	mov rsi, rcx ; source
	add rsi, 2 ; skip null-terminator
	lea rdi, globModuleFileName ; destination
	mov ecx, r8d ; count
	rep movsw

	; restore
	mov rsi, r9
	mov rdi, rax

	; get heap
	call GetProcessHeap
	mov globProcHeapHandle, rax

	add rsp, 28h ; shadow space
	ret
win_init endp

win_uninit PROC
	sub rsp, 28h ; shadow space

	call win_destroy_window

	add rsp, 28h ; shadow space
	ret
win_uninit endp

win_terminate PROC
	sub rsp, 28h ; shadow space
	mov ecx, 0 ; uExitCode
	call ExitProcess
	int 3
	add rsp, 28h ; shadow space
win_terminate endp

win_alloc PROC
	mov r8d, ecx ; dwBytes
	mov edx, 8 ; dwFlags, HEAP_ZERO_MEMORY
	mov rcx, globProcHeapHandle ; hHeap
	jmp HeapAlloc
win_alloc endp	

win_free PROC
	mov r8, rcx ; lpMem
	xor edx, edx ; dwFlags
	mov rcx, globProcHeapHandle ; hHeap
	jmp HeapFree
win_free endp

win_create_window PROC
	; 28h shadow + raddr
	; SIZEOF WNDCLASSEXW 
	; 80h CreateWindowExW params
	sub rsp, (28h + SIZEOF WNDCLASSEXW + 80h)
	; set up WNDCLASSEXW
	lea rcx, [rsp + 28h]
	mov dword ptr [rcx + WNDCLASSEXW.cbSize], SIZEOF WNDCLASSEXW
	mov dword ptr [rcx + WNDCLASSEXW.style], 3h ; CS_HREDRAW | CS_VREDRAW
	lea rax, DefWindowProcW
	mov qword ptr [rcx + WNDCLASSEXW.lpfnWndProc], rax
	mov dword ptr [rcx + WNDCLASSEXW.cbClsExtra], 0
	mov dword ptr [rcx + WNDCLASSEXW.cbWndExtra], 0
	mov rax, globModuleHandle
	mov qword ptr [rcx + WNDCLASSEXW.hInstance], rax
	mov qword ptr [rcx + WNDCLASSEXW.hIcon], 0
	mov qword ptr [rcx + WNDCLASSEXW.hCursor], 0
	mov qword ptr [rcx + WNDCLASSEXW.hbrBackground], 6
	mov qword ptr [rcx + WNDCLASSEXW.lpszMenuName], 0
	lea rax, winClassName
	mov qword ptr [rcx + WNDCLASSEXW.lpszClassName], rax
	mov qword ptr [rcx + WNDCLASSEXW.hIconSm], 0

	; register class
	call RegisterClassExW
	test eax, eax
	jnz win_create_window_class_success
	int 3
win_create_window_class_success:

	; CreateWindowExW params
	mov ecx, 80000000h ; CW_USEDEFAULT
	mov dword ptr [rsp + 20h], ecx ; x
	mov dword ptr [rsp + 28h], ecx ; y
	mov dword ptr [rsp + 30h], ecx ; nWidth
	mov dword ptr [rsp + 38h], ecx ; nHeight
	mov qword ptr [rsp + 40h], 0 ; hWndParent
	mov qword ptr [rsp + 48h], 0 ; hMenu
	mov rcx, globModuleHandle
	mov qword ptr [rsp + 50h], rcx ; hInstance
	mov qword ptr [rsp + 58h], 0 ; lpParam

	; dwExStyle
	mov ecx, 0
	; lpClassName
	lea rdx, winClassName
	; lpWindowName
	lea r8, globModuleFileName
	; dwStyle
	mov r9d, 0CF0000h ; WS_OVERLAPPEDWINDOW

	call CreateWindowExW
	test rax, rax
	jnz win_create_window_hwnd_success
	int 3
	win_create_window_hwnd_success:

	mov globWindowHandle, rax
	mov rcx, rax
	mov edx, 5 ; SW_SHOW
	call ShowWindow
	mov rcx, rax
	call UpdateWindow

	add rsp, (28h + SIZEOF WNDCLASSEXW + 80h)
	ret
win_create_window endp

win_dispatch_messages PROC
	; 20h shadow,
	; 8h PeekMessageW wRemoveMsg
	; 8h raddr
	sub rsp, (28h + SIZEOF MSG + 8h)
	push rsi
	;mov qword ptr [rsp + 28h + SIZEOF MSG], rsi
	xor sil, sil
peek_loop:
	lea rcx, [rsp + 28h] ; msg
	; zero out MSG
	mov qword ptr [rcx + MSG.hwnd], 0
	mov dword ptr [rcx + MSG.message], 0
	mov qword ptr [rcx + MSG.wParam], 0
	mov qword ptr [rcx + MSG.lParam], 0
	mov dword ptr [rcx + MSG.time], 0
	mov dword ptr [rcx + MSG.pt.x], 0
	mov dword ptr [rcx + MSG.pt.y], 0
	mov dword ptr [rcx + MSG.lPrivate], 0

	; peek message
	xor edx, edx ; hWnd
	mov r8, 0 ; wMsgFilterMin
	mov r9, 0 ; wMsgFilterMax
	mov dword ptr [rsp + 20h], 1 ; wRemoveMsg
	call PeekMessageW
	test eax, eax
	jz peek_loop_end

	; translate message
	lea rcx, [rsp + 28h] ; lpMsg
	call TranslateMessage

	; dispatch message
	lea rcx, [rsp + 28h] ; lpMsg
	call DispatchMessageW

	; test if exit message
	mov eax, dword ptr [rsp + 28h + MSG.message]
	cmp eax, 12h ; WM_QUIT
	sete al
	or sil, al

	jmp peek_loop

peek_loop_end:
	mov al, sil
	;mov rsi, qword ptr [rsp + 28h + SIZEOF MSG]
	pop rsi
	add rsp, (28h + SIZEOF MSG + 8h)
	ret
win_dispatch_messages endp

win_destroy_window PROC
	sub rsp, 28h ; shadow+raddr

	mov rcx, globWindowHandle
	test rcx, rcx
	jz win_destroy_window_skip
	call DestroyWindow
	win_destroy_window_skip:

	add rsp, 28h ; shadow+raddr
	ret
win_destroy_window endp



END
