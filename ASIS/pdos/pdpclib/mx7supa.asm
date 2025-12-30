; x64 code for macOS in masm format

; Written by Paul Edwards
; Released to the public domain

; 64-bit x64 needs the stack 16-byte aligned, I think

; macOS needs the syscall number in rax, and it has
; 0x2000000 added to the normal-looking number.
; I then uses syscall, not some int like int 0x80

; Note that the syscall numbers are
; considered private, so you may need to recompile
; your software one day. This is not a problem for
; the intended purpose of creating a pseudo-bios for
; PDOS-generic. The pdos-generic applications do not
; require recompilation.

; MacOS standard calling convention has parameters in
; rdi, rsi, rdx, r10, r8, r9
; and these are also used by the syscall,
; so minimal code is required.
; Except rcx is used for non-syscall calling instead
; of r10, I think

; But we are using Win64 calling convention, so we
; get rcx, rdx, r8, r9 plus the stack, and need to
; convert

; syscall numbers may be available here:
; https://opensource.apple.com/source/xnu/xnu-1228/bsd/sys/syscall.h.auto.html


.code


public __pdpent
__pdpent:

; If we target MacOS 10, or do a static link for
; more recent MacOS, we don't get argc and
; argv in rdi and rsi. They are instead on the
; stack. So make argv point to the current stack
; pointer, and the C code will figure it out later

; Actually, since we are using pdld, and it has LC_MAIN
; defined, we will get rdi and rsi set already
; And because of the different calling conventions,
; we can't make _start the entry point.

mov rcx,rdi
mov rdx,rsi

call _start
;mov rcx,3
;call __exita

; shouldn't return here
rrr:
     jmp rrr




; void __exita(int rc);

        public  __exita
__exita:
        mov     rax, 02000001h
;           @ SYS_exit
; And yes, I know this isn't necessary - please
; stop writing in about it
        push rdi
        mov rdi,rcx
        syscall
        pop rdi

        ret




; int __write(int fd, void *buf, int len);

        public  __write
__write:
        mov     rax, 02000004h
;           @ SYS_write
        push rdi
        push rsi
        push rdx
        mov rdi, rcx
        mov rsi, rdx
        mov rdx, r8
        syscall
        pop rdx
        pop rsi
        pop rdi

        ret





; int setjmp(jmp_buf env);

        public __setj
__setj:


mov [rcx + 8*2], rbx
mov [rcx + 8*3], rcx
mov [rcx + 8*4], rdx
mov [rcx + 8*5], r8
mov [rcx + 8*6], r9
mov [rcx + 8*7], rsp
mov [rcx + 8*8], rsi
mov [rcx + 8*9], rdi
mov [rcx + 8*10], r10
mov [rcx + 8*11], r11
mov [rcx + 8*12], r12
mov [rcx + 8*13], r13
mov [rcx + 8*14], r14
mov [rcx + 8*15], r15
mov [rcx + 8*16], rbp
mov rax, [rsp]
mov [rcx + 8*1], rax

xor rax,rax
ret





; void _longjmp(int rc);

        public  __longj
__longj:


mov rax, [rcx + 8*7]
mov rsp, rax
mov rax, [rcx + 8*1]
mov [rsp], rax
mov rbx, [rcx + 8*2]
mov rdx, [rcx + 8*4]
mov r8, [rcx + 8*5]
mov r9, [rcx + 8*6]
mov rsi, [rcx + 8*8]
mov rdi, [rcx + 8*9]
mov r10, [rcx + 8*10]
mov r11, [rcx + 8*11]
mov r12, [rcx + 8*12]
mov r13, [rcx + 8*13]
mov r14, [rcx + 8*14]
mov r15, [rcx + 8*15]
mov rbp, [rcx + 8*16]
mov rax, [rcx]
mov rcx, [rcx + 8*3]
ret




; int __ioctl(unsigned int fd, unsigned int cmd, unsigned long arg);

        public  __ioctl
__ioctl:
        mov     rax,02000036h
;           @ SYS_ioctl

        push rdi
        push rsi
        push rdx
        mov rdi, rcx
        mov rsi, rdx
        mov rdx, r8
        syscall
        pop rdx
        pop rsi
        pop rdi

        ret




; int __getpid(void);

        public  __getpid
__getpid:
        mov     rax, 02000014h
;           @ SYS_getpid
        syscall

        ret




; int __seek(int fd, int pos, int how);

        public  __seek
__seek:
        mov     rax, 020000c7h
;           @ SYS_lseek
        push rdi
        push rsi
        push rdx
        mov rdi, rcx
        mov rsi, rdx
        mov rdx, r8
        syscall
        pop rdx
        pop rsi
        pop rdi

        ret





; int __mprotect(const void *buf, size_t len, int prot);

        public  __mprotect
__mprotect:
        mov     rax, 0200004ah
;           @ SYS_mprotect
        push rdi
        push rsi
        push rdx
        mov rdi, rcx
        mov rsi, rdx
        mov rdx, r8
        syscall
        pop rdx
        pop rsi
        pop rdi

        ret






; int __read(int fd, void *buf, int len);

        public  __read
__read:
        mov     rax, 02000003h
;           @ SYS_read
        push rdi
        push rsi
        push rdx
        mov rdi, rcx
        mov rsi, rdx
        mov rdx, r8
        syscall
        pop rdx
        pop rsi
        pop rdi

        ret






; int __close(int fd);

        public  __close
__close:
        mov     rax, 02000006h
;           @ SYS_close
        push rdi
        mov rdi, rcx
        syscall
        pop rdi

        ret





; sometimes there is a 3rd parameter
; int __open(char *path, int flags);

        public  __open
__open:
        mov     rax, 02000005h
;           @ SYS_open
        push rdi
        push rsi
        push rdx
        mov rdi, rcx
        mov rsi, rdx
        mov rdx, r8
        syscall
        jnc opengood
        mov rax,-1
opengood:

        pop rdx
        pop rsi
        pop rdi

        ret







; int __rename(char *old, char *new);

        public  __rename
__rename:
        mov     rax, 02000080h
;           @ SYS_rename
        push rdi
        push rsi
        mov rdi, rcx
        mov rsi, rdx
        syscall
        pop rsi
        pop rdi

        ret







; int __remove(char *path);

        public  __remove
__remove:
        mov     rax, 0200000ah
;           @ SYS_unlink
        push rdi
        mov rdi, rcx
        syscall
        pop rdi

        ret






; int __time(void);

        public __time
__time:

; Not sure what to do with this. Just return 0
; for now.
        mov rax, 0
        ret







; int __mmap(...);

        public  __mmap
__mmap:
        push rbp
        mov rbp, rsp
        push rdi
        push rsi
        push rdx
        push r10
        push r8
        push r9
        mov rdi, rcx
        mov rsi, rdx
        mov rdx, r8
        mov r10, r9
        mov r8, [rbp + 2*8]
        mov r9, [rbp + 3*8]
; The above 2 aren't working yet, but we know
; what is needed already
        mov r8,-1
        mov r9,0

        mov     rax, 020000c5h
;           @ SYS_mmap
        syscall
        pop r9
        pop r8
        pop r10
        pop rdx
        pop rsi
        pop rdi

        pop rbp

        ret








; int ___fork(...);

        public  __fork
__fork:
        mov     rax, 02000002h
;           @ SYS_fork
        syscall

        ret






; int __waitid(...);

        public  __waitid
__waitid:
        mov     rax, 020000adh
;           @ SYS_waitid
        syscall

        ret








; int __execve(...);

        public  __execve
__execve:
        mov     rax, 0200003bh
;           @ SYS_execve
        syscall

        ret







; int __munmap(void *a, size_t b);

        public  __munmap
__munmap:
        push rdi
        push rsi
        mov rdi, rcx
        mov rsi, rdx
;
        mov     rax, 02000049h
;           @ SYS_munmap
        syscall

        pop rsi
        pop rdi

        ret




; Doesn't appear to have mremap





; int __chdir(const char *filename);

        public  __chdir
__chdir:
        mov     rax, 0200000ch
;           @ SYS_chdir
        push rdi
        mov rdi, rcx
        syscall
        pop rdi

        ret







; int __mkdir(const char *filename);

        public  __mkdir
__mkdir:
        mov     rax, 02000088h
;           @ SYS_mkdir
        push rdi
        mov rdi, rcx
        syscall
        pop rdi

        ret







; int __rmdir(const char *filename);

        public  __rmdir
__rmdir:
        mov     rax, 02000089h
;           @ SYS_rmdir
        push rdi
        mov rdi, rcx
        syscall
        pop rdi

        ret






; There is a SYS_getdirentries of value 196,
; but I don't know how to use it

; int __getdents(unsigned int fd, struct linux_dirent *dirent, int count);

; there may be a 4th parameter of NULL

        public  __getdents
__getdents:
        mov     rax, 020000c4h
;           @ SYS_getdirentries
        push rdi
        push rsi
        push rdx
        push r10
        mov rdi, rcx
        mov rsi, rdx
        mov rdx, r8
        xor r10, r10
        syscall
        pop r10
        pop rdx
        pop rsi
        pop rdi

        ret




; I don't know how to do a sleep, but we may not need
; to sleep anyway

; int __nanosleep(unsigned int tval[2], unsigned int tval2[2]);



end
