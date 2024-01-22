INCLUDE platform_windows.inc

.CODE

asm_entry PROC
	sub rsp, 28h
	call win_init

	call win_create_window

	call win_destroy_window

	call win_uninit
	call win_terminate
	add rsp, 28h
	ret
asm_entry ENDP

END