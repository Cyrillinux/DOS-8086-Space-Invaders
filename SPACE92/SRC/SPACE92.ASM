;
;   _____                        _____                     _               
;  / ____|                      |_   _|                   | |              
; | (___  _ __   __ _  ___ ___    | |  _ ____   ____ _  __| | ___ _ __ ___ 
;  \___ \| '_ \ / _` |/ __/ _ \   | | | '_ \ \ / / _` |/ _` |/ _ \ '__/ __|
;  ____) | |_) | (_| | (_|  __/  _| |_| | | \ V / (_| | (_| |  __/ |  \__ \
; |_____/| .__/ \__,_|\___\___| |_____|_| |_|\_/ \__,_|\__,_|\___|_|  |___/
;        | |                                                                                                                              
;  ___   |_|  ___             ___         
; | _ )_  _  | _ ) ___ _ _   | _ \__ _ ___
; | _ \ || | | _ \/ -_) ' \  |   / _` |_ /
; |___/\_, | |___/\___|_||_| |_|_\__,_/__|
;      |__/                               
;
; Space Invaders by Ben Raz.
;


IDEAL
MODEL small
ideal
;Version EQU "1.00"
stack   4096                ;Allocate 4K stack
P386

DATASEG
;******
;* Variables
;*
PspAddress  dw  ?           ;Segment address of Program Segment Prefix(PSP)
SavePspSeg  dw  ?
SavedDS     dw  ?           ;For the control-break handler to find the path
                            ;variables for restoring the original path and
                            ;drive.
SizeOfProg  dw  0
ModMain                                db  "ASSETS\SNMAIN.MOD",0
ModMenu1                               db  "ASSETS\SNMNU1.MOD",0
ModMenu2                               db  "ASSETS\SNMNU2.MOD",0

include  "globals.inc"
include  "libpps.inc"
CODESEG

include "FILEUSE.ASM"
include "GAME.ASM"
include "PRINT.ASM"
include "MENUS.ASM"


start:
	mov ax, @data
	mov ds, ax

    ;Check if debug mode is enabled ( -dbg flag)
	call CheckDebug
	cmp ax, 0
	je setVideoMode

	mov [byte ptr DebugBool], 1 ;set debug as true

setVideoMode:
	;Set video mode:
	mov ax, 13h
	int 10h

    call Initialize
	call PrintMainMenu

	;Set text mode back:
	mov ax, 03h
	int 10h

exit:
	mov ax, 4c00h
	int 21h
;******
;* Initialize
;*
proc    Initialize
    ;Store the PSP address by storing es in the variable PspAddress.
    ;Note that we do it this way instead of using DOS function 62h because
    ;the function is only available on DOS 3.0 or later.
        mov  [PspAddress], es
        push es
        mov  ax, seg PSPAddress
        mov  es, ax
        mov  bx, [es:PSPAddress]
        mov  es, bx
        mov  ax, EndProgSeg
        sub  ax, bx
        mov  bx,ax
        inc  bx               ;Safety margin
        inc  bx
        mov  [cs:SizeOfProg],bx
        mov  ah, 4ah          ;Memory block resize opcode
        int  21h
        pop  es
        mov  ax,ds
        mov  [SavedDS],ax
        mov  bx,255
        call sd_InitSound
        ret
endp    Initialize
segment EndProgSeg              ;Dummy final segment for calculating program size
LastBytes    db    16 dup (?)   ;to release memory back to DOS.
ends    EndProgSeg
END start
