INCLUDE masm_macros.inc
INCLUDE platform_windows.inc
INCLUDE gl.inc
.CODE

asm_entry PROC
	sub rsp, (28h)
	call win_init

	call win_create_window

	jmp window_loop
one_frame:
	call glasm_beginframe
	call win_swap_buffers
	call glasm_endframe
window_loop:
	call win_dispatch_messages
	test al, al
	jz one_frame

	call win_destroy_window

	call win_uninit
	call win_terminate
	add rsp, (28h)
	ret
asm_entry ENDP

END