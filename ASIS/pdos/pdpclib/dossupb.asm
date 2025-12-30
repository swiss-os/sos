; dossupb.asm - assembler support functions for DOS
;
; This program written by Paul Edwards
; Released to the public domain

; For functions/variables that aren't C so shouldn't
; have C as the language

% .model memodel

extrn ___divide:proc
extrn ___modulo:proc

.code

; These are needed for Turbo C++

; must release stack space in this procedure
; original value and divisor will be on stack
; return value in dx:ax
public ludiv@
ludiv@:
public f_ludiv@
f_ludiv@ proc
push bp
mov bp,sp

; Watcom seems to be allowed to trash bx and cx,
; and we call a C routine later
push bx
push cx
push ds

cmp word ptr [bp + 10 + @CodeSize * 2], 0
jne ludiv_full

mov ax, [bp + 6 + @CodeSize * 2]
mov dx, 0
div word ptr [bp + 8 + @CodeSize * 2]
mov bx, ax
mov ax, [bp + 4 + @CodeSize * 2]
div word ptr [bp + 8 + @CodeSize * 2]

mov dx, bx
jmp short ludiv_fin

ludiv_full:
push word ptr [bp + 10 + @CodeSize * 2]
push word ptr [bp + 8 + @CodeSize * 2]
push word ptr [bp + 6 + @CodeSize * 2]
push word ptr [bp + 4 + @CodeSize * 2]

call ___divide

add sp, 8

ludiv_fin:

pop ds
pop cx
pop bx
pop bp
ret 8
f_ludiv@ endp



; must release stack space in this procedure
public ldiv@
ldiv@:
public f_ldiv@
f_ldiv@ proc
push bp
mov bp,sp

push ds
; I don't know why we need to preserve dx. I expected
; the return value to be a dx:ax pair. Maybe it works
; in conjunction with the f_lmod call, and the return
; value is only ax
push dx

; Watcom seems to be allowed to trash bx and cx,
; and we call a C routine later
push bx
push cx

cmp word ptr [bp + 10 + @CodeSize * 2], 0
jne ldiv_full

mov ax,[bp+4+@CodeSize*2]
mov dx,[bp+6+@CodeSize*2]
idiv word ptr [bp+8+@CodeSize*2]
jmp short ldiv_fin

ldiv_full:
push word ptr [bp + 10 + @CodeSize * 2]
push word ptr [bp + 8 + @CodeSize * 2]
push word ptr [bp + 6 + @CodeSize * 2]
push word ptr [bp + 4 + @CodeSize * 2]

call ___divide

add sp, 8

ldiv_fin:

pop cx
pop bx
pop dx
pop ds
pop bp
ret 8
f_ldiv@ endp


public lmod@
lmod@:
public f_lmod@
f_lmod@ proc
push bp
mov bp,sp

; Watcom seems to be allowed to trash bx and cx,
; and we call a C routine later
push bx
push cx
push ds

cmp word ptr [bp + 10 + @CodeSize * 2], 0
jne lmod_full

mov ax,[bp+4+@CodeSize*2]
mov dx,[bp+6+@CodeSize*2]
idiv word ptr [bp+8+@CodeSize*2]
mov ax,dx
mov dx,0
jmp short lmod_fin

lmod_full:
push word ptr [bp + 10 + @CodeSize * 2]
push word ptr [bp + 8 + @CodeSize * 2]
push word ptr [bp + 6 + @CodeSize * 2]
push word ptr [bp + 4 + @CodeSize * 2]

call ___modulo

add sp, 8

lmod_fin:

pop ds
pop cx
pop bx
pop bp
ret 8
f_lmod@ endp



; procedure needs to fix up stack
; original value and divisor will be on stack
; return in dx:ax
public lumod@
lumod@:
public f_lumod@
f_lumod@ proc
push bp
mov bp,sp

; Watcom seems to be allowed to trash bx and cx,
; and we call a C routine later
push bx
push cx

cmp word ptr [bp + 10 + @CodeSize * 2], 0
jne lumod_full

mov ax, [bp + 6 + @CodeSize * 2]
mov dx, 0
div word ptr [bp + 8 + @CodeSize * 2]
mov ax, [bp + 4 + @CodeSize * 2]
div word ptr [bp + 8 + @CodeSize * 2]
mov ax,dx
mov dx, 0
jmp short lumod_fin

lumod_full:
push word ptr [bp + 10 + @CodeSize * 2]
push word ptr [bp + 8 + @CodeSize * 2]
push word ptr [bp + 6 + @CodeSize * 2]
push word ptr [bp + 4 + @CodeSize * 2]

call ___modulo

add sp, 8

lumod_fin:

pop cx
pop bx
pop bp
ret 8
f_lumod@ endp



; multiply cx:bx by dx:ax, result in dx:ax

public lxmul@
lxmul@:
public f_lxmul@
; masm doesn't like this unless language is C
;f_lxmul@ proc uses cx bx si di
f_lxmul@ proc

push cx
push bx
push si
push di

; Code provided by Terje Mathisen
mov si,ax
mov di,dx
mul cx ;; hi * lo
xchg ax,di ;; First mul saved, grab org dx
mul bx ;; lo * hi
add di,ax ;; top word of result

mov ax,si ;; retrieve original AX
mul bx ;; lo * lo
add dx,di

pop di
pop si
pop bx
pop cx

ret
f_lxmul@ endp


; shift dx:ax left by cl

public lxlsh@
lxlsh@:
public f_lxlsh@
;f_lxlsh@ proc uses bx
f_lxlsh@ proc

push bx

cmp cl, 24
jl lxlsh_16
mov dh, al
mov dl, 0
mov ax, 0
sub cl, 24
jmp short lxlsh_last

lxlsh_16:
cmp cl, 16
jl lxlsh_8
mov dx, ax
mov ax, 0
sub cl, 16
jmp short lxlsh_last

lxlsh_8:
cmp cl, 8
jl lxlsh_last
mov dh, dl
mov dl, ah
mov ah, al
mov al, 0
sub cl, 8
;jmp short lxlsh_last

lxlsh_last:

mov ch, 8
sub ch, cl
xchg ch, cl
mov bx, ax
shr bx, cl
xchg ch, cl
shl dx, cl
or dl, bh
shl ax, cl

pop bx

ret
f_lxlsh@ endp



public f_lxursh@
;f_lxursh@ proc uses bx
f_lxursh@ proc

push bx

cmp cl, 24
jl lxursh_16
mov al, dh
mov ah, 0
mov dx, 0
sub cl, 24
jmp short lxursh_last

lxursh_16:
cmp cl, 16
jl lxursh_8
mov ax, dx
mov dx, 0
sub cl, 16
jmp short lxursh_last

lxursh_8:
cmp cl, 8
jl lxursh_last
mov al, ah
mov ah, dl
mov dl, dh
mov dh, 0
sub cl, 8
;jmp short lxursh_last

lxursh_last:

mov ch, 8
sub ch, cl
xchg ch, cl
mov bx, dx
shl bx, cl
xchg ch, cl
shr ax, cl
or ah, bl
shr dx, cl

pop bx

ret
f_lxursh@ endp


; this procedure needs to fix up the stack
; can't use "uses" keyword until proc knows about parameters
public scopy@
scopy@:
public f_scopy@
f_scopy@ proc

push bp
mov bp, sp
push cx
push ds
push es
push si
push di
lds si, [bp + 4 + @CodeSize * 2]
les di, [bp + 8 + @CodeSize * 2]
cld
rep movsb

pop di
pop si
pop es
pop ds
pop cx
pop bp
ret 8
f_scopy@ endp


public ftol@
ftol@:
public f_ftol@
f_ftol@ proc
ret
f_ftol@ endp



public FIDRQQ
public FIWRQQ
public FIERQQ
public FJARQQ
public FIARQQ
public FJCRQQ
public FICRQQ
public FJSRQQ
public FISRQQ

.data

FIDRQQ  dw  ?
FIWRQQ  dw  ?
FIERQQ  dw  ?
FJARQQ  dw  ?
FIARQQ  dw  ?
FJCRQQ  dw  ?
FICRQQ  dw  ?
FJSRQQ  dw  ?
FISRQQ  dw  ?

public flags8087@
flags8087@ dw 0

dummy1 dw 3
public __edata
; masm doesn't like this
;__edata:
__edata dw 4

.data?
dummy2 dw ?
public __end
;__end:
__end dw ?

end
