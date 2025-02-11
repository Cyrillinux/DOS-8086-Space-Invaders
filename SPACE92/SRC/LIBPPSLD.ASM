;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;�  FILENAME: PPSLOAD.ASM   Version 1.00				     �
;�									     �
;�  DATE    : April 27, 1992						     �
;�                                                                           �
;�  Ideal Mode -- Turbo Assembler v2.01 and above			     �
;�                                                                           �
;�  DESCRIPTION: This file includes all routines for loading Amiga modules.  �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

	ideal				; Use TASM's Ideal mode.
	model	Small,Pascal		; Define the memory model.
	P286				; Set up for 286 instructions.
	jumps				; Have TASM automatically resolve out-
					; of-range jumps.

	include "libpps.inc"

codeseg

;郞袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
;� NAME       : sd_SetupMinor						     �
;�                                                                           �
;� ENTRY      : None                                                         �
;�                                                                           �
;� RETURN     : None                                                         �
;�                                                                           �
;� DESCRIPTION: Sets up the counter variables, frequency values, and clears  �
;�		several sections of memory.				     �
;�									     �
;�              *** Written by Joshua C. Jensen                              �
;突袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
proc	sd_SetupMinor
	uses	ds,es
	mov	ax,@data		; Make sure the data segment is set
        mov     ds,ax                   ; to the main data segment in which
	mov	es,ax			; all of our variables are stationed.
	mov	[Word mt_PatternPos],0	; Start at beginning of block.
	mov	[Byte mt_SongPos],0	; Start at beginning of song.
	mov	[Byte mt_counter],0	; Set the counter to zero so that
                                        ; when it begins counting, it doesn't
                                        ; skip part of a note.

        ; 컴컴 Clear out segment, offset, etc. pointers before we play, so it
        ; 컴컴 doesn't "screech" on the first note.
	mov	di,offset Channel1Seg	; Set a pointer to Channel1Seg.
	xor	ax,ax
	mov	cx,16			; Get structure size.
	shl	cx,1			; In total, we have Size*4 bytes to clear
	rep	stosw			; (four channels), so multiplying it
					; by two will make CX = Size * 2 and we
                                        ; will be clearing by moving Word 0's
                                        ; into the structure, thus making it
					; Size * 4.
	call	sd_SetFreq
	call	sd_SetMaxVolume
	mov	[Byte ModuleLoaded],1	; If we've made it this far, then the
                                        ; module was loaded correctly.
        ret                             ; Exit.
endp	sd_SetupMinor

;郞袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
;� NAME       : sd_GetHighestBlock                                           �
;�                                                                           �
;� ENTRY      : None                                                         �
;�                                                                           �
;� RETURN     : AL - Highest block                                           �
;�                                                                           �
;� DESCRIPTION: This code will return the highest block in a sequence.       �
;�              That is, it will return the largest number of patterns to    �
;�              load from or save to a file.                                 �
;�									     �
;�              *** Written by Joshua C. Jensen                              �
;突袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
proc    sd_GetHighestBlock
	uses	ds

        mov     ax,@data                ; Make sure the data segment is set
        mov     ds,ax                   ; to the main data segment in which
                                        ; all of our variables are stationed.

	mov	si,[SequenceOffset]	; Set SI to the sequence location in
                                        ; the header.
	add	si,offset Header
        mov     cx,128                  ; 128 (127) sequences total to search
                                        ; through.
        xor     ax,ax

	; 컴컴 In the following search, AH is going to store the highest block
	; 컴컴 found so far.  AL is used for comparisons.  CX is the counter.
@@SetHighestBlock:
	mov	ah,al			; Store the higher block number
	jmp	@@BotLoop
@@SearchLoop:
	lodsb
	cmp	al,ah			; Compare against the largest block.
        jg      @@SetHighestBlock       ; Is it greater than our stored value?
@@BotLoop:
	loop	@@SearchLoop
	mov	al,ah
	inc	al			; Increment the highest block by one
                                        ; so when the loader loads them in or
                                        ; the blocks are saved, it takes care
                                        ; of them all.
        xor     ah,ah                   ; Clear ah.

        ret
endp    sd_GetHighestBlock

;郞袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
;� NAME       : sd_ClearInstrumentLocations                                  �
;�                                                                           �
;� ENTRY      : None                                                         �
;�                                                                           �
;� RETURN     : None                                                         �
;�                                                                           �
;� DESCRIPTION: The following code is going to zero out the instrument       �
;�              segment locations, so old values aren't sitting there.       �
;�									     �
;�              *** Written by Joshua C. Jensen                              �
;突袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
proc    sd_ClearInstrumentLocations
        push    ds

        mov     ax,@data                ; Make sure the data segment is set
        mov     ds,ax                   ; to the main data segment in which
	mov	es,ax			; all of our variables are stationed.

	xor	ax,ax
	mov	cx,31			; Get the number of instruments.
	mov	di,offset InsLoc	; Set BX to the offset of the
                                        ; instrument locations.
@@ZeroInstruments:
	rep	stosw

	mov	[Byte TypeOfSample],0	; We have found no greater than 64k
                                        ; samples yet.
        pop     ds
        ret
endp    sd_ClearInstrumentLocations

;郞袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
;� NAME       : sd_ClearPatternLocations				     �
;�                                                                           �
;� ENTRY      : None                                                         �
;�                                                                           �
;� RETURN     : None                                                         �
;�                                                                           �
;� DESCRIPTION: The following code is going to zero out the pattern          �
;�              segment locations, so old values aren't sitting there.       �
;�									     �
;�              *** Written by Joshua C. Jensen                              �
;突袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
proc	sd_ClearPatternLocations
        push    ds

        mov     ax,@data                ; Make sure the data segment is set
        mov     ds,ax                   ; to the main data segment in which
	mov	es,ax			; all of our variables are stationed.

	xor	ax,ax
        mov     cx,64                   ; 64 Pattern Locations to clear
	mov	di,offset PatternLoc	; Set BX to the offset of the
                                        ; pattern locations.
@@ZeroPatterns:
	rep	stosw

        pop     ds
        ret
endp	sd_ClearPatternLocations

;郞袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
;� NAME       : sd_LoadPatterns 					     �
;�                                                                           �
;� ENTRY      : AX - Number of patterns.				     �
;�		BX - File Handle.					     �
;�									     �
;� RETURN     : Carry set - there was an error. 			     �
;�                                                                           �
;� DESCRIPTION: This will read the patterns from the module.		     �
;�									     �
;�              *** Written by Joshua C. Jensen                              �
;突袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
proc    sd_LoadPatterns
	uses	ds
	mov	dx,@data
        mov     ds,dx
        mov     es,dx

        push    bx                      ; Push the handle.
	push	ax			; Push num to do.

        call    sd_ClearPatternLocations

        ; 컴컴 Each block is 400h bytes long or 1k.  By shifting $400 right
        ; 컴컴 4 times (dividing it by 16) we can figure out how many
        ; 컴컴 paragraphs of memory it is going to require.
        mov     bx,1024                 ; Set BX to 400h.
        shr     bx,4                    ; Shift it right four times.
        inc     bx                      ; Add one more paragraph for safety.
                                        ; In all reality, if there are 64
                                        ; patterns, this only adds an
                                        ; additional 16k to the module.
                                        ; Cut this line if that memory is
                                        ; needed.

        mov     di,offset PatternLoc    ; Set DI to PatternLoc so we can store
                                        ; pattern segments as we allocate them.
	pop	cx			; Set CX to highest pattern.

	push	cx			; Save...

	; 컴컴 This is where we begin allocating all of the blocks.
@@BlockAllocLoop:
        push    bx                      ; Save BX - Size to allocate.
        mov     ax,4800h                ; Allocate the memory.
        int     21h
        jnb     @@BlockAllocatedOK      ; No problem with allocation.
        mov     [Byte Fatal],1
        mov     ax,3                    ; Set Couldn't Allocate Block flag.
	stc
	ret
@@BlockAllocatedOK:
        stosw                           ; ES:DI -- Store segment in list.
	pop	bx
	loop	@@BlockAllocLoop

	; 컴컴 This is where we begin allocating all of the blocks.
        pop     cx                      ; Pop the Num blocks counter.
	mov	si,offset PatternLoc	; Set SI to PatternLoc so we can read
					; pattern segments.
	xor	dx,dx			; Load all segments at 0 offset.
	pop	bx			; Pop the handle.

@@BlockReadLoop:
        push    cx                      ; Save CX - Highest Block Counter.

	push	ds
	lodsw				; Read pattern segment.
	mov	ds,ax
	mov	cx,1024 		; (400h bytes).
        mov     ax,3F00h                ; Load in the block.
        int     21h
        jnb     @@BlockReadOK           ; No problem reading the block
	pop	cx cx			; We had a problem loading the block.
        mov     ax,4                    ; Set Couldn't Read Block flag.
	stc
	ret

@@BlockReadOK:
	pop	ds
	pop	cx			; Restore the bytes to allocate and
                                        ; restore the counter.
        loop    @@BlockReadLoop         ; Keep going until we've allocated
                                        ; all the blocks.
        clc
	ret
endp    sd_LoadPatterns

;郞袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
;� NAME       : sd_LoadSamples						     �
;�                                                                           �
;� ENTRY      : BX - File Handle.					     �
;�									     �
;� RETURN     : Carry set - there was an error. 			     �
;�                                                                           �
;� DESCRIPTION: This will read the samples from the module.		     �
;�									     �
;�              *** Written by Joshua C. Jensen                              �
;突袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
proc    sd_LoadSamples
	uses	ds
	local	Handle:word
	mov	[Handle],bx
	mov	dx,@data
        mov     ds,dx
        mov     es,dx

	call	sd_ClearInstrumentLocations

	; 컴컴 Now we are going to read all the samples into memory.  SI is
        ; 컴컴 the current location in the header of the length field for the
        ; 컴컴 samples.
        mov     si,2Ah                  ; Start at sample length field.
                                        ; If you were to calculate an offset,
                                        ; 2Ah would be this location.  I can't
                                        ; use a structure to determine this,
                                        ; because we have two kinds of modules
                                        ; to support (15 and 31 instruments).

        mov     di,offset InsLoc        ; Set BX to be a pointer to the
                                        ; instrument segment list.
        mov     cx,[NumberInstruments]  ; Set CX to be the counter.  Load it
                                        ; with the highest number of
                                        ; instruments.
	xor	dx,dx			; Set offset to 0.

@@SampleReadLoop:
        push    cx                      ; Store the counter.

	mov	bx,[si+offset Header+4] ; Get the repeat from the header.
	xchg	bl,bh			; On the Amiga, word values are
                                        ; swapped from the IBM.  Swap it to
                                        ; the correct IBM position.
	mov	[si+offset Header+4],bx ; Store it back to the header.
	mov	bx,[si+offset Header+6] ; Get the repeat length from the header.
	xchg	bl,bh
	mov	[si+offset Header+6],bx ; Store it back to the header.
	mov	bx,[si+offset Header]	; Get the length from the header.
	xchg	bl,bh
	mov	[si+offset Header],bx	; Store it back to the header.

	or	bx,bx			; See if the length is actually zero.
        jnz     @@InstrumentExists      ; It not, do something about it.
        add     di,2
        jmp     @@DoneInstrument

@@InstrumentExists:
	cmp	bx,8000h		; Is the length greater than 8000h?
        jnb     @@ReadSample64          ; Yes, jump to @@ReadSample64.

	push	bx			; Save the length.

        ; 컴컴 Samples vary in length.  By shifting the length right
        ; 컴컴 4 times (dividing it by 16) we can figure out how many
        ; 컴컴 paragraphs of memory it is going to require.

        ; 컴컴 The length in a sample that is less than 64k has been divided
        ; 컴컴 by two.  The reason for this is because a sample that is
        ; 컴컴 greater than 64k appears in the length field as a value
        ; 컴컴 greater than or equal to 8000h.  If it is this, then we know
        ; 컴컴 we have found a >64k sample.

        ; 컴컴 When we find a >64k sample, we subtract from the length 8000h.
        ; 컴컴 Then we multiply it by 2 and store the value.  We then load in
        ; 컴컴 64k of the sample and restore our saved length and load that
        ; 컴컴 in.
	shr	bx,4			; Shift the length right four times.
	inc	bx			; Add an extra paragraph for safety.
	shl	bx,1
        mov     ax,4800h                ; Allocate the memory.
        int     21h
	pop	cx			                    ; Restore the length.
        jnb     @@SampleAllocatedOK     ; No problem with the allocation.

        pop     cx                      ; Pop used registers off the stack.
        mov     [Byte Fatal],1
        mov     ax,5                    ; Set Couldn't Allocate Sample flag.
	stc
	ret

@@SampleAllocatedOK:
        stosw                           ; Store segment in list.

        push    ds                      ; Save data segment for later.
        mov     ds,ax                   ; Load the allocated segment into DS.
        shl     cx,1                    ; Double the length so we don't cut
                                        ; off half of the sample.
        mov     bx,[Handle]
        mov     ax,3F00h                ; Read it in.
        int     21h
        pop     ds                      ; Restore the data segment.
        jnb     @@DoneInstrument        ; No problems reading the sample.

        pop     cx                      ; Pop used registers off the stack.
        mov     ax,6                    ; Set Couldn't Read Sample flag.
	stc
	ret

@@DecSize:
        mov     ax,[si+offset Header]
        dec     ax
        dec     ax
        dec     ax
        mov     [si+offset Header],ax
@@DoneInstrument:
        pop     cx                      ; Restore counter.
	add	si,30			; Size of sample structure.
        loop    @@SampleReadLoop
	clc
	ret

@@ReadSample64:
	pop	cx			; Pop used registers.
	mov	[Byte TypeOfSample],1	; Signify the greater than 64k sample.
        mov     ax,9
	stc
	ret
endp    sd_LoadSamples

;郞袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
;� NAME       : sd_SetModuleSize					     �
;�                                                                           �
;� ENTRY      : BX - File Handle.					     �
;�									     �
;� RETURN     : Carry set - there was an error. 			     �
;�                                                                           �
;� DESCRIPTION: This will determine the size of the module...15 or 31 ins.   �
;�									     �
;�              *** Written by Joshua C. Jensen                              �
;突袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
proc    sd_SetModuleSize
        call    sd_Set15Ins             ; Assume 15 instruments.
        mov     cx,0
        mov     dx,438h
        mov     ax,4200h                ; Reposition file pointer.
        int     21h
        jnb     @@GetTheMK
        mov     ax,2                    ; Set Couldn't Read Header flag.
	stc
	ret
@@GetTheMK:
        mov     dx,offset Header        ; If there is a M.K. or FLT4 at this
        mov     cx,4                    ; position, then it is 31 ins.
        mov     ax,3f00h
        int     21h
        jnb     @@DoCompare
        mov     ax,2
	stc
	ret
@@DoCompare:
        mov     ax,[Word Header]
	xchg	ah,al			; Amiga swap.
	cmp	ax,"M."                 
        jz      @@Its31
	cmp	ax,"FL"
        jnz     @@LoadHeader
@@Its31:
        call    sd_Set31Ins
@@LoadHeader:
        mov     cx,0
        mov     dx,0
        mov     ax,4200h                ; Reposition file pointer to beginning.
        int     21h
	clc
	ret
endp    sd_SetModuleSize

;郞袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
;� NAME       : sd_LoadModule                                                �
;�                                                                           �
;� ENTRY      : DS:DX -- Pointer to ASCIIZ filename of module to be loaded.  �
;�                                                                           �
;� RETURN     : AX - Error Flag                                              �
;�                1 - Couldn't open module                                   �
;�                2 - Couldn't read header                                   �
;�                3 - Couldn't allocate block                                �
;�                4 - Couldn't read block                                    �
;�                5 - Couldn't allocate sample                               �
;�                6 - Couldn't read sample                                   �
;�                7 - Couldn't close module                                  �
;�		  8 - Couldn't determine size                                �
;�		  9 - >64k sample.					     �
;�                                                                           �
;�              Carry set -- Error                                           �
;�              Carry clear -- Module loaded successfully                    �
;�                                                                           �
;� DESCRIPTION: This procedure handles all module loading for the player.    �
;�              It ensures that pointers are set up properly.                �
;�                                                                           �
;�              sd_LoadModule distinguishes between less than 64k samples    �
;�		and greater than 64k samples.  It also detects whether a     �
;�		module is 15 or 31 instruments.  However, >64k sample	     �
;�		support doesn't exist because I haven't had time to          �
;�		reimplement it. 					     �
;�                                                                           �
;�              *** Written by Joshua C. Jensen                              �
;突袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴�
proc    sd_LoadModule
	uses	ds
	local	Handle:word

	mov	ax,3D00h		; Open the module file.
	int	21h			; Everything is fine if carry is not
	jnb	@@ModuleOpenOK		; set.

        mov     ax,1                    ; Set Couldn't Open Module flag.
	jmp	@@Abort
@@ModuleOpenOK:
	mov	[Handle],ax
	mov	ax,@data
	mov	ds,ax
	mov	[Byte Fatal],0		; No fatal error yet.
        mov     [Byte ModuleLoaded],0   ; We haven't loaded a module yet.
        mov     [Byte mt_speed],6       ; Standard module playing speed.
        mov     [Byte MStatus],1        ; Set music status to not playing.

	mov	bx,[Handle]
	call	sd_SetModuleSize
	jb	@@Abort

	; 컴컴 We're now going to load in the header.  The reason CX is
        ; 컴컴 obtaining its information from HeaderSize is because the
        ; 컴컴 size of the header varies from 15 instrument to 31 instrument
        ; 컴컴 modules.
	mov	cx,[HeaderSize] 	; Number of bytes to read.
        mov     dx,offset Header        ; Offset of our storage for the header.
	mov	bx,[Handle]
	mov	ax,3F00h		; Load in the header
        int     21h
        jnb     @@HeaderLoadedOK        ; If we didn't fail, skip the next part.

        mov     ax,2                    ; Set Couldn't Read Header flag.
        jmp     @@Abort                 ; Abort.

@@HeaderLoadedOK:
        call    sd_GetHighestBlock      ; Find the highest block.
        mov     [NumBlocks],al          ; Store it for later use.

	mov	bx,[Handle]
	call	sd_LoadPatterns
	jb	@@LoadFail		; There was a major error.

	mov	bx,[Handle]
	call	sd_LoadSamples
	jb	@@LoadFail

	mov	bx,[Handle]		; Close the module file.
	mov	ax,3E00h
	int	21h
        jnb     @@FinishUp              ; No problems closing the module.
        mov     ax,7                    ; Something happened...don't know what.
        jmp     @@LoadFail              ; Abort.

@@FinishUp:
	call	sd_SetupMinor		; Set up the final values.
        ret                             ; Exit

@@Abort:
        stc
        ret

        ; 컴컴 @@LoadFail is called when there is an error after some memory
        ; 컴컴 allocation has been done.
@@LoadFail:
        push    ax                      ; Save the error flag.
        call    sd_CloseAllMusic        ; Close down EVERYTHING.
        pop     ax                      ; Restore the error flag.
        stc                             ; Set the carry flag.
        ret                             ; Exit;
endp    sd_LoadModule

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

end

