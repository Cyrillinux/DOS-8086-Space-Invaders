;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³  FILENAME: PPS.INC	Version 1.00					     ³
;³									     ³
;³  DATE    : April 27, 1992						     ³
;³                                                                           ³
;³  Ideal Mode -- Turbo Assembler v2.01 and above			     ³
;³                                                                           ³
;³  DESCRIPTION: This include file declares all the public symbols used by   ³
;³  the module player program.						     ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

; The original C header structure.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; struct ST24Mod {
;   BYTE songname[20];				  /* 0 */
;   struct {
;     BYTE Name[22];				  /* 20 */
;     WORD Length;				  /* 42 */
;     WORD Volume;				  /* 44 */
;     WORD Repeat;				  /* 46 */
;     WORD RepLen;				  /* 48 */
;   } sample[31];
;   BYTE songlen;
;   BYTE I_dont_know_what_this_byte_is;
;   BYTE playseq[128];
;   LONG mk;					  /* Contains M.K. */
; };
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Public structures and equates.

;³    *** Written by Joshua C. Jensen.	Originally by Dave Ashcroft.	     ³
struc   SoundSrcStruc
SName		db	8 dup (?)
Special 	db	?
AddressLeft	dw	?
AddressRight	dw	?
ends    SoundSrcStruc

;³ Original Amiga equates by Lars "Zap" Hamre.  Converted to IBM structure   ³
;³ by Joshua C. Jensen. 						     ³
struc   MS
Note            dw      ?
cmd             db      ?
cmdlo           db      ?
start           dw      ?
Length          dw      ?
LoopStart       dw      ?
RepLen          dw      ?
Period          dw      ?
FineTune        db      ?
Volume          db      ?
TonePortDirec   db      ?
TonePortSpeed   db      ?
WantedPeriod    dw      ?
VibratoCmd      db      ?
VibratoPos      db      ?
TremoloCmd      db      ?
TremoloPos      db      ?
WaveControl     db      ?
GlissFunk       db      ?
SampleOffset    db      ?
pattpos         db      ?
loopcount       db      ?
FunkOffset      db      ?
WaveStart       dw      ?
RealLength      dw      ?
MasterVolume    db      ?
Trigger         db      ?
SampleNum       db      ?
ends    MS

;³    *** Written by Joshua C. Jensen.					     ³
struc   MCS                     ; My Channel Stuff
MSeg		dw	?
MOfs		dw	?
MRepeat 	dw	?
MRepLen 	dw	?
MFreq		dw	?
MMaxRep 	dw	?
MOFlow		dw	?
MVol		db	?
MIns		db	?
ends    MCS

;³		*** Written by Joshua C. Jensen 			     ³
TSSeg           equ     [ds:bp+(offset (MCS).MSeg)]
TSOff           equ     [ds:bp+(offset (MCS).MOfs)]
TSRepeat        equ     [ds:bp+(offset (MCS).MRepeat)]
TSRepeatLen     equ     [ds:bp+(offset (MCS).MRepLen)]
TSNoteFreq      equ     [ds:bp+(offset (MCS).MFreq)]
TSMaxRep        equ     [ds:bp+(offset (MCS).MMaxRep)]
TSVol1          equ     [ds:bp+(offset (MCS).MVol)]
TSIns           equ     [Byte ds:bp+(offset (MCS).MIns)]

codeseg

global	sd_InitSound:proc
global  sd_PlayMusic:proc
global	sd_PlayIns:proc
global	sd_SetupForMusic:proc
global	sd_CloseAllMusic:proc
global	sd_ShutDownMusicInt:proc
global	sd_SetFreq:proc

global	sd_SetMainAddr:proc
global	sd_ReturnInfo:proc
global	sd_Set15Ins:proc
global	sd_Set31Ins:proc
global	sd_SetMaxVolume:proc

global	sd_DetectSB:proc
global	sd_DetectDACs:proc
global  sd_SetupMinor:proc
global	sd_GetHighestBlock:proc
global	sd_ClearInstrumentLocations:proc
global	sd_ClearPatternLocations:proc
global	sd_LoadModule:proc

dataseg

global	Fatal:byte

global	SequenceOffset:word
global	MKHeader:word
global	HeaderSize:word
global	NumberInstruments:word

global	TypeOfSample:byte
global	SoundSource:byte
global	MusicPlayerInstalled:byte
global	SoundSources:SoundSrcStruc
global	Channel1:MS
global	Channel2:MS
global	Channel3:MS
global	Channel4:MS

global	MaxVolume:word
global	PlayStatus:byte
global	NumBlocks:byte
global	ModuleLoaded:byte
global	MStatus:byte
global	Header:byte:1084
global	InsLoc:word:31
global	PatternLoc:word:64

global	SampleRate:word
global	MainFreq:dword
global	LSBCounter:word
global	IntMaster:word
global	IntCountDown:word

global	IntSet:byte
global	TypeOfInt:byte
global	Int08:dword
global	IntMask:byte
global	FreqMult:word
global  MainAddr:word
global	PlayerInterrupt:word
global	TimeValue:word

global	Channel4Seg:word
global  Channel3Seg:word
global  Channel2Seg:word
global  Channel1Seg:word
global  Channel4Freq:word
global  Channel3Freq:word
global  Channel2Freq:word
global  Channel1Freq:word
global  Channel1Vol2:byte
global  Channel2Vol2:byte
global  Channel3Vol2:byte
global  Channel4Vol2:byte
global	Channel1Vol1:byte
global	Channel2Vol1:byte
global	Channel3Vol1:byte
global	Channel4Vol1:byte
global  Channel1Ins:byte
global  Channel2Ins:byte
global  Channel3Ins:byte
global  Channel4Ins:byte

global	mt_speed:byte
global  mt_counter:byte
global  mt_PatternPos:word
global  mt_SongPos:byte

global	mt_PeriodTable:word
