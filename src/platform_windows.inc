EXTERN globModuleSize:DWORD
EXTERN globModuleHandle:QWORD

; 512 WORDS MAX for these buffers:
EXTERN globModuleFolderPath:WORD ; not including the trailing slash
EXTERN globModuleFolderPathLen:WORD
EXTERN globModuleFileName:WORD ; name.exe
EXTERN globModuleFileNameLen:WORD

EXTERN win_init:PROC
EXTERN win_uninit:PROC
EXTERN win_terminate:PROC

; heap
; allocs to 16 byte alignment
EXTERN globProcHeapHandle:QWORD
EXTERN win_alloc:PROC
EXTERN win_free:PROC

; window
EXTERN globWindowHandle:QWORD
EXTERN win_create_window:PROC
EXTERN win_destroy_window:PROC