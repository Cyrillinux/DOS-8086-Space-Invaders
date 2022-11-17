;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  FILENAME: PPS.ASM    Version 1.00                         ³
;³                                         ³
;³  DATE    : April 27, 1992                             ³
;³                                                                           ³
;³  Ideal Mode -- Turbo Assembler v2.01 and above                 ³
;³                                                                           ³
;³  DESCRIPTION: This file includes all routines for playing music modules.  ³
;³         Many of the routines, before my HD crash, were written by   ³
;³         a friend, Mark Anderson.  I appreciate those original         ³
;³         routines, and thank him for it, but I had to rewrite         ³
;³         everything from scratch.  He spent many hours working on    ³
;³         routines for SuperProPlay, especially when I didn't have    ³
;³         a computer that could play modules decently (8mhz).         ³
;³         Thanks Mark!                             ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

    ideal                   ; Use TASM's Ideal mode.
    model  Small,Pascal     ; Define the memory model.
    P286                    ; Set up for 286 instructions.
    jumps                   ; Have TASM automatically resolve out-
                            ; of-range jumps.

include "libpps.inc"

dataseg

Fatal   db   0

MusicPlayerInstalled  db  0 ; Music handler installed...or not?

;-------- Special MOD Header declarations
SequenceOffset  dw   0      ; Where do the Sequences begin?
HeaderSize      dw   0      ; How big is the header?
NumberInstruments dw  0     ; Num Ins in module.

TypeOfSample db   0       ; 0 for <64k, 1 for >64k
                    ; Set when loading module; Not
                    ; implemented in this version.

SoundSource        db    0    ; Corresponds to position of Sound
                                        ; Source in SoundSources.
label   SoundSources    SoundSrcStruc
    SoundSrcStruc    <"Speaker ",0, 42h,0>
    SoundSrcStruc    <"SBlaster",1,  0h,0>
    SoundSrcStruc    <"DAC-LPT1",2,  0h,0>
    SoundSrcStruc    <"DAC-LPT2",2,  0h,0>
    SoundSrcStruc    <"DAC-LPT3",2,  0h,0>
    SoundSrcStruc    <"DAC-LPT4",2,  0h,0>

Channel1  MS      <0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>
Channel2  MS      <0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>
Channel3  MS      <0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>
Channel4  MS      <0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>

MaxVolume    dw    0    ; This is the max volume setting
PlayStatus    db    0    ; 0 --> Play regular (stop at end).
                ; 1 --> Play forever.
NumBlocks       db      0

ModuleLoaded    db    0    ; 0 - No, 1 - Yes
MStatus     db    1    ; 0 - Running, 1 - Off

; This table is a kluge...how many people actually play modules out of their
; speakers anyway?

TranslationTable:
    db    1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3
    db    4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6
    db    7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9
    db    10,10,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11
    db    12,12,12,12,12,12,12,12,12,12,13,13,13,13,13,13,13,13,13,13
    db    14,14,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,15,15
    db    16,16,16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17,17,17
    db    18,18,18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,19,19
    db    20,20,20,20,20,20,20,20,20,20,21,21,21,21,21,21,21,21,21,21
    db    22,22,22,22,22,22,22,22,22,22,23,23,23,23,23,23,23,23,23,23
    db    24,24,24,24,24,24,24,24,24,24,25,25,25,25,25,25,25,25,25,25
    db    26,26,26,26,26,26

Header      db      1084 dup (0)
InsLoc      dw      31 dup (0)
PatternLoc  dw    64 dup (0)

SampleRate  dw    0    ; Generally 15909.
MainFreq    dd      0
LSBCounter   dw      0
IntMaster    dw    0    ; Value that is restored into IntCountDown.
IntCountDown dw    0    ; Countdown value.  When it hits zero,
                ; UpdateChannels is called.
IntSet      db    0    ; 0 if no interrupt, 1 if running.
TypeOfInt   db    0    ; 1 for music, 2 for sample.
Int1Ch      dd    0    ; Storage for the timer interrupt.
IntMask         db      0
FreqMult    dw    0
MainAddr    dw    0    ; Address to play out of.
PlayerInterrupt dw    0    ; Holding place for the interrupt.
TimeValue    dw    0    ; This, divided by 50, is the number of seconds
                ; that the music has played.
Mode5Cntr    db    0
; Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿Ú¿
;ÄÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀÙÀ
; Seg                           Stores the segment of the current sample.  If
;                               the segment is zero, then there is no sample
;                               begin played.
; Offset                        The current offset of the sample being played
;                               in the segment specified.
; MaxRep                        The offset of the place in the sample to
;                repeat from (i.e. the end of the sample).
; Freq                          The frequency to be played out the output
;                               device.  It is actually a playback period,
;                               the upper byte determining the number of
;                               bytes to be added to the sample offset each
;                               interrupt, and the lower byte to be added
;                               over and over to generate carry flags to be
;                               added to additional offsets.
; Vol1                          The actual volume to multiply the frequency
;                               by.
; Repeat                        The place to repeat from when the end of the
;                               loop is found.
; RepLen                        The number of bytes from Repeat to go to.
;                               When the end of this is found, it goes back
;                               to Repeat.
; OFlow                         The overflow variable used to generate the
;                               carry flags.

;ÄChannel 1 StuffÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Channel1Seg     dw      0
Channel1Ofs     dw      0
Channel1Repeat  dw      0
Channel1RepLen  dw      0
Channel1Freq    dw    0
Channel1MaxRep    dw    0
Channel1OFlow   dw      0
Channel1Vol1    db    0
Channel1Ins     db      0

;ÄChannel 2 StuffÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Channel2Seg    dw    0
Channel2Ofs    dw    0
Channel2Repeat    dw    0
Channel2RepLen    dw    0
Channel2Freq    dw    0
Channel2MaxRep    dw    0
Channel2OFlow   dw      0
Channel2Vol1    db    0
Channel2Ins     db      0

;ÄChannel 3 StuffÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Channel3Seg    dw    0
Channel3Ofs    dw    0
Channel3Repeat    dw    0
Channel3RepLen    dw    0
Channel3Freq    dw    0
Channel3MaxRep    dw    0
Channel3OFlow   dw      0
Channel3Vol1    db    0
Channel3Ins     db      0

;ÄChannel 4 StuffÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Channel4Seg    dw    0
Channel4Ofs    dw    0
Channel4Repeat    dw    0
Channel4RepLen    dw    0
Channel4Freq    dw    0
Channel4MaxRep    dw    0
Channel4OFlow   dw      0
Channel4Vol1    db    0
Channel4Ins     db      0

;ÚÄ¿ Protracker specific
;ÀÄÙ variables.
mt_speed                db      0
mt_counter        db    0
mt_PatternPos        dw    0
mt_SongPos        db    0
mt_PattDelayTime2       db      0
mt_PattDelayTime        db      0
mt_PBreakFlag           db      0
mt_PBreakPos            db      0
mt_PosJumpFlag          db      0
mt_LowMask              db      0FFh

mt_FunkTable        db    0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128
 
mt_VibratoTable:    db      0, 24, 49, 74, 97,120,141,161
            db    180,197,212,224,235,244,250,253
            db    255,253,250,244,235,224,212,197
            db    180,161,141,120, 97, 74, 49, 24
 
mt_PeriodTable:
; Tuning 0, Normal
        dw    856,808,762,720,678,640,604,570,538,508,480,453
        dw    428,404,381,360,339,320,302,285,269,254,240,226
        dw    214,202,190,180,170,160,151,143,135,127,120,113
; Tuning 1
        dw    850,802,757,715,674,637,601,567,535,505,477,450
        dw    425,401,379,357,337,318,300,284,268,253,239,225
        dw    213,201,189,179,169,159,150,142,134,126,119,113
; Tuning 2
        dw    844,796,752,709,670,632,597,563,532,502,474,447
        dw    422,398,376,355,335,316,298,282,266,251,237,224
        dw    211,199,188,177,167,158,149,141,133,125,118,112
; Tuning 3
        dw    838,791,746,704,665,628,592,559,528,498,470,444
        dw    419,395,373,352,332,314,296,280,264,249,235,222
        dw    209,198,187,176,166,157,148,140,132,125,118,111
; Tuning 4
        dw    832,785,741,699,660,623,588,555,524,495,467,441
        dw    416,392,370,350,330,312,294,278,262,247,233,220
        dw    208,196,185,175,165,156,147,139,131,124,117,110
; Tuning 5
        dw    826,779,736,694,655,619,584,551,520,491,463,437
        dw    413,390,368,347,328,309,292,276,260,245,232,219
        dw    206,195,184,174,164,155,146,138,130,123,116,109
; Tuning 6
        dw    820,774,730,689,651,614,580,547,516,487,460,434
        dw    410,387,365,345,325,307,290,274,258,244,230,217
        dw    205,193,183,172,163,154,145,137,129,122,115,109
; Tuning 7
        dw    814,768,725,684,646,610,575,543,513,484,457,431
        dw    407,384,363,342,323,305,288,272,256,242,228,216
        dw    204,192,181,171,161,152,144,136,128,121,114,108
; Tuning -8
        dw    907,856,808,762,720,678,640,604,570,538,508,480
        dw    453,428,404,381,360,339,320,302,285,269,254,240
        dw    226,214,202,190,180,170,160,151,143,135,127,120
; Tuning -7
        dw    900,850,802,757,715,675,636,601,567,535,505,477
        dw    450,425,401,379,357,337,318,300,284,268,253,238
        dw    225,212,200,189,179,169,159,150,142,134,126,119
; Tuning -6
        dw    894,844,796,752,709,670,632,597,563,532,502,474
        dw    447,422,398,376,355,335,316,298,282,266,251,237
        dw    223,211,199,188,177,167,158,149,141,133,125,118
; Tuning -5
        dw    887,838,791,746,704,665,628,592,559,528,498,470
        dw    444,419,395,373,352,332,314,296,280,264,249,235
        dw    222,209,198,187,176,166,157,148,140,132,125,118
; Tuning -4
        dw    881,832,785,741,699,660,623,588,555,524,494,467
        dw    441,416,392,370,350,330,312,294,278,262,247,233
        dw    220,208,196,185,175,165,156,147,139,131,123,117
; Tuning -3
        dw    875,826,779,736,694,655,619,584,551,520,491,463
        dw    437,413,390,368,347,328,309,292,276,260,245,232
        dw    219,206,195,184,174,164,155,146,138,130,123,116
; Tuning -2
        dw    868,820,774,730,689,651,614,580,547,516,487,460
        dw    434,410,387,365,345,325,307,290,274,258,244,230
        dw    217,205,193,183,172,163,154,145,137,129,122,115
; Tuning -1
        dw    862,814,768,725,684,646,610,575,543,513,484,457
        dw    431,407,384,363,342,323,305,288,272,256,242,228
        dw    216,203,192,181,171,161,152,144,136,128,121,114
 
codeseg

;---------------------------------------------------
; Format of a note:
;
;                   00           00           00           00
;                   ||           ||           ||           ||
;                   /\           //           /\           \\
;      MSB of Ins.      Note          LSB Ins. Spec. Com.   Data for special
;

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_UpdateChannels                         ³
;³                                         ³
;³ ENTRY      : None                                 ³
;³                                         ³
;³ RETURN     : None                                 ³
;³                                         ³
;³ DESCRIPTION: This procedure shouldn't need to be called by anything else  ³
;³        but the interrupt (ever).  It handles all note updating,     ³
;³        special effects, pointers, etc.                  ³
;³                                         ³
;³        *** This code came directly from the Amiga Protracker         ³
;³            playback code, written by Lars "Zap" Hamre.  Give this   ³
;³            guy a pat on the back for such excellent code.         ³
;³                                         ³
;³        *** Converted by Joshua C. Jensen.                 ³
;³                                         ³
;³ BUGS       : Or rather, non-implementations.  Command EF - Funk it is     ³
;³        not all the way implemented.  Command E0 - Filter is not     ³
;³        implemented at all.  It is Amiga-specific, directly with     ³
;³        the Paula chip.                          ³
;³                                                                           ³
;³        For some reason, Porta Up has problems every so often.         ³
;³                                                                           ³
;³        All commands have been tested fully except for Command 7,    ³
;³        Tremolo.  But, since it is an exact duplicate of the         ³
;³        Protracker code, it should work.                 ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc    sd_UpdateChannels near
    mov    ax,@data        ; Put the pointer to the @code segment
    mov    ds,ax            ; into the data segment
    mov    es,ax            ; and extra segment
    cmp    [Byte MStatus],1    ; Are we done yet???
    jnz    mt_ContinueUpdate    ; Nope.
    ret                ; Yes, don't update anything.

mt_ContinueUpdate:
    inc    [Byte mt_counter]    ; Increment our counter.
    mov    al,[mt_counter]     ; Load it into AL.
    cmp    al,[mt_speed]        ; Does it match the current speed?
    jb    mt_NoNewNote        ; No, just do fx.
    mov    [Byte mt_counter],0
    cmp    [Byte mt_PattDelayTime2],0
    jz    mt_GetNewNote
    call    mt_NoNewAllChannels    ; Otherwise, just do fx only.
    jmp    mt_dskip        ; Then, jump to update block values.

mt_NoNewNote:
    call    mt_NoNewAllChannels    ; Do fx.
    jmp    mt_NoNewPosYet        ; We don't update block values when we are just doing fx.

mt_NoNewAllChannels:
    mov    si,offset Channel1    ; Do Channel 1
    mov    bp,offset Channel1Seg
    call    mt_CheckEfx        ; Check the fx for this channel.
    mov    si,offset Channel2    ; Do Channel 2
    mov    bp,offset Channel2Seg
    call    mt_CheckEfx        ; Check the fx for this channel.
    mov    si,offset Channel3    ; Do Channel 3
    mov    bp,offset Channel3Seg
    call    mt_CheckEfx        ; Check the fx for this channel.
    mov    si,offset Channel4    ; Do Channel 4
    mov    bp,offset Channel4Seg
    jmp    mt_CheckEfx        ; Check the fx for this channel.

mt_GetNewNote:
        xor     ax,ax
    mov    al,[mt_SongPos]     ; Get the current sequence position.
    add    ax,[SequenceOffset]    ; Pick up the pattern from the list.
    mov    di,ax            ; Set di to point to it.
    xor    ax,ax            ; Clear out AX.
    mov    al,[di+offset Header]    ; Load in the block.
    shl    al,1            ; By multiplying it by two, we can
    mov    di,offset PatternLoc    ; figure out in the block segment list
    add    di,ax            ; where it is so we can set up a pointer.
    mov    es,[di]         ; Get the segment.
    mov    di,[mt_PatternPos]    ; Store in DI the current position
                    ; in the block.

    mov    si,offset Channel1    ; Set pointers for the channel 1
    mov    bp,offset Channel1Seg    ; information and
    call    mt_PlayVoice        ; update the channel.
    mov    si,offset Channel2    ; Set pointers for the channel 2
    mov    bp,offset Channel2Seg    ; information and
    call    mt_PlayVoice        ; update the channel.
    mov    si,offset Channel3    ; Set pointers for the channel 3
    mov    bp,offset Channel3Seg    ; information and
    call    mt_PlayVoice        ; update the channel.
    mov    si,offset Channel4    ; Set pointers for the channel 4
    mov    bp,offset Channel4Seg    ; information and
    call    mt_PlayVoice        ; update the channel.

    jmp    mt_dskip        ; Update the block pointer values.

mt_PlayVoice:
    cmp    [Word si],0        ; See if there is a note.
    jnz    mt_plvskip        ; No, go on.
    cmp    [Word si+2],0
    jnz    mt_plvskip
    call    mt_PerNop        ; Otherwise, figure out the frequency.
mt_plvskip:
    mov    ax,[es:di]        ; Load this channel's information
    mov    [si+MS.Note],ax     ; from the actual pattern block and
    mov    ax,[es:di+02h]        ; into our own internal structure
    mov    [Word si+MS.cmd],ax    ; to access it from.
    add    di,4            ; Increment past the stuff we just
                    ; moved.

    mov    al,[si+MS.cmd]        ; Here we are figuring out which
    and    al,0F0h         ; instrument needs to be played by
    shr    al,4            ; masking and shifting the approp. bits.
        mov     ah,[Byte si+MS.Note]    ; In order to obtain 31 instruments,
    and    ah,0F0h         ; we need to OR this bit into the
    or    al,ah            ; instrument byte.  Is there an ins?
    jz    mt_SetRegs
    mov    bl,al            ; Temporarily store the instrument.
    mov    TSIns,al        ; Store it in the structure.
    mov    [si+MS.SampleNum],al    ; Store it in the MS structure.
    mov    bh,30            ; 30 is the size of an instrument
    mul    bh            ; structure.  Multiply it to find its
    mov    dx,ax            ; location in the header and save it.

    xor    bh,bh            ; Clear out BH.
    dec    bl            ; Decrement the instrument by one so
    shl    bx,1            ; we can find an address in the
    add    bx,offset InsLoc    ; instrument segment array.
    mov    ax,[bx]         ; Get the segment.
    mov    [si+MS.start],ax    ; Store it in our structure.
    mov    bx,dx            ; Load DX into BX.
    add    bx,+0Ch         ; Point bx to the sample.length.
    mov    ax,[bx+offset Header]    ; Get the length.
    mov    [si+MS.Length],ax    ; Store it appropriately.
    mov    [si+MS.RealLength],ax
    mov    ax,[bx+offset Header+02h] ; Get the instrument volume and fine tune.
    mov    [Word si+MS.FineTune],ax ; Store it appropriately.
        mov     al,ah                   ; Put the volume in al.
        mul     [si+MS.MasterVolume]    ; Multiply by the MasterVolume to get
    mov    TSVol1,ah        ; a relative volume and store it.  Idea
                    ; from the MED module playback code.
    mov    cx,[bx+offset Header+06h] ; Get Repeat length
    cmp    cx,4            ; If the length is less than four,
    jb    mt_NoLoop        ; then there is no loop.
    mov    ax,[bx+offset Header+04h]  ; Get the Repeat start.
    shl    ax,1            ; Otherwise, times it by 2.
mt_DoInsPointer2:
    mov    TSRepeat,ax        ; Move it into the appropriate
    mov    [si+MS.LoopStart],ax    ; structures and locations.
        mov     [si+MS.WaveStart],ax
    mov    [si+MS.RepLen],cx    ; Move the length into its storage.
    ; We're figuring out the offset of where the repeat length breaks.
    add    ax,cx            ; Add on the offset.
    add    ax,cx            ; Add it again.
    sub    ax,3
    mov    TSRepeatLen,ax        ; Store it.
    jmp    mt_SetRegs        ; Skip the no loop part.

mt_NoLoop:
    xor    ax,ax            ; Zero out AX.
    mov    TSRepeatLen,ax        ; Make sure that no loop exists and
    mov    TSRepeat,ax
    mov    [si+MS.LoopStart],ax
    mov    [si+MS.WaveStart],ax
    mov    ax,[si+MS.Length]
    mov    [si+MS.RepLen],ax
mt_SetRegs:
    mov    ax,[si+MS.Note]     ; Grab the note.
    xchg    ah,al            ; Amiga exchange.
    and    ax,0FFFh        ; Mask out everything but the note.
    jz    mt_CheckMoreEfx     ; Check the fx.
    mov    ax,[Word si+MS.cmd]    ; Get the special fx command.
    xchg    ah,al            ; Amiga exchange.
    and    ax,0FF0h        ; Mask out the bits we don't want.
    cmp    ax,0E50h        ; Is there a fine tune command?
    jz    mt_DoSetFineTune
    cmp    ah,3            ; Is it a tone portamento?
    jz    mt_ChkTonePorta
    cmp    ah,5            ; Is it a tone and volume slide?
    jz    mt_ChkTonePorta
    cmp    ah,9            ; Is it a sample offset command?
    jnz    mt_SetPeriod        ; If not, go do the actual note.
    call    mt_CheckMoreEfx
    jmp    mt_SetPeriod        ; Go do the actual note.

mt_DoSetFineTune:
    call    mt_SetFineTune        ; Update the fine tune.
    jmp    mt_SetPeriod        ; Go do the note.
 
mt_ChkTonePorta:
    call    mt_SetTonePorta     ; Do part of the tone portamento.
    jmp    mt_CheckMoreEfx     ; Go do the fx.

mt_SetPeriod:
    ; ÄÄÄÄ We are now going to find the note in the period table.  If it
    ; ÄÄÄÄ doesn't exist, then no fine tuning can be performed.  If it
    ; ÄÄÄÄ does, and fine tuning is specified, then we can update it.

    mov    ax,[si+MS.Note]     ; Get the note.
    xchg    ah,al            ; Amiga exchange.
    and    ax,0FFFh        ; Mask out unwanted bits.
    mov    bx,offset mt_PeriodTable; Set pointer to the beginning of table.
    mov    cx,36            ; There are 36 periods to cycle through.
mt_ftuloop:
    cmp    ax,[bx]         ; Check the note against the period.
    jnb    mt_ftufound        ; We found it!
    add    bx,2            ; Otherwise, update the pointer and
    loop    mt_ftuloop        ; keep looping.
mt_ftufound:
    mov    al,[si+MS.FineTune]    ; Get the fine tune.
    mov    cl,36*2         ; The period table's size is 72.
    mul    cl            ; Multiply it by the fine tune.
    add    bx,ax            ; Add it onto the pointer to point to
    mov    ax,[bx]         ; the new period and get it.
    mov    [si+MS.Period],ax    ; Store it.

    mov    ax,[Word si+MS.cmd]
    xchg    ah,al
    and    ax,0FF0h
    cmp    ax,0ED0h
    jz    mt_CheckMoreEfx

    mov    al,[si+MS.WaveControl]    ; Get the WaveControl.
    and    al,00000100b        ; Amiga: BTST #2,WaveControl.
    jz    mt_vibnoc        ; If it is zero, then skip.
    mov    [Byte si+MS.VibratoPos],0
mt_vibnoc:
    mov    al,[si+MS.WaveControl]    ; Get it again.
    and    al,01000000b        ; Amiga: BTST #6,WaveControl
    jz    mt_trenoc        ; If it is zero, then skip.
    mov    [Byte si+MS.TremoloPos],0 ; Zero the Tremolo offset.
mt_trenoc:
    mov    ax,[si+MS.start]    ; Get the start segment.
    mov    TSSeg,ax        ; Store it to be updated.
    xor    cx,cx            ; Clear CX.
    mov    TSOff,cx        ; Set the offset to zero.
    mov    ax,[si+MS.Length]
    shl    ax,1
    mov    TSMaxRep,ax        ; Store in MaxRepeat
    mov    cx,[si+MS.Period]
    call    mt_PerNop2
;     mov     ax,[Word si+MS.cmd]
;     xchg     ah,al
;     and     ax,0FF0h
;     cmp     ax,0ED0h
;     jnz     @@DONEFIN
;     mov     ax,TSMaxRep
;     mov     TSOff,ax
;@@DONEFIN:
;     mov     [si+MS.Trigger],1
        jmp     mt_CheckMoreEfx
endp    sd_UpdateChannels

proc    mt_dskip
    add    [Word mt_PatternPos],16     ; Increment position by one
    mov    al,[mt_PattDelayTime]
        or      al,al
    jz    mt_dskc
    mov    [mt_PattDelayTime2],al
    mov    [Byte mt_PattDelayTime],0
mt_dskc:
    cmp    [Byte mt_PattDelayTime2],0
    jz    mt_dska
    dec    [Byte mt_PattDelayTime2]
    jz    mt_dska
    sub    [Word mt_PatternPos],16
mt_dska:
        cmp     [Byte mt_PBreakFlag],0
    jz    mt_nnpysk
    mov    [Byte mt_PBreakFlag],0
    xor    ax,ax
    mov    al,[mt_PBreakPos]
    mov    [mt_PBreakPos],ah
    shl    ax,4
        mov     [mt_PatternPos],ax
mt_nnpysk:
    cmp    [Word mt_PatternPos],1024
    jb    mt_NoNewPosYet

mt_NextPosition:
    xor    ax,ax
    mov    al,[mt_PBreakPos]
    shl    ax,4
        mov     [mt_PatternPos],ax
    mov    [Byte mt_PBreakPos],0
    mov    [Byte mt_PosJumpFlag],0
    inc    [Byte mt_SongPos]
    and    [Byte mt_SongPos],7Fh
    mov    al,[mt_SongPos]
    mov    bx,[SequenceOffset]        ; Get Sequence Offset
    cmp    al,[bx-02h+offset Header]    ; Compare against SongLen
    jnz    mt_NoNewPosYet
    mov    [Byte mt_SongPos],0
    cmp    [Byte PlayStatus],1
    jnz    @@Quit
    mov    [Byte mt_SongPos],0
        ret
;---------------------------------------------------
@@Quit: mov    [Byte MStatus],1
    mov    [Byte mt_SongPos],0
        ret

mt_NoNewPosYet:
    cmp    [Byte mt_PosJumpFlag],0
    jnz    mt_NextPosition
        ret
endp    mt_dskip

proc    mt_CheckEfx
    call    mt_UpdateFunk
    mov    ax,[Word si+MS.cmd]         ; Get the special command
        xchg    al,ah
        and     ax,0FFFh
    jz    mt_PerNop
    mov    bl,[si+MS.cmd]            ; Contains the command to do
    and    bl,0Fh
    cmp    bl,0
    jz    mt_Arpeggio
    cmp    bl,1
    jz    mt_PortaUp
    cmp    bl,2
    jz    mt_PortaDown
    cmp    bl,3
    jz    mt_TonePortamento
    cmp    bl,4
    jz    mt_Vibrato
    cmp    bl,5
    jz    mt_TonePlusVolSlide
    cmp    bl,6
    jz    mt_VibratoPlusVolSlide
    cmp    bl,0Eh
    jz    mt_E_Commands
SetBack:call    mt_PerNop
    cmp    bl,7
    jz    mt_Tremolo
    cmp    bl,0Ah
    jz    mt_VolumeSlide
mt_Return:
    ret
endp    mt_CheckEfx

proc    mt_PerNop
    mov    cx,[si+MS.Period]
    jmp    mt_PerNop2
endp    mt_PerNop

proc    mt_PerNop2
    xor    dx,dx
        or      cx,cx
        jz      @@Fig1
    mov    ax,[Word MainFreq]
        mov     dx,[Word MainFreq+2]
        div     cx
        mov     dx,ax
@@Fig1: mov     TSNoteFreq,dx
        ret
endp    mt_PerNop2

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect 0 -- Arpeggio
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_Arpeggio
    xor    ax,ax
    mov    al,[mt_counter]
    mov    bl,3
        div     bl
    xchg    al,ah
        or      al,al
        jz      mt_Arpeggio2
        cmp     al,2
        jz      mt_Arpeggio1
        mov     al,[Byte si+MS.cmdlo]
        shr     al,4
        jmp     mt_Arpeggio3

mt_Arpeggio1:
        mov     al,[Byte si+MS.cmdlo]
        and     al,0Fh
        jmp     mt_Arpeggio3

mt_Arpeggio2:
    mov    cx,[si+MS.Period]
        jmp     mt_Arpeggio4

mt_Arpeggio3:
        cbw
        shl     ax,1
        mov     bx,ax
        mov     al,[si+MS.FineTune]
        mov     cl,36*2
        mul     cl
        mov     dx,[si+MS.Period]
    push    di
    mov    di,offset mt_PeriodTable
    add    di,ax
        mov     cx,36
mt_arploop:
    mov    cx,[bx+di]
    cmp    dx,[di]
        jnb     mt_arpafterloop
    add    di,2
        loop    mt_arploop
    pop    di
        ret
mt_arpafterloop:
    pop    di

mt_Arpeggio4:
        call    mt_PerNop2
        ret
endp    mt_Arpeggio

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect 1 -- Portamento Up
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_PortaUp
        xor     ax,ax
        mov     al,[si+MS.cmdlo]                ; Number to slide up
        and     al,[mt_LowMask]
        mov     [Byte mt_LowMask],0FFh
        sub     [si+MS.Period],ax
        mov     cx,[si+MS.Period]
        and     cx,0FFFh
        cmp     cx,113
        jnb     mt_PortaUSkip
        and     [si+MS.Period],0F000h
        or      [si+MS.Period],113
mt_PortaUSkip:
        mov     cx,[si+MS.Period]
        and     cx,0FFFh
        call    mt_PerNop2
        ret
endp    mt_PortaUp


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect 2 -- Portamento Down
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_PortaDown
        xor     ax,ax
        mov     al,[si+MS.cmdlo]                ; Number to slide down
        and     al,[mt_LowMask]
        mov     [Byte mt_LowMask],0FFh
        add     [si+MS.Period],ax
        mov     cx,[si+MS.Period]
        and     cx,0FFFh
        cmp     cx,856
        jb      mt_PortaDSkip
        and     [si+MS.Period],0F000h
        or      [si+MS.Period],856
mt_PortaDSkip:
        mov     cx,[si+MS.Period]
        and     cx,0FFFh
        call    mt_PerNop2
        ret
endp    mt_PortaDown

proc    mt_SetTonePorta
    mov    dx,[si+MS.Note]
    xchg    dh,dl
    and    dx,0FFFh
    xor    ax,ax
    mov    al,[si+MS.FineTune]
    mov    cl,37*2
        mul     cl
        push    di
    mov    di,offset mt_PeriodTable
        add     di,ax
        mov     bx,0
mt_StpLoop:
    cmp    dx,[bx+di]
    jnb    mt_StpFound
    add    bx,2
    cmp    bx,37*2
    jb    mt_StpLoop
    mov    bx,35*2
mt_StpFound:
    mov    dl,[si+MS.FineTune]
    and    dl,8
    jz    mt_StpGoss
    cmp    bx,0
    jz    mt_StpGoss
    sub    bx,2
mt_StpGoss:
    mov    dx,[bx+di]
        pop     di
    mov    [si+MS.WantedPeriod],dx
    mov    ax,[si+MS.Period]
    mov    [Byte si+MS.TonePortDirec],0
    cmp    dx,ax
    jz    mt_ClearTonePorta
    jnb    mt_Return
    mov    [Byte si+MS.TonePortDirec],1
        ret

mt_ClearTonePorta:
    mov    [Word si+MS.WantedPeriod],0
    ret
endp    mt_SetTonePorta


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect 3 -- Tone Portamento
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_TonePortamento
        mov     al,[si+MS.cmdlo]
        or      al,al
        jz      mt_TonePortNoChange
        mov     [si+MS.TonePortSpeed],al
        mov     [Byte si+MS.cmdlo],0
mt_TonePortNoChange:
        cmp     [Word si+MS.WantedPeriod],0
    jz    mt_Return
    xor    ax,ax
        mov     al,[si+MS.TonePortSpeed]
        cmp     [Byte si+MS.TonePortDirec],0
        jnz     mt_TonePortaUp
mt_TonePortaDown:
        add     [si+MS.Period],ax
        mov     ax,[si+MS.WantedPeriod]
        cmp     ax,[si+MS.Period]
        jg      mt_TonePortaSetPer
    mov    [si+MS.Period],ax
        mov     [Word si+MS.WantedPeriod],0
        jmp     mt_TonePortaSetPer

mt_TonePortaUp:
        sub     [si+MS.Period],ax
        mov     ax,[si+MS.WantedPeriod]
        cmp     ax,[si+MS.Period]
        jl      mt_TonePortaSetPer
        mov     [si+MS.Period],ax
        mov     [Word si+MS.WantedPeriod],0

mt_TonePortaSetPer:
    mov    cx,[si+MS.Period]
    mov    al,[si+MS.GlissFunk]
        and     al,0Fh
        jz      mt_GlissSkip
        mov     al,[si+MS.FineTune]
        mov     bl,36*2
        mul     bl
        push    di
    mov    di,offset mt_PeriodTable
    add    di,ax
        mov     bx,0
mt_GlissLoop:
    cmp    cx,[bx+di]
        jnb     mt_GlissFound
        add     bx,2
        cmp     bx,36*2
        jb      mt_GlissLoop
        mov     bx,35*2
mt_GlissFound:
        mov     cx,[bx+di]
    pop    di
mt_GlissSkip:
        call    mt_PerNop2
        ret
endp    mt_TonePortamento


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect 4 -- Vibrato
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_Vibrato
        mov     al,[si+MS.cmdlo]
        or      al,al
        jz      mt_Vibrato2
    mov    bl,[si+MS.VibratoCmd]
    and    al,0fh
        jz      mt_vibskip
    and    bl,0F0h
    or    bl,al
mt_vibskip:
        mov     al,[si+MS.cmdlo]
        and     al,0F0h
        jz      mt_vibskip2
    and    bl,0Fh
    or    bl,al
mt_vibskip2:
        mov     [si+MS.VibratoCmd],bl
mt_Vibrato2:
        mov     al,[si+MS.VibratoPos]
        shr     al,2
    and    ax,001Fh
    mov    bl,[si+MS.WaveControl]
    and    bl,03h
        jz      mt_vib_sine
    shl    al,3
    cmp    bl,1
        jz      mt_vib_rampdown
    mov    bl,255
        jmp     mt_vib_set
mt_vib_rampdown:
        cmp     [Byte si+MS.VibratoPos],0
    jnb    mt_vib_rampdown2
    mov    bl,255
    sub    bl,al
        jmp     mt_vib_set
mt_vib_rampdown2:
    mov    bl,al
        jmp     mt_vib_set
mt_vib_sine:
    xor    bx,bx
    mov    bl,al
        mov     bl,[Byte bx+offset mt_VibratoTable]
mt_vib_set:
        mov     al,[si+MS.VibratoCmd]
        and     al,0Fh
        mul     bl
    shr    ax,7
        mov     bx,ax
        mov     ax,[si+MS.Period]
        cmp     [Byte si+MS.VibratoPos],0
    jb    mt_VibratoNeg        ; BMI
        add     ax,bx
        jmp     mt_Vibrato3
mt_VibratoNeg:
        sub     ax,bx
mt_Vibrato3:
    mov    cx,ax
        call    mt_PerNop2
        mov     al,[si+MS.VibratoCmd]
    shr    ax,2
    and    ax,3Ch
        add     [si+MS.VibratoPos],al
        ret
endp    mt_Vibrato


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect 5 -- Tone and Volume Slide
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_TonePlusVolSlide
        call    mt_TonePortNoChange
        jmp     mt_VolumeSlide
endp    mt_TonePlusVolSlide

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect 6 -- Vibrato and Volume Slide
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_VibratoPlusVolSlide
        call    mt_Vibrato2
        jmp     mt_VolumeSlide
endp    mt_VibratoPlusVolSlide


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect 7 -- Tremolo
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_Tremolo
        mov     al,[Byte si+MS.cmdlo]
        or      al,al
        jz      mt_Tremolo2
        mov     bl,[si+MS.TremoloCmd]
        and     al,0Fh
        jz      mt_treskip
        and     bl,0F0h
        or      bl,al
mt_treskip:
        mov     al,[Byte si+MS.cmdlo]
        and     al,0F0h
        jz      mt_treskip2
        and     bl,0Fh
        or      bl,al
mt_treskip2:
        mov     [si+MS.TremoloCmd],bl
mt_Tremolo2:
        mov     al,[si+MS.TremoloPos]
        shr     al,2
        and     ax,001Fh
        mov     bl,[si+MS.WaveControl]
        shr     bl,4
        and     bl,03h
        jz      mt_tre_sine
        shl     al,3
        cmp     bl,1
        jz      mt_tre_rampdown
        mov     bl,255
        jmp     mt_tre_set
mt_tre_rampdown:
        cmp     [Byte si+MS.VibratoPos],0
    jnb    mt_tre_rampdown2
        mov     bl,255
        sub     bl,al
        jmp     mt_tre_set
mt_tre_rampdown2:
        mov     bl,al
        jmp     mt_tre_set
mt_tre_sine:
    xor    bx,bx
    mov    bl,al
    mov    bl,[bx+offset mt_VibratoTable]
mt_tre_set:
        mov     al,[si+MS.TremoloCmd]
        and     al,0Fh
        mul     bl
        mov     bx,ax
        shr     bx,6
        mov     al,[si+MS.Volume]
        cmp     [Byte si+MS.TremoloPos],0
    jb    mt_TremoloNeg        ; BMI  jns
        add     al,bl
        jmp     mt_Tremolo3
mt_TremoloNeg:
        sub     al,bl
mt_Tremolo3:
        jnb     mt_TremoloSkip
    xor    ax,ax
mt_TremoloSkip:
        cmp     al,40h
    jb    mt_TremoloOK        ; BLS
        mov     al,40h
mt_TremoloOK:
        mul     [Byte si+MS.MasterVolume]
        mov     TSVol1,ah
        mov     al,[si+MS.TremoloCmd]
        shr     al,2
        and     al,3Ch
        add     [si+MS.TremoloPos],al
        ret
endp    mt_Tremolo


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect 9 -- Sample Offset
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_SampleOffset
    xor    ax,ax
    mov    al,[Byte si+MS.cmdlo]
        or      al,al
        jz      mt_sononew
        mov     [si+MS.SampleOffset],al
mt_sononew:
    mov    al,[si+MS.SampleOffset]     ; Variance in Protracker code.
    shl    ax,8
        cmp     ax,TSMaxRep
    jnb    mt_sofskip
        mov     TSOff,ax
        ret
mt_sofskip:
    mov    ax,TSOff
        mov     TSMaxRep,ax
        ret
endp    mt_SampleOffset


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect A -- Volume Slide
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_VolumeSlide
        mov     al,[si+MS.cmdlo]
        shr     al,4
        cmp     al,0
        jz      mt_VolSlideDown
mt_VolSlideUp:
        add     [Byte si+MS.Volume],al
        cmp     [Byte si+MS.Volume],40h
        jb      mt_vsuskip
        mov     [Byte si+MS.Volume],40h
mt_vsuskip:
        mov     al,[Byte si+MS.Volume]
        mul     [Byte si+MS.MasterVolume]
        mov     TSVol1,ah
        ret

mt_VolSlideDown:
        mov     al,[si+MS.cmdlo]
        and     al,0Fh
mt_VolSlideDown2:
        sub     [Byte si+MS.Volume],al
        jnb     mt_vsdskip
        mov     [Byte si+MS.Volume],0
mt_vsdskip:
        mov     al,[Byte si+MS.Volume]
        mul     [Byte si+MS.MasterVolume]
        mov     TSVol1,ah
        ret
endp    mt_VolumeSlide


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect B -- Position Jump
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_PositionJump
        mov     al,[Byte si+MS.cmdlo]         ; Get where to jump
        dec     al                            ; Update the
    mov    [mt_SongPos],al           ; information.
mt_pj2: mov    [Byte mt_PBreakPos],0
        mov     [Byte mt_PosJumpFlag],1
        ret
endp    mt_PositionJump

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect C -- Volume Change
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_VolumeChange
        mov     al,[Byte si+MS.cmdlo]   ; Get value for volume
        cmp     al,40h                  ; Is it greater than 40h?
        jb      mt_VolumeOK             ; Nope
        mov     al,40h
mt_VolumeOK:
        mov     [si+MS.Volume],al       ; Get it again
        mul     [Byte si+MS.MasterVolume]
        mov     TSVol1,ah

    ret
endp    mt_VolumeChange

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect D -- Pattern Break
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_PatternBreak
        mov     al,[Byte si+MS.cmdlo]             ; Break to where?
        mov     bl,al
        shr     al,4
        mov     cl,10
        mul     cl
        and     bl,0Fh
        add     al,bl
        cmp     al,63
        jg      mt_pj2
        mov     [mt_PBreakPos],al
        mov     [Byte mt_PosJumpFlag],1
        ret
endp    mt_PatternBreak


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect F -- Set Speed
;   Doesn't handle Protracker extended speeds.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
proc    mt_SetSpeed
        mov     al,[Byte si+MS.cmdlo]             ; Get value for speed
        or      al,al
        jz      @@SSpe1
    cmp    al,32
    jnb    @@SSpe1
    mov    [Byte mt_counter],0
    mov    [Byte mt_speed],al
@@SSPe1:ret
endp    mt_SetSpeed


proc    mt_CheckMoreEfx
        call    mt_UpdateFunk
        mov     bl,[si+MS.cmd]
        and     bl,0Fh
    cmp    bl,09h
    jz    mt_SampleOffset
    cmp    bl,0Bh
    jz    mt_PositionJump
    cmp    bl,0Dh
    jz    mt_PatternBreak
    cmp    bl,0Eh
    jz    mt_E_Commands
    cmp    bl,0Fh
    jz    mt_SetSpeed
    cmp    bl,0Ch
        jz      mt_VolumeChange
    jmp    mt_PerNop
endp    mt_CheckMoreEfx

proc    mt_E_Commands
        mov     bl,[Byte si+MS.cmdlo]
        and     bl,0F0h
        shr     bl,4
    cmp    bl,0
    jz    mt_FilterOnOff
    cmp    bl,1
    jz    mt_FinePortaUp
    cmp    bl,2
    jz    mt_FinePortaDown
    cmp    bl,3
    jz    mt_SetGlissControl
    cmp    bl,4
    jz    mt_SetVibratoControl
    cmp    bl,5
    jz    mt_SetFineTune
    cmp    bl,6
    jz    mt_JumpLoop
    cmp    bl,7
    jz    mt_SetTremoloControl
    cmp    bl,9
    jz    mt_RetrigNote
    cmp    bl,0Ah
    jz    mt_VolumeFineUp
    cmp    bl,0Bh
    jz    mt_VolumeFineDown
    cmp    bl,0Ch
    jz    mt_NoteCut
    cmp    bl,0Dh
    jz    mt_NoteDelay
    cmp    bl,0Eh
    jz    mt_PatternDelay
    cmp    bl,0Fh
    jz    mt_FunkIt
    ret
endp    mt_E_Commands

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect E
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Effect 0 -- FilterOnOff
proc    mt_FilterOnOff
    mov    al,[Byte si+MS.cmdlo]
    and    al,1
    sal    al,1
    ; Amiga
    ; Stuff
    ret
endp    mt_FilterOnOff

; Effect 1 -- Fine Porta Up
proc    mt_FinePortaUp
        cmp     [Byte mt_counter],0
        jnz     mt_Return
        mov     [Byte mt_LowMask],0Fh
        jmp     mt_PortaUp
endp    mt_FinePortaUp

; Effect 2 -- Fine Porta Down
proc    mt_FinePortaDown
        cmp     [Byte mt_counter],0
        jnz     mt_Return
        mov     [Byte mt_LowMask],0Fh
        jmp     mt_PortaDown
endp    mt_FinePortaDown

; Effect 3 -- Set Gliss Control
proc    mt_SetGlissControl
        mov     al,[Byte si+MS.cmdlo]
        and     al,0Fh
        and     [Byte si+MS.GlissFunk],0F0h
        or      [si+MS.GlissFunk],al
        ret
endp    mt_SetGlissControl

; Effect 4 -- Set Vibrato Control
proc    mt_SetVibratoControl
        mov     al,[si+MS.cmdlo]
        and     al,0Fh
        and     [Byte si+MS.WaveControl],0F0h
        or      [si+MS.WaveControl],al
        ret
endp    mt_SetVibratoControl

; Effect 5 -- Set Fine Tune
proc    mt_SetFineTune
        mov     al,[si+MS.cmdlo]
        and     al,0Fh
        mov     [si+MS.FineTune],al
        ret
endp    mt_SetFineTune

; Effect 6 -- Jump Loop
proc    mt_JumpLoop
        cmp     [Byte mt_counter],0
    jnz    mt_Return
    mov    al,[si+MS.cmdlo]
        and     al,0Fh
        jz      mt_SetLoop
        cmp     [Byte si+MS.loopcount],0
        jz      mt_jumpcnt
        dec     [Byte si+MS.loopcount]
    jz    mt_Return
mt_jmploop:
        mov     al,[si+MS.pattpos]
        mov     [mt_PBreakPos],al
        mov     [Byte mt_PBreakFlag],1
        ret

mt_jumpcnt:
        mov     [si+MS.loopcount],al
    jmp    mt_jmploop

mt_SetLoop:
    mov    ax,[mt_PatternPos]
        shr     ax,4
        mov     [si+MS.pattpos],al
        ret
endp    mt_JumpLoop

; Effect 7 -- Set Tremolo Control
proc    mt_SetTremoloControl
        mov     al,[Byte si+MS.cmdlo]
        and     al,0Fh
        shl     al,4
        and     [Byte si+MS.WaveControl],0Fh
        or      [si+MS.WaveControl],al
        ret
endp    mt_SetTremoloControl

; Effect 9 -- Retrig Note
proc    mt_RetrigNote
        mov     bl,[Byte si+MS.cmdlo]
        and     bl,0Fh
    jz    mt_rtnend
    xor    ax,ax
        mov     al,[mt_counter]
        or      al,al
        jnz     mt_rtnskp
        mov     cx,[si+MS.Note]
        xchg    ch,cl
        and     cx,0FFFh
    jnz    mt_rtnskp
        mov     [Byte mt_counter],0
mt_rtnskp:
        div     bl
        xchg    ah,al
        or      al,al
    jnz    mt_rtnend
mt_DoRetrig:
        xor     ax,ax
        mov     TSOff,ax
    mov    ax,[si+MS.Length]
    shl    ax,1
    mov    TSMaxRep,ax
    mov    ax,[si+MS.LoopStart]
    mov    TSRepeat,ax
    mov    cx,[si+MS.RepLen]
    add    ax,cx            ; Add on the offset.
    add    ax,cx            ; Add it again.
    sub    ax,3
        mov     TSRepeatLen,ax          ; Store it.
mt_rtnend:
    ret
endp    mt_RetrigNote

; Effect A -- Volume Fine Up
proc    mt_VolumeFineUp
        cmp     [Byte mt_counter],0
    jnz    mt_Return
    mov    al,[si+MS.cmdlo]
        and     al,0Fh
        jmp     mt_VolSlideUp
endp    mt_VolumeFineUp

; Effect B -- Volume Fine Down
proc    mt_VolumeFineDown
        cmp     [Byte mt_counter],0
    jnz    mt_Return
    mov    al,[si+MS.cmdlo]
        and     al,0Fh
        jmp     mt_VolSlideDown2
endp    mt_VolumeFineDown

; Effect C -- Note Cut
proc    mt_NoteCut
        mov     al,[Byte si+MS.cmdlo]
        and     al,0Fh
    cmp    al,[mt_counter]
    jnz    mt_Return
    mov    [Byte si+MS.Volume],0
    mul    [Byte si+MS.MasterVolume]
        mov     TSVol1,ah
        ret
endp    mt_NoteCut

; Effect D -- Note Delay
proc    mt_NoteDelay
        mov     al,[Byte si+MS.cmdlo]
        and     al,0Fh
    cmp    al,[mt_counter]
    jnz    mt_Return
    mov    ax,[si]
    or    ax,ax
    jz    mt_Return
    jmp    mt_DoRetrig
endp    mt_NoteDelay

; Effect E -- Pattern Delay
proc    mt_PatternDelay
        cmp     [Byte mt_counter],0
    jnz    mt_Return
    mov    al,[Byte si+MS.cmdlo]
        and     al,0Fh
        cmp     [Byte mt_PattDelayTime2],0
    jnz    mt_Return
    inc    al
        mov     [mt_PattDelayTime],al
        ret
endp    mt_PatternDelay

; Effect F -- Funk It
proc    mt_FunkIt
    cmp    [Byte mt_counter],0
    jnz    mt_Return
    mov    al,[Byte si+MS.cmdlo]
        and     al,0Fh
        shl     al,4
        and     [Byte si+MS.GlissFunk],0Fh
        or      [si+MS.GlissFunk],al
        or      al,al
    jz    mt_Return
    jmp    mt_UpdateFunk
endp    mt_FunkIt

proc    mt_UpdateFunk
    xor    bx,bx
    mov    bl,[si+MS.GlissFunk]
    shr    bl,4
    or    bl,bl
    jz    mt_funkend
        mov     al,[bx+offset mt_FunkTable]
        add     [si+MS.FunkOffset],al
    mov    al,[si+MS.FunkOffset]
    and    al,10000000b
    jz    mt_funkend
    mov    [Byte si+MS.FunkOffset],0
    ; This is my best try at converting this code.
;     mov     ax,[si+MS.LoopStart]
;     mov     bx,[si+MS.RepLen]
;     add     ax,bx
;     add     ax,bx
;     mov     cx,[si+MS.WaveStart]
;     inc     cx
;     cmp     cx,ax
;     jb     mt_funkok
;     mov     cx,[si+MS.LoopStart]
;mt_funkok:
;     mov     [si+MS.WaveStart],cx
;     mov     ax,-1
;     mov     bx,cx
;     sub     [bx],ax
;     mov     ax,[bx]
mt_funkend:
    ret
endp    mt_UpdateFunk

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_PlayMusic                                                 ³
;³                                                                           ³
;³ ENTRY      : None                                 ³
;³                                                                           ³
;³ RETURN     : Carry Set - Error                                            ³
;³              Carry Clear - Everything OK, music should be playing         ³
;³                                                                           ³
;³ DESCRIPTION: This procedure sets up all pointers, interrupts, and the     ³
;³              likes for the current module in memory.  Error checking is   ³
;³              done to make sure a module is loaded, the music is already   ³
;³              playing, or whatever else may conflict.                      ³
;³                                         ³
;³        *** Written by Joshua C. Jensen                  ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc  sd_PlayMusic
    uses ds,es
    
    push es
    mov  ax, @code
    mov  es, ax
    mov  ax, @data      ; Make sure the data segment is set
    mov  es:IntDS, ax   ; Save Data Seg Int in Int1Ch program code seg
    mov  ds, ax         ; to the main data segment in which
                        ; all of our variables are stationed.
                        ; See if the Music Player has been initialized yet.
    pop  es
    
    cmp  [Byte MusicPlayerInstalled],1
    je   @@MusicIsInstalled    ; It has, so continue.

@@Abort:
    stc
    ret

@@MusicIsInstalled:
    cmp  [Byte ModuleLoaded],1   ; Do we have a module in memory?
    jnz  @@Abort                 ; Nope, abort out of here.

    call sd_ShutDownMusicInt     ; Before doing anything else, shut
                                        ; down any music that is playing.
    call sd_ReturnInfo           ; Get address information
    mov  dx,offset sd_MusicInterrupt
    mov  [PlayerInterrupt],dx    ; Store the interrupt for later.

        ; ÄÄÄÄ This is where all of the extra info for the SoundBlaster,
    ; ÄÄÄÄ SoundBlaster Pro, Adlib Gold, etc., is set up.  AL on return
        ; ÄÄÄÄ from sd_ReturnInfo will contain a number from the structure
        ; ÄÄÄÄ so we know which card is installed and can set up
        ; ÄÄÄÄ appropriately.
    call    sd_SetMainAddr
@@SetupForMusic:
        mov     [Byte TypeOfInt],1      ; Specify that the interrupt to be
                    ; set up is the music interrupt.
        call    sd_SetupForMusic
    clc                ; Clear the carry.
        ret                             ; Exit.
endp    sd_PlayMusic

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_PlayIns                                                   ³
;³                                                                           ³
;³ ENTRY      : AX - Period                                                  ³
;³              BX - RepLen                                                  ³
;³              CX - MaxRep                                                  ³
;³              DX - Repeat                                                  ³
;³              SI - Volume                                                  ³
;³              ES - Sample Segment                                          ³
;³                                                                           ³
;³ RETURN     : Carry Set - Error                                            ³
;³              Carry Clear - Everything OK, music should be playing         ³
;³                                                                           ³
;³ DESCRIPTION: This procedure sets up all pointers, interrupts, and the     ³
;³              likes for the instrument specified.                          ³
;³                                         ³
;³        *** Written by Joshua C. Jensen                  ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc  sd_PlayIns
    uses    ds
        push    ax
        mov     ax,@data
        mov     ds,ax
        pop     ax
        cmp     [Byte MusicPlayerInstalled],1
        jnz     @@End
        call    sd_ShutDownMusicInt
        or      si,si
        jz      @@End
        dec     si
        shl     si,2                    ; Give the effect of all four voices
                                        ; playing at once.
        shl     bx,1
        shl     cx,1
        shl     dx,1
        mov     [Channel1RepLen],bx
        mov     [Channel1MaxRep],cx
        mov     [Channel1Repeat],dx
        mov     bx,si
    mov    [Channel1Vol1],bl
        mov     [Channel1Seg],es
        mov     [Word Channel1Ofs],0
    push    ax
    call    sd_SetFreq
        pop     bx
        or      bx,bx
        jz      @@BlankPeriod
        div     bx
        mov     bx,ax
@@BlankPeriod:
        mov     [Channel1Freq],bx
        call    sd_ReturnInfo
    mov    dx,offset sd_InsInterrupt
    mov    [PlayerInterrupt],dx
    call    sd_SetMainAddr
@@SetupForIns:
        mov     [Byte TypeOfInt],2      ; Specify that the interrupt to be
                                        ; set up is the sample interrupt.
        call    sd_SetupForMusic
@@End:
        ret
endp    sd_PlayIns

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_SetupForMusic                         ³
;³                                                                           ³
;³ ENTRY      : None                                 ³
;³                                                                           ³
;³ RETURN     : None                                 ³
;³                                                                           ³
;³ DESCRIPTION: This procedure redefines internal interrupt variables to     ³
;³        run at the new sample rate and sets of the interrupt.         ³
;³                                         ³
;³        *** Written by Joshua C. Jensen.                 ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc    sd_SetupForMusic
        mov     [Byte IntSet],1         ; Specify that the interrupt is setup.

    push    es
    mov    ax,351Ch        ; Get information for interrupt 1Ch,
                                        ; the timer interrupt, which is the
                                        ; main interrupt that we wedge into.
        int     21h                     ; Call DOS's Get Interrupt Vector.
        mov     [Word Int1Ch],bx         ; Store the returned interrupt so we
        mov     [Word Int1Ch+2],es       ; can restore it when done.
        pop    es

        in      al,21h                  ; Direct input from the interrupt
                                        ; mask register.
        mov     [IntMask],al            ; Store the interrupt mask so we can
                                        ; restore it later.

        cli                             ; Clear the interrupt flag so the
                                        ; system recognizes no maskable
                                        ; interrupts.
        mov     al,0FFh                 ; Disable every maskable interrupt
        out    21h,al            ; while setting up the new one.
        sti                             ; Set the interrupt flag so the
                                        ; system recognizes maskable
                                        ; interrupts.

        push    ds                      ; Since we change the data segment,
                                        ; save it.
        mov     dx,[PlayerInterrupt]    ; Get the Player Interrupt.
        push    cs                      ; Push the code segment into the
        pop     ds                      ; data segment.
        mov     ax,251Ch                ; Set information for interrupt 1Ch.
        int     21h                     ; Call DOS's Set Interrupt Vector.
        pop     ds                      ; Retrieve DS.

        mov     al,00110100b            ; Channel 0, Read/write LSB followed
        out     43h,al                  ; by MSB, Operation mode 2, binary
        mov     al,[Byte LSBCounter]
        out     40h,al
    mov    al,[Byte LSBCounter+1]    ; Send counter MSB
    out    40h,al

    mov    al,10010000b        ; Channel 2, Read/write only MSB,
        out     43h,al                  ; Operation mode 0, Binary
        in      al,61h                  ; Turn speaker on, speaker control
    or    al,00000011b        ; through 8253 timer
        out     61h,al

    cli                ; Enable old interrupts
        mov     al,[IntMask]
        out     21h,al
        sti

        mov     [Byte MStatus],0        ; Set the music status to playing.
    ret
endp    sd_SetupForMusic

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_CloseAllMusic                         ³
;³                                                                           ³
;³ ENTRY      : None                                 ³
;³                                                                           ³
;³ RETURN     : Carry Set - Fatal Error...abort program.             ³
;³        Carry Clear - Everything OK.                     ³
;³                                                                           ³
;³ DESCRIPTION: Frees up any and all pointers set up when the module was     ³
;³        loaded.  Quick and easy way to kill EVERYTHING!          ³
;³                                         ³
;³        *** Written by Joshua C. Jensen.                 ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc    sd_CloseAllMusic
    uses ds
;    mov  ax, @data
;    mov  ds, ax
    
    mov  ax,351Ch         ;Lire contenu vecteur d'interruption 1Ch
    int  21h                                 ;Appeler fonction DOS
    mov  ax, word ptr es:[bx+4]   ;Initialize ds by moving segment
    mov  ds, ax     ; Get Data Seg from original program in memory
    
    cmp  [Byte IntSet],1     ; Do we have the music playing?
    jnz    @@FreeInstruments
    call  sd_ShutDownMusicInt    ; Yes, shut it down.

@@FreeInstruments:
    mov    si,offset InsLoc
    mov    cx,31            ; 31 Instruments to choose from.
@@FreeInsLoop:
    lodsw                ; Pick up a segment.
    or    ax,ax            ; If there is a zero there, then there
    jz    @@BotFreeInsLoop    ; is nothing to free.
    mov    es,ax            ; Otherwise, free it.
    mov    ax,4900h        ; Deallocate the memory.
    int    21h
    jnb    @@BotFreeInsLoop    ; No problem with allocation.
    mov     [Byte Fatal],1
    stc                ; There was a fatal error.
    ret
@@BotFreeInsLoop:
    loop    @@FreeInsLoop

@@FreePatterns:
    mov    si,offset PatternLoc
    mov    cx,64            ; 64 different patterns
@@FreePatLoop:
    lodsw                ; Pick up a segment.
    or    ax,ax            ; If there is a zero there, then there
    jz    @@BotFreePatLoop    ; is nothing to free.
    mov    es,ax            ; Otherwise, free it.
    mov    ax,4900h        ; Deallocate the memory.
    int    21h
    jnb    @@BotFreePatLoop    ; No problem with allocation.
    mov     [Byte Fatal],1
    stc                ; There was a fatal error.
    ret
@@BotFreePatLoop:
    loop    @@FreePatLoop
    ret
endp    sd_CloseAllMusic

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_ShutDownMusicInt                         ³
;³                                                                           ³
;³ ENTRY      : None                                 ³
;³                                                                           ³
;³ RETURN     : None                                 ³
;³                                                                           ³
;³ DESCRIPTION: Stops the music from playing.  Might be called a "Pause".    ³
;³        A call to sd_PlayMusic, sd_PlayIns, or sd_SetupForMusic      ³
;³        will start it playing again, right where it left off.         ³
;³                                         ³
;³        *** Written by Joshua C. Jensen.                 ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc    sd_ShutDownMusicInt
    uses ds,es,dx,ax
;    mov  ax,@data
;    mov  ds,ax

    mov  ax,351Ch         ;Lire contenu vecteur d'interruption 1Ch
    int  21h                                 ;Appeler fonction DOS
    mov  ax, word ptr es:[bx+4]   ;Initialize ds by moving segment
    mov  ds, ax     ; Get Data Seg from original program in memory

    cmp  [Byte MusicPlayerInstalled],1
    jnz  @@End
    cmp  [Byte IntSet],1     ; Is the interrupt set.
    jnz  @@End
    mov  [Byte IntSet],0
    cli
    mov     al,0FFh
    out     21h,al
    sti
    in     al,61h
    and  al,0FCh
    out  61h,al
    mov  al,00110100b        ; Channel 0, Read/write LSB followed
    out  43h,al            ; by MSB, Operation mode 2, binary
    xor     ax,ax
    out     40h,al
    out     40h,al
    mov     al,10110110b        ; Channel 2, Read/write LSB followed
    out  43h,al            ; by MSB, Operation mode 3, binary
    mov  ax,0533h
    out  42h,al
    mov  al,ah
    out  42h,al

    push ds
  
    mov  dx, [Word Int1Ch]
    mov  ds, [Word Int1Ch+2]
    mov  ax,251Ch       ;Replacer contenu vecteur d'interruption 1Ch
    int  21h            ;sur ancienne routine
    
    pop     ds

    cli
    mov     al, [Byte IntMask]
    out     21h, al        ;DIRECT_OUTPUT
    sti
;    sti
@@End:
    mov     [Byte MStatus],1
    ret
endp    sd_ShutDownMusicInt

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_SetFreq                             ³
;³                                                                           ³
;³ ENTRY      : None                                 ³
;³                                                                           ³
;³ RETURN     : None                                 ³
;³                                                                           ³
;³ DESCRIPTION: Sets standard frequency and LSBCounter information.         ³
;³                                         ³
;³        *** Written by Joshua C. Jensen.                 ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc    sd_SetFreq
    uses    ds
    mov    ax,@data
    mov    ds,ax
    xor    dx,dx            ; Clear out DX.
        mov     ax,[SampleRate]         ; Load the sampling rate into AX.
        mov     bx,50                   ; Module timing on the Amiga is
        div     bx                      ; determined by the refresh rate of
                                        ; the screen.
        mov     [IntMaster],ax          ; Set all of these values the same.
        mov     [IntCountDown],ax       ; section below.

        mov     [Word FreqMult],300h    ; Set up standard information.
        mov     dx,0012h                ; Combined DX:AX = 1,193,180 which is
        mov     ax,34DCh                ; the 8253's chip operating frequency.
        div     [Word SampleRate]       ; Divide it by the sampling rate to
                                        ; determine the LSB of the new
                                        ; interrupt counter.
        mov     [LSBCounter],ax         ; Store it for when we set up the
                                        ; interrupt.
        mov     bx,[FreqMult]           ; Now, multiply by FreqMult to get the
        mul     [Word FreqMult]         ; value to divide the period by to get
        mov     [Word MainFreq],ax      ; a "frequency" to skip through the
        mov     [Word MainFreq+2],dx    ; sample with.  Essentially, the 8253's
                                        ; new "operating frequency".
    ret
endp    sd_SetFreq

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ ***********************  Playback Interrupts  ****************************  ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ The below code was written by Joshua C. Jensen.  These routines are a     ³
;³ copy of the instrument playback routines with three extra voices.         ³
macro   sd_MonoLess64
    xor    cx,cx
    xor    dx,dx

@@Channel1:
    cmp    [Word Channel1Seg],0    ;;<--Is the channel even on?
    jz    @@Channel2        ;;<--If not jump to channel 2
        mov     es,[Channel1Seg]

    mov    bx,[Channel1Ofs]
    cmp    bx,[Channel1MaxRep]
    jb    @@Channel1_1

    cmp    [Word Channel1RepLen],0
    jz    @@Channel2

        mov     bx,[Channel1Repeat]
    mov    ax,[Channel1RepLen]
        mov     [Channel1MaxRep],ax
@@Channel1_1:
    mov    ax,[Channel1Freq]
    add    [Byte Channel1OFlow],al
    mov    cl,ah
        adc     bx,cx
        mov     [Channel1Ofs],bx
        mov     al,[es:bx]
    imul    [Byte Channel1Vol1]
    add    dl,ah

@@Channel2:
    cmp    [Word Channel2Seg],0
    jz    @@Channel3
    mov    es,[Channel2Seg]

    mov    bx,[Channel2Ofs]
    cmp    bx,[Channel2MaxRep]
    jb    @@Channel2_1

    cmp    [Word Channel2RepLen],0
    jz    @@Channel3

    mov    bx,[Channel2Repeat]
    mov    ax,[Channel2RepLen]
    mov    [Channel2MaxRep],ax
@@Channel2_1:
    mov    ax,[Channel2Freq]
    add    [Byte Channel2OFlow],al
    mov    cl,ah
        adc     bx,cx
    mov    [Channel2Ofs],bx
        mov     al,[es:bx]
    imul    [Byte Channel2Vol1]
    add    dh,ah

@@Channel3:
    cmp    [Word Channel3Seg],0    ;;<--Is the channel even on?
    jz    @@Channel4        ;;<--If not jump to channel 2
    mov    es,[Channel3Seg]

    mov    bx,[Channel3Ofs]
    cmp    bx,[Channel3MaxRep]
    jb    @@Channel3_1

    cmp    [Word Channel3RepLen],0
    jz    @@Channel4

    mov    bx,[Channel3Repeat]
    mov    ax,[Channel3RepLen]
    mov    [Channel3MaxRep],ax
@@Channel3_1:
    mov    ax,[Channel3Freq]
    add    [Byte Channel3OFlow],al
        mov     cl,ah
        adc     bx,cx
    mov    [Channel3Ofs],bx
        mov     al,[es:bx]
    imul    [Byte Channel3Vol1]
    add    dh,ah

@@Channel4:
    cmp    [Word Channel4Seg],0    ;;<--Is the channel even on?
    jz    @@ChannelDone        ;;<--If not jump to channel 2
    mov    es,[Channel4Seg]

    mov    bx,[Channel4Ofs]
    cmp    bx,[Channel4MaxRep]
    jb    @@Channel4_1

    cmp    [Word Channel4RepLen],0
    jz    @@ChannelDone

    mov    bx,[Channel4Repeat]
    mov    ax,[Channel4RepLen]
    mov    [Channel4MaxRep],ax
@@Channel4_1:
    mov    ax,[Channel4Freq]
    add    [Byte Channel4OFlow],al
        mov     cl,ah
        adc     bx,cx
    mov    [Channel4Ofs],bx
        mov     al,[es:bx]
    imul    [Byte Channel4Vol1]
        add     dl,ah
@@ChannelDone:
endm    sd_MonoLess64
;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;-;
proc    sd_MusicInterrupt near
    jmp  newint
    db   "SP"                   ;Identification du programme PPS (SP inverted)
IntDS dw (?)
newint:
    push ds ax es di si bx cx dx bp
    mov    ax, @data
    mov    ds, ax
    cmp    [Byte SoundSource],1
    jnz    @@GetValueToOutput
    mov    dx,[MainAddr]
@@0:    in    al,dx
    rol    al,1
    jb    @@0
    mov    al,10h
        out     dx,al
@@GetValueToOutput:
    sd_MonoLess64
    mov    bx,dx
        mov     dx,[MainAddr]
        cmp     [Byte SoundSource],0
    jz    DoRestOfSpeakerStuff
        cmp     [Byte SoundSource],1
    jz    @@FinishTheSB
    cmp    [Byte SoundSource],2
    jz    @@FinishTheDAC
DoRestOfSpeakerStuff:
    add    bl,bh
    mov    ax,bx
    xor    al,10000000b    ;<-remove the sign
        mov     bx,offset TranslationTable
    xlat
    shl    al,2
    out    dx,al
    jmp    FinishTheInterrupt
@@FinishTheSB:
    in    al,dx                ; tell us to send.
    rol    al,1
    jb    @@FinishTheSB
    mov    ax,bx
    add    al,ah
    xor    al,10000000b    ;<-remove the sign
        out     dx,al
        jmp     FinishTheInterrupt
@@FinishTheDAC:
    mov    ax,bx
    add    al,ah
    xor    al,10000000b    ;<-remove the sign
    out    dx,al
;    jmp     FinishTheInterrupt
FinishTheInterrupt:
    dec    [Word IntCountDown]
    jz    HandleUpdateModule
FinishTheInterrupt2:
    pop    bp dx cx bx si di es
    mov    al,20h
        out     20h,al
    pop    ax ds
     mov    ax,@data
    mov    ds,ax
    sti
    jmp [Int1Ch]
;    iret
HandleUpdateModule:
    mov    ax,[IntMaster]
    mov    [IntCountDown],ax
    inc    [Word TimeValue]
    call  sd_UpdateChannels
    pop    bp dx cx bx si di es
    mov    al,20h
    out     20h,al
    pop    ax ds
    mov    ax,@data
    mov    ds,ax
    sti
    jmp [Int1Ch]
;    iret
endp    sd_MusicInterrupt

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ ******************  Instrument Playback Interrupts  **********************  ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³ The below code was written by Joshua C. Jensen.  Help was obtained from   ³
;³ several professional programmers, the most helpful being Dave Ashcroft.   ³
;³ The help was in building the initial interrupt routines around two years  ³
;³ ago.  They have since been rewritten for speed many times over by myself. ³
macro   sd_MonoLessIns
        xor     cx,cx
        xor     dx,dx

@@Channel1:
        cmp     [Word Channel1Seg],0    ;;<--Is the channel even on?
        jz      @@ChannelDone           ;;<--If not jump to channel 2
        mov     es,[Channel1Seg]

        mov     bx,[Channel1Ofs]
        cmp     bx,[Channel1MaxRep]
        jb      @@Channel1_1

        cmp     [Channel1RepLen],0
        jz      @@ChannelTurnInsOff

        mov     bx,[Channel1Repeat]
        mov     ax,[Channel1RepLen]
        mov     [Channel1MaxRep],ax
@@Channel1_1:
        mov     ax,[Channel1Freq]
        add     [Byte Channel1OFlow],al
        xchg    ah,cl
        adc     bx,cx
        mov     [Channel1Ofs],bx
        mov     al,[es:bx]
        xor     al,10000000b    ;<-remove the sign
    mul    [Byte Channel1Vol1]
@@ChannelDone:
        mov     al,ah
        jmp     @@DoneWithIt
@@ChannelTurnInsOff:
        mov     [Byte MStatus],1
@@DoneWithIt:
endm    sd_MonoLessIns

proc    sd_InsInterrupt near
    push    ds ax es di si bx cx dx bp
    mov     ax,@data
    mov     ds,ax
    cmp     [Byte SoundSource],1
    jnz    @@GetValueToOutput
    mov    dx,[MainAddr]
@@0:    in    al,dx
    rol    al,1
    jb    @@0
    mov    al,10h
        out     dx,al
@@GetValueToOutput:
    sd_MonoLessIns
    cmp    [Byte MStatus],1
    jz    FinishTheInterrupt
        cmp     [Byte SoundSource],0
    jz    @@DoRestOfSpeakerStuff
    mov    dx,[MainAddr]
    mov    bx,ax
    cmp    [Byte SoundSource],1
    jz    @@FinishTheSB
    cmp    [Byte SoundSource],2
    jz    @@FinishTheDAC
@@DoRestOfSpeakerStuff:
    xor    al,10000000b    ;<-remove the sign
        mov     bx,offset TranslationTable
    xlat
    shl    al,2
        out     42h,al
    jmp    FinishTheInterrupt2
@@FinishTheSB:
    in    al,dx                ; tell us to send.
    rol    al,1
    jb    @@FinishTheSB
    mov    ax,bx
    out    dx,al
    jmp    FinishTheInterrupt2
@@FinishTheDAC:
    out    dx,al
    jmp    FinishTheInterrupt2
endp    sd_InsInterrupt

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_SetMainAddr                             ³
;³                                                                           ³
;³ ENTRY      : None                                                         ³
;³                                                                           ³
;³ RETURN     : None                                 ³
;³                                         ³
;³ DESCRIPTION: Gets the output address for the current device and sets it.  ³
;³                                         ³
;³              *** Written by Joshua C. Jensen                              ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc    sd_SetMainAddr
    mov    ax,[bx+SoundSrcStruc.AddressLeft]
    mov    [MainAddr],ax
    ret
endp    sd_SetMainAddr

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_ReturnInfo                             ³
;³                                                                           ³
;³ ENTRY      : None                                                         ³
;³                                                                           ³
;³ RETURN     : AL - Type of device.                         ³
;³                                         ³
;³ DESCRIPTION: Returns various pieces of information about the current      ³
;³        playing device.                          ³
;³                                         ³
;³        *** Written by Joshua C. Jensen.                 ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc    sd_ReturnInfo
    uses    ds
    mov    ax,@data
    mov    ds,ax
    xor    ax,ax                ; Figure out addresses, etc.
    mov    al,[SoundSource]
    mov    dx,size SoundSrcStruc
    mul    dx
    add    ax,offset SoundSources
    mov    bx,ax
    mov    al,[bx+SoundSrcStruc.Special]
    ret
endp    sd_ReturnInfo

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_InitSound                             ³
;³                                                                           ³
;³ ENTRY      : BX - Force value - 255 = No force, 0-254 = automatically     ³
;³             use this sound source regardless of what was found.     ³
;³                                                                           ³
;³ RETURN     : None                                 ³
;³                                         ³
;³ DESCRIPTION: Initializes the module player.    This MUST be called before   ³
;³        anything else!    Scans for Soundblaster, DACs, etc.         ³
;³                                         ³
;³              *** Written by Joshua C. Jensen                              ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc  sd_InitSound
    uses    ds
    mov    ax,@data
    mov    ds,ax
    push    bx
    call    sd_SetMaxVolume
    mov    [Word MaxVolume],255
    mov    [Byte PlayStatus],0
    mov    [Word SampleRate],15909     ; Standard sampling rate.
    mov     [Byte SoundSource],0            ; Start with speaker.
    mov    [Byte MusicPlayerInstalled],1
    call    sd_DetectDACs
;    call    sd_DetectSB
    pop    bx
    cmp    bx,255
    jz    @@Done
    mov    [Byte SoundSource],bl
@@Done:
        ret
endp  sd_InitSound

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_Set15Ins and sd_Set31Ins                     ³
;³                                                                           ³
;³ ENTRY      : None                                                         ³
;³                                                                           ³
;³ RETURN     : None                                 ³
;³                                         ³
;³ DESCRIPTION: Sets up pointers to positions in the header based on the     ³
;³        number of instruments.                         ³
;³                                         ³
;³              *** Written by Joshua C. Jensen                              ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc    sd_Set15Ins
    uses    ds
    mov    ax,@data
    mov    ds,ax
    mov    [Word NumberInstruments],15
    mov    [Word SequenceOffset],01D8h
    mov    [Word HeaderSize],0258h
    ret
endp    sd_Set15Ins

proc    sd_Set31Ins
    uses    ds
    mov    ax,@data
        mov     ds,ax
        mov     [Word NumberInstruments],31
    mov    [Word SequenceOffset],03B8h
    mov    [Word HeaderSize],043Ch
    ret
endp    sd_Set31Ins

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_SetMaxVolume                          ³
;³                                                                           ³
;³ ENTRY      : None                                                         ³
;³                                                                           ³
;³ RETURN     : None                                 ³
;³                                         ³
;³ DESCRIPTION: Sets the four channels to the Maximum volume.             ³
;³                                         ³
;³              *** Written by Joshua C. Jensen                              ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc    sd_SetMaxVolume
    uses    ds
    mov    ax,@data
    mov    ds,ax
    mov    al,[Byte MaxVolume]
    mov    [offset Channel1+(offset (MS).MasterVolume)],al
    mov    [offset Channel2+(offset (MS).MasterVolume)],al
    mov    [offset Channel3+(offset (MS).MasterVolume)],al
    mov    [offset Channel4+(offset (MS).MasterVolume)],al
    ret
endp    sd_SetMaxVolume

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_DetectSB                             ³
;³                                                                           ³
;³ ENTRY      : None                                                         ³
;³                                                                           ³
;³ RETURN     : None                                                         ³
;³                                                                           ³
;³ DESCRIPTION: Soundblaster specific code.  Finds Soundblaster port         ³
;³        address is available.  This code will be based on a lot of   ³
;³        technical junk that came out of the SBK around section 8-4.  ³
;³        Haven't had time to rewrite it!                              ³
;³                                                                           ³
;³        *** Written by Joshua C. Jensen                  ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
;proc    sd_DetectSB
;    ret
;endp    sd_DetectSB

;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ NAME       : sd_DetectDACs                             ³
;³                                                                           ³
;³ ENTRY      : None                                                         ³
;³                                                                           ³
;³ RETURN     : SoundSource set to first DAC found in SoundSources list.     ³
;³                                                                           ³
;³ DESCRIPTION: DAC specific code.  Finds the port addresses of all          ³
;³        installed parallel ports on the system.              ³
;³                                         ³
;³              *** Written by Joshua C. Jensen                              ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
proc    sd_DetectDACs
    uses    es
    mov    ax,0040h
    mov    es,ax
    mov    si,8
    mov    bx,size SoundSrcStruc
    shl    bx,1
    add    bx,offset SoundSources
    xor    cx,cx
    xor    dx,dx            ; Used for found DAC.
@@DACLoop:
    mov    ax,[es:si]        ; Get the address.
    add    si,2
    or    ax,ax            ; Is there a parallel port?
    jz    @@ParallelPut
    or    dx,dx            ; Do we already have one here?
    jnz    @@ParallelPut
    mov    dx,cx
    add    dx,2
@@ParallelPut:
    mov    [bx+SoundSrcStruc.AddressLeft],ax
    add    bx,size SoundSrcStruc
    inc    cx
    cmp    cx,4
    jz    @@DACLoop
    mov    [SoundSource],dl
    ret
endp    sd_DetectDACs

end

