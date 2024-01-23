cmake_minimum_required(VERSION 3.20)

project(glasm)

enable_language(C ASM_MASM)

# glob all asm files in src/*
file(GLOB ASM_SOURCES src/*.asm)

# dummy c file to make cmake happy
set(C_SOURCES src/dummy.c)

add_executable(glasm ${ASM_SOURCES} ${C_SOURCES})

set_source_files_properties(${ASM_SOURCES} PROPERTIES LANGUAGE ASM_MASM)

# set /Zi flag for debug info
set_source_files_properties(${ASM_SOURCES} PROPERTIES COMPILE_FLAGS "/Zi")

# enable debug link if debug build
if(CMAKE_BUILD_TYPE MATCHES Debug)
	set_target_properties(glasm PROPERTIES LINK_FLAGS "/DEBUG")
endif()

# dont link c runtime
set_target_properties(glasm PROPERTIES LINK_FLAGS "/NODEFAULTLIB")

# set entry point
set_target_properties(glasm PROPERTIES LINK_FLAGS "/ENTRY:asm_entry")

# link with opengl32.lib
target_link_libraries(glasm opengl32.lib)