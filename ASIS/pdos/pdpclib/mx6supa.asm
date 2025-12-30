# x64 code for macOS

# Written by Paul Edwards
# Released to the public domain

# 64-bit x64 needs the stack 16-byte aligned, I think

# macOS needs the syscall number in rax, and it has
# 0x2000000 added to the normal-looking number.
# I then uses syscall, not some int like int 0x80

# Note that the syscall numbers are
# considered private, so you may need to recompile
# your software one day. This is not a problem for
# the intended purpose of creating a pseudo-bios for
# PDOS-generic. The pdos-generic applications do not
# require recompilation.

# Standard calling convention has parameters in
# with parameters in rdi, rsi, rdx, r10, r8, r9
# and these are also used by the syscall,
# so minimal code is required.
# Except rcx is used for non-syscall calling instead
# of r10, I think

# syscall numbers may be available here:
# https://opensource.apple.com/source/xnu/xnu-1228/bsd/sys/syscall.h.auto.html


.code64
.intel_syntax noprefix


.globl ___pdpent
___pdpent:

# If we target MacOS 10 - or do a static link -
# we don't get argc and
# argv in rdi and rsi. They are instead on the
# stack. So make argv point to the current stack
# pointer, and the C code will figure it out later
# Another factor is whether LC_MAIN or LC_UNIXTHREAD
# is in effect - setting initial registers to 0
# But in old format, it may be neither!
# So if LC_MAIN is defined, this should NOT be the
# entry point. Set the entry point to _start (in C)
# instead. Otherwise, if this is the entry point,
# then save the stack pointer.

mov rdi,0
mov rsi,rsp

call __start

# shouldn't return here
rrr: jmp rrr




# void ___exita(int rc);

        .globl  ___exita
___exita:
        mov     rax, 0x2000001
#           @ SYS_exit
        syscall

        ret




# int ___write(int fd, void *buf, int len);

        .globl  ___write
___write:
        mov     rax, 0x2000004
#           @ SYS_write
        syscall

        ret





# int setjmp(jmp_buf env);

        .globl ___setj
___setj:

# Not yet implemented. Just return 0 until
# someone actually starts calling longjmp
        mov rax,0
        ret





# void _longjmp(int rc);

        .globl  _longjmp
_longjmp:

# Not yet implemented or used - so just loop
# for when someone actually uses it
loop2:  jmp loop2




# int ___ioctl(unsigned int fd, unsigned int cmd, unsigned long arg);

        .globl  ___ioctl
___ioctl:
        mov     rax,0x2000036
#           @ SYS_ioctl

        syscall

        ret




# int ___getpid(void);

        .globl  ___getpid
___getpid:
        mov     rax, 0x2000014
#           @ SYS_getpid
        syscall

        ret




# int ___seek(int fd, int pos, int how);

        .globl  ___seek
___seek:
        mov     rax, 0x20000c7
#           @ SYS_lseek
        syscall

        ret





# int ___mprotect(const void *buf, size_t len, int prot);

        .globl  ___mprotect
___mprotect:
        mov     rax, 0x200004a
#           @ SYS_mprotect
        syscall

        ret






# int ___read(int fd, void *buf, int len);

        .globl  ___read
___read:
        mov     rax, 0x2000003
#           @ SYS_read
        syscall

        ret






# int ___close(int fd);

        .globl  ___close
___close:
        mov     rax, 0x2000006
#           @ SYS_close
        syscall

        ret






# int ___open(char *path, int flags, ...);
# sometimes get a 3rd parameter

        .globl  ___open
___open:
        mov     rax, 0x2000005
#           @ SYS_open
        syscall

        jnc opengood
        mov rax,-1
opengood:

        ret







# int ___rename(char *old, char *new);

        .globl  ___rename
___rename:
        mov     rax, 0x2000080
#           @ SYS_rename
        syscall

        ret







# int ___remove(char *path);

        .globl  ___remove
___remove:
        mov     rax, 0x200000a
#           @ SYS_unlink
        syscall

        ret






# int __time(void);

        .globl ___time
___time:

# Not sure what to do with this. Just return 0
# for now.
        mov rax, 0
        ret







# int ___mmap(...);

        .globl  ___mmap
___mmap:
push rbp
mov rbp, rsp
push r10

mov r10, rcx
        mov     rax, 0x20000c5
#           @ SYS_mmap
        syscall

pop r10
pop rbp

        ret








# int ___fork(...);

        .globl  ___fork
___fork:
        mov     rax, 0x2000002
#           @ SYS_fork
        syscall

        ret






# int ___waitid(...);

        .globl  ___waitid
___waitid:
        mov     rax, 0x20000ad
#           @ SYS_waitid
        syscall

        ret








# int ___execve(...);

        .globl  ___execve
___execve:
        mov     rax, 0x200003b
#           @ SYS_execve
        syscall

        ret







# int ___munmap(...);

        .globl  ___munmap
___munmap:
        mov     rax, 0x2000049
#           @ SYS_munmap
        syscall

        ret




# Doesn't appear to have mremap





# int ___chdir(const char *filename);

        .globl  ___chdir
___chdir:
        mov     rax, 0x200000c
#           @ SYS_chdir
        syscall

        ret







# int ___mkdir(const char *filename);

        .globl  ___mkdir
___mkdir:
        mov     rax, 0x2000088
#           @ SYS_mkdir
        syscall

        ret







# int ___rmdir(const char *filename);

        .globl  ___rmdir
___rmdir:
        mov     rax, 0x2000089
#           @ SYS_rmdir
        syscall

        ret






# There is a SYS_getdirentries of value 196,
# but I don't know how to use it

# int ___getdents(unsigned int fd, struct linux_dirent *dirent, int count);





# I don't know how to do a sleep, but we may not need
# to sleep anyway

# int ___nanosleep(unsigned int tval[2], unsigned int tval2[2]);
