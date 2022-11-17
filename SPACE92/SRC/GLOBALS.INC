;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

CursorOff = 2000h
NumCols 	= 80
NumRows 	= 25

MAX_PATH_LENGTH = 80

FILE_SPEC_SIZE  = 15

F_File		= 0
F_Directory	= 1
F_Drive 	= 2
F_PCX		= 3

T_Size15	= 0
T_Size31	= 1

DTA_dosuse	= 0
DTA_dosattr	= 15h
DTA_dostime	= 16h
DTA_dosdate	= 18h
DTA_lsize	= 1Ah
DTA_hsize	= 1Ch
DTA_dosname	= 1Eh
DTA_totallength = 1Fh


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
codeseg

global  DetermineDisplay:proc
global	SetCursor:proc				; SetCursor,CursorSize
global	Write:proc				; Write X,Y,Attr,String
global	WriteMemLeft:proc			; WriteMemLeft,Row
global	ConvertKToStr:proc			; ConvertKToStr NumK,String
global	RestoreMode:proc
global	SetMode:proc
global	WriteChars:proc
global	WriteCol:proc
global	HowMuchMemory:proc
global	FillBox:proc

;--------------
global	ReadFiles:proc
global	SortFiles:proc
global	DisplayFiles:proc
global	DisplayDrives:proc
global	DisplayDriveStuff:proc
global	DisplayAll:proc
global	DisplayFileMax:proc

;-------------
global  WriteStandardInfo:proc
global	CheckStandardKeys:proc

;------------
global	AltScrn1:proc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
dataseg

global	TopFileLine:byte

global  Screen:word

global  kline:byte:6
global	kline2:byte:6
global  MaxFiles:word
global	FileSeg:dword
global	CurFile:word
global	NumFiles:word
global	TopFile:word

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

struc   FStruc
Filename	db	13 dup (?)
Title           db      14h dup (?)
TitleZero	db	?
KInFile         dw      ?
TypeOfFile	db	?
TaggedFile      db      ?
BadModule       db      ?
ends    FStruc

struc	Psp ; Structure representing DOS's Program Segment Prefix(Psp)
    Int20h              dw  ?   ; Int 20h
    EndOfAllocation dw  ?   ; Segment, end of allocation block
    Reserved1           db  ?   ; Reserved by DOS
    MsDosDispatcher db  5h  dup (?) ; Long call to MS-DOS function
                                        ; dispatcher
    OldTermination      dd  ?   ; Previous contents of termination handler
                                ; interrupt vector(Int 22h)
    OldCtrlCHandler dd  ?   ; Previous contents of CTRL-C interrupt
                                ; vector(Int 23h)
    OldCriticalError    dd  ?   ; Previous contents of critical-error
                                ; interrupt vector(Int 24h)
    Reserved2           db  16h dup (?) ; Reserved by DOS
    EnvironmentBlock    dw  ?           ; Segment address of environment block
    Reserved3           db  2Eh dup (?) ; Reserved by DOS
    Fcb1                db  10h dup (?) ; Default File Control Block(FCB) #1
    Fcb2                db  14h dup (?) ; Default File Control Block(FCB) #2
    CommandTail 	db  ? ; Command tail and default Dta
ends    ; Psp

; The following record type represents the file attributes field in a
; DOS directory entry.

record  FileAttribType  UnUsed:2, Archive:1, Directory:1, Volume:1, System:1, Hidden:1, ReadOnly:1

struc   Dta ; Structure representing the DOS Data Transfer Area(Dta)
Reserved	db  15h dup (?)     ; Used by Find Next function
FileAttribute	FileAttribType	<>  ; Attribute of file that was found
    ;         BIT       Meaning
    ; 7 6 5 4 3 2 1 0
    ;               1   Read only
    ;             1     Hidden
    ;           1       System
    ;         1         Volume label
    ;       1           Subdirectory
    ;     1             Archive
    ;   1               Unused
    ; 1                 Unused
Filetime	dw  ?		    ; Time of file modification
Filedate	dw  ?		    ; Date of file modification
Filesize	dd  ?		    ; File size in bytes
Filename	db  13	dup (?)     ; File name(ASCIIZ string)
ends    ; Dta


