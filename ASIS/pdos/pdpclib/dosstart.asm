; dosstart.asm - startup code for C programs for DOS
;
; This program written by Paul Edwards
; Released to the public domain

; For an executable, at entry, the CS:IP will be set
; correctly as specified in the executable header (offset
; 0x14 - 2 bytes - initial IP, and 0x16 - 2 bytes,
; an offset segment). DS and ES will both be set to point to the
; PSP. SS will be set correct as specified in the
; executable header (offset 0x0e - 2 bytes - an offset
; segment), and SP will be set to the stack length as
; specified in the executable header (offset 0x10 - 2 bytes).

; For a COM file, there is no header at all, so the values
; that are set are - all of CS, DS, ES, SS are set to point
; to the PSP and the IP is 0x100, ie at the end of the PSP,
; which means you need both an "org 100h" in your assembler
; code plus you need to link that object code first. You
; must also use the tiny memory model and you may use the
; exe2bin utility or your linker may be able to produce a
; COM file itself.

; Note that @model values are:
; 1 = tiny
; 2 = small
; 3 = compact
; 4 = medium
; 5 = large
; 6 = huge
; 7 = flat

% .model memodel, c

extrn __start:proc
extrn __exita:proc

ifdef POLLUTE
extrn __clrbss:proc
else
extrn _end:byte
extrn _edata:byte
endif

public __psp
public __envptr
public __osver

; define these before the stack so that the stack comes last,
; so that we can initialize bss
.data
.data?

ifndef MAKECOM
.stack 1000h
endif

; Create a BSS segment (.data? is the equivalent of .bss)
; in case we are using an option like -zt0 with Watcom and
; we end up with no BSS created at all, which stops the
; edata and end keywords from working - the linker gives
; this error:
; Error! E2083: file dosstart.obj(...\dosstart.asm):
; cannot reference address ffff:0000 from frame 12a2
; The "frame" is the segment for .data - so that's the
; start of the DGROUP, and the uninitialized BSS is between
; the end of the data and the end of everything. far BSS
; is initialized to NULs and part of the executable (I believe -
; not much choice).
; signal13_DATA  FAR_DATA  AUTO    0b87:71a0  0000001c
; _DATA          DATA      DGROUP  12a2:000c  00000012
; Note - b870 + 71a0 + 1c = 12a2c

.data?

.data

; This object code should be linked first so that this
; variable is at the beginning of DGROUP
banner  db  "PDPCLIB"
__psp   dd  ?
__envptr dd ?
__osver dw ?

if @DataSize eq 0
copypsp db 256 dup(?)
endif

.code

ifdef MAKECOM
org 100h
endif

top:

public __asmstart

__asmstart proc

; add some nops to create a cs-addressable save area, and also create a
; bit of an eyecatcher

nop
nop
nop
nop

; ds and es both point to the PSP, and we need ds for other purposes,
; so es will be used to preserve the PSP, and we won't trust any
; interrupt to preserve it for us, so we will push it now until we
; need it.

push es

; determine how much memory is needed. The stack pointer points
; to the top. Work out what segment that is, then subtract the
; starting segment (the PSP), and you have your answer.

; Note that if you don't do this, MSDOS will normally allocate
; as much memory as possible, according to the maxalloc in the
; executable header, which linkers normally set to x'ffff'.
; The minalloc is normally set to just the stack + bss, as both
; of these are outside the executable proper. But extra memory,
; if available, can be used as a heap for mallocs. Rather than
; patch every executable produced by every linker that sets the
; maxalloc to x'ffff', it is probably better to just do the
; resizing ourselves at runtime.

mov ax, sp
mov cl, 4
shr ax, cl ; get sp into pages
mov bx, ss
add ax, bx
add ax, 2 ; safety margin in case OS has made use of our stack
          ; and will get upset if we free it and it gets reused
mov bx, ds
sub ax, bx ; subtract the psp segment

; free initially allocated memory

mov bx, ax
mov ah, 4ah
int 21h

; It appears that in the tiny memory model, you are still required
; to set ds to the same as cs yourself, presumably because ds is
; pointing to the PSP while cs is probably pointing to the beginning
; of the executable. DGROUP may also get the correct value, presumably
; zero. es is set to ds a bit later. And you need to set ss to that
; value too. Actually, for a COM file (still tiny), DGROUP is unlikely
; to be valid because there is no relocation information, and in fact,
; ds will already be set correctly.

if @DataSize ne 0
ifndef AS86
jmp nextzz
; we are attempting to get the DGROUP segment
; but we want to allow the flexibility of going
; through a linker that is only capable of 32-bit flat
; and the conversion to segmentation would happen
; sometime after that.
; We can't put this data into the DGROUP itself, because
; we haven't yet established addressability to the DGROUP
; (data area)
; This 4-byte address will be offset followed by segment,
; so later we extract just the last 2 bytes.
dgaddr dd banner
nextzz:
endif
endif

if @Model eq 1
mov dx, cs
else

ifdef AS86
mov dx,DGROUP
else
; extract the last 2 bytes which are the segment portion
mov dx,word ptr dgaddr + 2
endif

endif


mov ds,dx

; In tiny, small and medium memory models, you need to set
; ss to ds (MSDOS will have set them to different values
; when it loaded the executable).
; ds and ss are the same so that
; near pointers can refer to either stack or data and still work

; It seems that even compact/large/huge require the same thing -
; they expect DS=SS and may use near pointers and the stack is
; in the DGROUP for this reason. I haven't actually observed
; near pointers being used though.

mov bx,ss
mov ax,ds
sub bx,ax
mov cl,4
shl bx,cl

mov bp, sp
add bp, bx
mov ss, dx
mov sp, bp

; we are responsible for clearing our own BSS
; in Watcom at least, the BSS is at the end of the DGROUP
; which can be referenced as _end, and the end of the
; DATA section is referenced as _edata
; We can use rep stos to clear the memory, which initializes
; using the byte in al, starting at es:di, for a length of cx

ifdef POLLUTE
call __clrbss
else

; In huge etc memory models, we may be able to have more
; than 64k of BSS, so we start by preparing a full 32-bit
; address of start and end of BSS.
; But currently we require it to reside in the same
; segment. We might want to switch to using memset which
; should take care of this. Although we still need an
; intermediatry C function to get the length, so that we
; don't have to subtract 2 huge pointers ourselves - especially
; if we are using 32-bit size_t

if @DataSize ne 0
jmp nextyy
myedata dd _edata
myend dd _end
nextyy:

mov di, word ptr myedata
mov cx, word ptr myend

else
mov di, offset DGROUP:_edata
mov cx, offset DGROUP:_end
endif


sub cx, di
; move ds (data pointer, often DGROUP, into es)
push ds
pop es
mov al, 0
rep stosb

endif


; The psp and envptr variables are only accessible with a far
; pointer, nominally not available in small data memory models
; (ie not if you have actually read ISO/IEC 9899:1990)
; (I watched the movie version)

pop es ; we preserved this right at the start

; Additionally, in small data memory models, the PSP is not
; actually addressable. In tiny model we could nominally rely
; on address wraparound, but if tiny is being used to produce
; a COM file, we'll end up with a NULL pointer, which will
; only work if there is no test of NULL done. So we simply
; make a copy of the PSP while we have the chance.

if @DataSize eq 0

; move from ds:si to es:di for a length of cx
; but it is es that currently has the "from", and ds that
; has the "to", so we need to swap them
mov cx, 256
mov si, 0
mov di, offset copypsp

; save originals
push ds
push es

; ready to swap
push ds
push es
; swap
pop ds
pop es
rep movsb

; restore originals
pop es
pop ds

mov word ptr __psp, offset copypsp
mov word ptr [__psp + 2], ds
; and set envptr to NULL
mov word ptr __envptr, 0
mov word ptr [__envptr + 2], ds

else

mov word ptr __psp, 0
mov word ptr [__psp + 2], es
mov word ptr __envptr, 0
mov dx, es:[02ch]
mov word ptr [__envptr + 2], dx

endif

; And we have now finished using es to address the psp
; so we can set it to the same as ds and es, which is
; what is normally expected

push ds
pop es

; Get the operating system version, which is used in the
; C code to know if the environment pointer is valid

mov ah,30h
int 21h
xchg al,ah
mov [__osver],ax

; push the psp now, ready for calling start

if @DataSize
push word ptr [__psp + 2]
endif
push word ptr [__psp]

call __start
if @DataSize
add sp, 4  ; delete psp from stack
else
add sp, 2
endif

push ax

; how do I get rid of the warning about "instruction can be compacted
; with override"?  The answer is certainly NOT to change the "far" to
; "near". Not relevant anymore now that exita is in dossupa.asm though
call __exita
add sp, 2
ret
__asmstart endp

public __main
__main proc
ret
__main endp


end top
