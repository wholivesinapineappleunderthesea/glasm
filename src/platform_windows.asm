;INCLUDE platform_windows.inc

INCLUDE masm_macros.inc

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
MSG STRUCT
	hwnd QWORD ?
	message DWORD ?
	wParam QWORD ?
	lParam QWORD ?
	time DWORD ?
	pt POINT <>
	lPrivate DWORD ?
MSG ENDS

; PIXELFORMATDESCRIPTOR
PIXELFORMATDESCRIPTOR STRUCT
	nSize WORD ?
	nVersion WORD ?
	dwFlags DWORD ?
	iPixelType BYTE ?
	cColorBits BYTE ?
	cRedBits BYTE ?
	cRedShift BYTE ?
	cGreenBits BYTE ?
	cGreenShift BYTE ?
	cBlueBits BYTE ?
	cBlueShift BYTE ?
	cAlphaBits BYTE ?
	cAlphaShift BYTE ?
	cAccumBits BYTE ?
	cAccumRedBits BYTE ?
	cAccumGreenBits BYTE ?
	cAccumBlueBits BYTE ?
	cAccumAlphaBits BYTE ?
	cDepthBits BYTE ?
	cStencilBits BYTE ?
	cAuxBuffers BYTE ?
	iLayerType BYTE ?
	bReserved BYTE ?
	dwLayerMask DWORD ?
	dwVisibleMask DWORD ?
	dwDamageMask DWORD ?
PIXELFORMATDESCRIPTOR ENDS

EXTERN PeekMessageW: PROC
EXTERN TranslateMessage: PROC
EXTERN DispatchMessageW: PROC
EXTERN DefWindowProcW: PROC
EXTERN PostQuitMessage: PROC
EXTERN ShowWindow: PROC
EXTERN UpdateWindow: PROC

EXTERN RegisterClassExW: PROC
EXTERN CreateWindowExW: PROC
EXTERN DestroyWindow: PROC

EXTERN GetDC: PROC
EXTERN ChoosePixelFormat: PROC
EXTERN SetPixelFormat: PROC
EXTERN wglCreateContext: PROC
EXTERN wglMakeCurrent: PROC
EXTERN wglDeleteContext: PROC

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
globWindowDC QWORD 0
PUBLIC globWindowDC 
globWindowGLRC QWORD 0
PUBLIC globWindowGLRC

.CONST
winClassName DW 'g', 'l', 'a', 's', 'm', '0', '1', 0

.CODE
win_init PROC
	; 28h shadow+call
	sub rsp, (28h)

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

	add rsp, (28h)
	ret
win_init endp

win_uninit PROC
	; 28h shadow+call
	sub rsp, (28h)
	
	call win_destroy_window

	add rsp, (28h)
	ret
win_uninit endp

win_terminate PROC
	; 28h shadow+call
	sub rsp, (28h)
	mov ecx, 0 ; uExitCode
	call ExitProcess
	int 3
	add rsp, (28h)
win_terminate endp

win_alloc PROC
	; 28h shadow+call
	sub rsp, (28h)
	mov r8d, ecx ; dwBytes
	mov edx, 8 ; dwFlags, HEAP_ZERO_MEMORY
	mov rcx, globProcHeapHandle ; hHeap
	call HeapAlloc
	test rax, rax
	jnz win_alloc_success
	int 3
win_alloc_success:
	add rsp, (28h)
	ret
win_alloc endp	

win_free PROC
	test rcx, rcx
	jz win_free_skip
	mov r8, rcx ; lpMem
	xor edx, edx ; dwFlags
	mov rcx, globProcHeapHandle ; hHeap
	jmp HeapFree
win_free_skip:
	ret
win_free endp

win_wndproc PROC
	; 28h shadow+call
	; 8h hWnd
	; 8h uMsg
	; 8h wParam
	; 8h lParam
	sub rsp, (28h + 8h + 8h + 8h + 8h)
	mov qword ptr [rsp + 28h], rcx ; hWnd
	mov dword ptr [rsp + 30h], edx ; uMsg
	mov qword ptr [rsp + 38h], r8 ; wParam
	mov qword ptr [rsp + 40h], r9 ; lParam

	; WM_DESTROY
	cmp edx, 02h ; WM_DESTROY
	jne not_wm_destroy
	xor ecx, ecx ; uExitCode
	call PostQuitMessage

	mov rcx, globWindowGLRC
	test rcx, rcx
	jz win_destroy_glrc_done
	call wglDeleteContext
	mov globWindowGLRC, 0
win_destroy_glrc_done:

	mov globWindowDC, 0
	mov globWindowHandle, 0

	xor eax, eax ; If an application processes this message, it should return zero.
	jmp wndproc_handled
not_wm_destroy:

	jmp call_defwndproc
wndproc_handled:
	add rsp, (28h + 8h + 8h + 8h + 8h)
	ret
call_defwndproc:
	mov rcx, qword ptr [rsp + 28h] ; hWnd
	mov edx, dword ptr [rsp + 30h] ; uMsg
	mov r8, qword ptr [rsp + 38h] ; wParam
	mov r9, qword ptr [rsp + 40h] ; lParam
	add rsp, (28h + 8h + 8h + 8h + 8h)
	jmp DefWindowProcW
win_wndproc endp

win_create_wgl PROC
	; 28h shadow+call
	; SIZEOF PIXELFORMATDESCRIPTOR
	sub rsp, (28h + ALIGN_TO_16(SIZEOF PIXELFORMATDESCRIPTOR))

	mov rcx, globWindowDC
	lea rdx, [rsp + 28h] ; ppfd
	mov word ptr [rdx + PIXELFORMATDESCRIPTOR.nSize], SIZEOF PIXELFORMATDESCRIPTOR
	mov word ptr [rdx + PIXELFORMATDESCRIPTOR.nVersion], 1h
	mov dword ptr [rdx + PIXELFORMATDESCRIPTOR.dwFlags], 25h ; PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.iPixelType], 0 ; PFD_TYPE_RGBA
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cColorBits], 20h ; 32
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cRedBits], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cRedShift], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cGreenBits], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cGreenShift], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cBlueBits], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cBlueShift], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cAlphaBits], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cAlphaShift], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cAccumBits], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cAccumRedBits], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cAccumGreenBits], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cAccumBlueBits], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cAccumAlphaBits], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cDepthBits], 32 
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cStencilBits], 8
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.cAuxBuffers], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.iLayerType], 0
	mov byte ptr [rdx + PIXELFORMATDESCRIPTOR.bReserved], 0
	mov dword ptr [rdx + PIXELFORMATDESCRIPTOR.dwLayerMask], 0
	mov dword ptr [rdx + PIXELFORMATDESCRIPTOR.dwVisibleMask], 0
	mov dword ptr [rdx + PIXELFORMATDESCRIPTOR.dwDamageMask], 0

	call ChoosePixelFormat
	test eax, eax
	jnz win_create_wgl_choose_success
	int 3
win_create_wgl_choose_success:
	
	mov rcx, globWindowDC
	mov edx, eax
	lea r8, [rsp + 28h] ; ppfd
	call SetPixelFormat
	test eax, eax
	jnz win_create_wgl_set_success
	int 3
win_create_wgl_set_success:

	mov rcx, globWindowDC
	call wglCreateContext
	test rax, rax
	jnz win_create_wgl_create_success
	int 3
win_create_wgl_create_success:
	mov globWindowGLRC, rax

	mov rcx, globWindowDC
	mov rdx, rax
	call wglMakeCurrent
	test eax, eax
	jnz win_create_wgl_makecur_success
	int 3
win_create_wgl_makecur_success:

	add rsp, (28h + ALIGN_TO_16(SIZEOF PIXELFORMATDESCRIPTOR))
	ret
win_create_wgl endp

win_create_window PROC
	; 28h shadow + call
	; SIZEOF WNDCLASSEXW 
	; 80h CreateWindowExW params
	sub rsp, (28h + ALIGN_TO_16(SIZEOF WNDCLASSEXW) + 80h)

	; set up WNDCLASSEXW
	lea rcx, [rsp + 28h]
	mov dword ptr [rcx + WNDCLASSEXW.cbSize], SIZEOF WNDCLASSEXW
	mov dword ptr [rcx + WNDCLASSEXW.style], 023h ; CS_HREDRAW | CS_VREDRAW | CS_OWNDC
	lea rax, win_wndproc
	mov qword ptr [rcx + WNDCLASSEXW.lpfnWndProc], rax
	mov dword ptr [rcx + WNDCLASSEXW.cbClsExtra], 0
	mov dword ptr [rcx + WNDCLASSEXW.cbWndExtra], 0
	mov rax, globModuleHandle
	mov qword ptr [rcx + WNDCLASSEXW.hInstance], rax
	mov qword ptr [rcx + WNDCLASSEXW.hIcon], 0
	mov qword ptr [rcx + WNDCLASSEXW.hCursor], 0
	mov qword ptr [rcx + WNDCLASSEXW.hbrBackground], 6 ; COLOR_WINDOW
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

	mov rcx, globWindowHandle
	call UpdateWindow

	mov rcx, globWindowHandle
	call GetDC
	test rax, rax
	jnz win_create_window_dc_success
	int 3
win_create_window_dc_success:
	mov globWindowDC, rax

	call win_create_wgl

	add rsp, (28h + ALIGN_TO_16(SIZEOF WNDCLASSEXW) + 80h)
	ret
win_create_window endp

win_dispatch_messages PROC
	; 28h shadow+call
	; SIZEOF MSG
	; 8h PeekMessageW wRemoveMsg
	sub rsp, (28h + ALIGN_TO_16(SIZEOF MSG) + 8h)

	push rsi
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
	pop rsi
	add rsp, (28h + ALIGN_TO_16(SIZEOF MSG) + 8h)
	ret
win_dispatch_messages endp

win_destroy_window PROC
	; shadow+call
	sub rsp, 28h

	mov rcx, globWindowHandle
	test rcx, rcx
	jz win_destroy_window_done
	call DestroyWindow
	mov globWindowHandle, 0
win_destroy_window_done:

	add rsp, 28h
	ret
win_destroy_window endp



END
