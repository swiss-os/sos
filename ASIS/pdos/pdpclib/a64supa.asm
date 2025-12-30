# This code was written by Paul Edwards
# Released to the public domain

# 64-bit ARM (AArch64) needs the stack 16-byte aligned

# syscall numbers can be found here:
# https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md


.ifndef STACKPARM
.set STACKPARM,0
.endif

.ifndef LINUX
.set LINUX,0
.endif

.ifndef ELF
.set ELF,0
.endif


# int setjmp(jmp_buf env);

        .globl  __setj
        .globl  ___setj
.if ELF
        .type  __setj, %function
.endif
        .align  2
__setj:
___setj:
        str     x1,[x0,#52*2]
        mov     x1,x0
        str     x2,[x1,#40*2]
        str     x3,[x1,#44*2]
        str     x12,[x1,#48*2]
        mov     x2,sp
        str     x2,[x1]
        str     x11,[x1,#4*2]
#   @ fp
        str     lr,[x1,#8*2]
#    @ r14
        str     x4,[x1,#12*2]
        str     x5,[x1,#16*2]
        str     x6,[x1,#20*2]
        str     x7,[x1,#24*2]
        str     x8,[x1,#28*2]
        str     x9,[x1,#32*2]
#   @ rfp
        str     x10,[x1,#36*2]
#  @ sl

        str     x13,[x1,#14*4*2]
        str     x14,[x1,#15*4*2]
        str     x15,[x1,#16*4*2]
        str     x16,[x1,#17*4*2]
        str     x17,[x1,#18*4*2]
        str     x18,[x1,#19*4*2]
        str     x19,[x1,#20*4*2]
        str     x20,[x1,#21*4*2]
        str     x21,[x1,#22*4*2]
        str     x22,[x1,#23*4*2]
        str     x23,[x1,#24*4*2]
        str     x24,[x1,#25*4*2]
        str     x25,[x1,#26*4*2]
        str     x26,[x1,#27*4*2]
        str     x27,[x1,#28*4*2]
        str     x28,[x1,#29*4*2]
        str     x29,[x1,#30*4*2]
        str     x30,[x1,#31*4*2]

# This doesn't assemble
# The distance 32 appears to be too far
# There is no sign that gcc is generating references to x31
# so it is probably fine to do nothing. No sign of references
# to x17 either.
#        str     x31,[x1,#32*4*2]

        mov     x0, #0
        ret



# void longjmp(jmp_buf env, int v);

        .globl  longjmp
        .globl  _longjmp
.if ELF
        .type  longjmp, %function
.endif
        .align  2
longjmp:
_longjmp:

        mov     x2,x0
        mov     x0,x1

        cbnz    x0,notzero
        cmp     x0,#0
#        moveq   x0,#1
        mov     x0,#1
notzero:

        mov     x1,x2

#        ldr     sp,[x1]
        ldr     x2,[x1]
        mov     sp,x2

        ldr     x11,[x1,#4*2]
#      @ fp
        ldr     lr,[x1,#8*2]
        str     lr,[sp]
        ldr     x4,[x1,#12*2]
        ldr     x5,[x1,#16*2]
        ldr     x6,[x1,#20*2]
        ldr     x7,[x1,#24*2]
        ldr     x8,[x1,#28*2]
        ldr     x9,[x1,#32*2]
        ldr     x10,[x1,#36*2]
        ldr     x2,[x1,#40*2]
        ldr     x3,[x1,#44*2]
        ldr     x12,[x1,#48*2]
#  @ ip

        ldr     x13,[x1,#14*4*2]
        ldr     x14,[x1,#15*4*2]
        ldr     x15,[x1,#16*4*2]
        ldr     x16,[x1,#17*4*2]
        ldr     x17,[x1,#18*4*2]
        ldr     x18,[x1,#19*4*2]
        ldr     x19,[x1,#20*4*2]
        ldr     x20,[x1,#21*4*2]
        ldr     x21,[x1,#22*4*2]
        ldr     x22,[x1,#23*4*2]
        ldr     x23,[x1,#24*4*2]
        ldr     x24,[x1,#25*4*2]
        ldr     x25,[x1,#26*4*2]
        ldr     x26,[x1,#27*4*2]
        ldr     x27,[x1,#28*4*2]
        ldr     x28,[x1,#29*4*2]
        ldr     x29,[x1,#30*4*2]
        ldr     x30,[x1,#31*4*2]
#        ldr     x31,[x1,#32*4*2]

        ldr     x1,[x1,#52*2]
#        mov     pc,lr
        ret



# For Windows support

.globl __main
__main:
ret



.if LINUX


.globl __pdpent
__pdpent:
        mov x0,sp
        bl _start
# shouldn't return, but if we do, loop
rrr:    b rrr



# int ___write(int fd, void *buf, int len);

        .globl  __write
        .globl  ___write
.if ELF
        .type  __write, %function
.endif
        .align  2
__write:
___write:
        sub     sp,sp,#16
        str     x8, [sp, #0]
.if STACKPARM
        ldr     x2,[sp,#40]     @ len
        ldr     x1,[sp,#32]      @ buf
        ldr     x0,[sp,#24]      @ fd
.endif
        mov     x8,#64
#           @ SYS_write

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret



# AArch64 requires the use of renameat instead

# int ___rename(char *old, char *new);

        .globl  __rename
        .globl  ___rename
.if ELF
        .type  __rename, %function
.endif
        .align  2
__rename:
___rename:
        sub     sp,sp,#32
        str     x8, [sp, #0]
        str     x1, [sp, #8]
        str     x2, [sp, #16]
        str     x3, [sp, #24]
.if STACKPARM
        ldr     x1,[sp,#48]      @ new
        ldr     x0,[sp,#40]      @ old
.endif
        mov     x3, x1
        mov     x2, #-100
# AT_FDCWD
        mov     x1, x0
        mov     x0, #-100
# AT_FDCWD
        mov     x8,#38
#           @ SYS_renameat

        svc     #0

        ldr     x3, [sp, #24]
        ldr     x2, [sp, #16]
        ldr     x1, [sp, #8]
        ldr     x8, [sp, #0]
        add     sp,sp,#32
        ret



# int _close(int fd);

        .globl  __close
        .globl  ___close
.if ELF
        .type  __close, %function
.endif
        .align  2
__close:
___close:
        sub     sp,sp,#16
        str     x8, [sp, #0]
.if STACKPARM
        ldr     x0,[sp,#24]      @ fd
.endif
        mov     x8,#57
#           @ SYS_close

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret



# int ___seek(int fd, int pos, int how);

        .globl  __seek
        .globl  ___seek
.if ELF
        .type  __seek, %function
.endif
        .align  2
__seek:
___seek:
        sub     sp,sp,#16
        str     x8, [sp, #0]
.if STACKPARM
        ldr     x2,[sp,#40]     @ how
        ldr     x1,[sp,#32]      @ pos
        ldr     x0,[sp,#24]      @ fd
.endif
        mov     x8,#62
#           @ SYS_lseek

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret



# AArch64 requires the use of unlinkat

# int ___remove(char *path);

        .globl  __remove
        .globl  ___remove
.if ELF
        .type  __remove, %function
.endif
        .align  2
__remove:
___remove:
        sub     sp,sp,#32
        str     x8, [sp, #0]
        str     x1, [sp, #8]
        str     x2, [sp, #16]
.if STACKPARM
        ldr     x0,[sp,#40]      @ path
.endif
        mov     x2,#0
# flags (not defining AT_REMOVEDIR)
        mov     x1, x0
        mov     x0, #-100
# AT_FDCWD
        mov     x8,#35
#           @ SYS_unlinkat

        svc     #0

        ldr     x2, [sp, #16]
        ldr     x1, [sp, #8]
        ldr     x8, [sp, #0]
        add     sp,sp,#32
        ret




# AArch64 requires the use of openat instead of open

# int _open(char *path, int flags);

        .globl  __open
        .globl  ___open
.if ELF
        .type  __open, %function
.endif
        .align  2
__open:
___open:
        sub     sp,sp,#32
        str     x8, [sp, #0]
        str     x1, [sp, #8]
        str     x2, [sp, #16]
        str     x3, [sp, #24]
.if STACKPARM
        ldr     x1,[sp,#48]      @ flags
        ldr     x0,[sp,#40]      @ path
.endif
        mov     x3,#0x1A4
#        @ 0644
        mov     x2, x1
        mov     x1, x0
        mov     x0, #-100
# AT_FDCWD
        mov     x8,#56
#           @ SYS_openat

        svc     #0

        ldr     x3, [sp, #24]
        ldr     x2, [sp, #16]
        ldr     x1, [sp, #8]
        ldr     x8, [sp, #0]
        add     sp,sp,#32
        ret



# int ___ioctl(unsigned int fd, unsigned int cmd, unsigned long arg);

        .globl  __ioctl
        .globl  ___ioctl
.if ELF
        .type  __ioctl, %function
.endif
        .align  2
__ioctl:
___ioctl:
        sub     sp,sp,#16
        str     x8, [sp, #0]
.if STACKPARM
        ldr     x2,[sp,#40]      @ arg
        ldr     x1,[sp,#32]      @ cmd
        ldr     x0,[sp,#24]      @ fd
.endif
        mov     x8,#29
#           @ SYS_ioctl

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret



# int ___getpid(void);

        .globl  __getpid
        .globl  ___getpid
.if ELF
        .type  __getpid, %function
.endif
        .align  2
__getpid:
___getpid:
        sub     sp,sp,#16
        str     x8, [sp, #0]
        mov     x8,#172
#           @ SYS_getpid

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret



# int ___read(int fd, void *buf, int len);

        .globl  __read
        .globl  ___read
.if ELF
        .type  __read, %function
.endif
        .align  2
__read:
___read:
        sub     sp,sp,#16
        str     x8, [sp, #0]
.if STACKPARM
        ldr     x2,[sp,#40]      @ len
        ldr     x1,[sp,#32]      @ buf
        ldr     x0,[sp,#24]      @ fd
.endif
        mov     x8,#63
#           @ SYS_read

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret





# void _exita(int rc);

        .globl  __exita
        .globl  ___exita
.if ELF
        .type  __exita, %function
.endif
        .align  2
__exita:
___exita:
        sub     sp,sp,#16
        str     x8, [sp, #0]
.if STACKPARM
        ldr     x0,[sp,#8]      @ rc
.endif
        mov     x8,#93
#           @ SYS_exit

        svc     #0
        ldr     x8,[sp, #0]
        add     sp,sp,#16
        ret




# int __time(void);

        .globl  __time
        .globl  ___time
.if ELF
        .type  __time, %function
.endif
        .align  2
__time:
___time:
# Unusual amount of storage used
        sub     sp,sp,#32
# Note that this store is unusual
        str     x8, [sp, #16]
        str     x1, [sp, #24]
# this is CLOCK_REALTIME
        mov     x0, #0
# this is a struct timespec
# it contains number of seconds followed by
# number of nanoseconds - both 64-bit values
        mov     x1, sp
        mov     x8,#113
#           @ SYS_clock_gettime

        svc     #0
        ldr     x1, [sp, #24]
        ldr     x8,[sp, #16]
# we are only interested in the number of seconds
        ldr     x0, [sp, #0]
# Unusual stack correction
        add     sp,sp,#32
        ret




# int ___clone(...);

        .globl  __clone
        .globl  ___clone
.if ELF
        .type  __clone, %function
.endif
        .align  2
__clone:
___clone:
        sub     sp,sp,#16
        str     x8, [sp, #0]
        mov     x8,#220
#           @ SYS_clone

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret




# int ___waitid(...);

        .globl  __waitid
        .globl  ___waitid
.if ELF
        .type  __waitid, %function
.endif
        .align  2
__waitid:
___waitid:
        sub     sp,sp,#16
        str     x8, [sp, #0]
        mov     x8,#95
#           @ SYS_waitid

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret




# int ___execve(...);

        .globl  __execve
        .globl  ___execve
.if ELF
        .type  __execve, %function
.endif
        .align  2
__execve:
___execve:
        sub     sp,sp,#16
        str     x8, [sp, #0]
        mov     x8,#221
#           @ SYS_execve

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret




# int ___mmap(...);

        .globl  __mmap
        .globl  ___mmap
.if ELF
        .type  __mmap, %function
.endif
        .align  2
__mmap:
___mmap:
        sub     sp,sp,#16
        str     x8, [sp, #0]
        mov     x8,#222
#           @ SYS_mmap

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret



# int ___munmap(...);

        .globl  __munmap
        .globl  ___munmap
.if ELF
        .type  __munmap, %function
.endif
        .align  2
__munmap:
___munmap:
        sub     sp,sp,#16
        str     x8, [sp, #0]
        mov     x8,#215
#           @ SYS_munmap

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret

# mremap is 216


# int ___chdir(const char *filename);

        .globl  __chdir
        .globl  ___chdir
.if ELF
        .type  __chdir, %function
.endif
        .align  2
__chdir:
___chdir:
        sub     sp,sp,#16
        str     x8, [sp, #0]
.if STACKPARM
        ldr     x0,[sp,#8]      @ filename
.endif
        mov     x8,#49
#           @ SYS_chdir

        svc     #0
        ldr     x8,[sp, #0]
        add     sp,sp,#16
        ret




# AArch64 uses mkdirat

# int ___mkdir(const char *filename, int mode);

        .globl  __mkdir
        .globl  ___mkdir
.if ELF
        .type  __mkdir, %function
.endif
        .align  2
__mkdir:
___mkdir:
        sub     sp,sp,#32
        str     x8, [sp, #0]
        str     x1, [sp, #8]
        str     x2, [sp, #16]
.if STACKPARM
        ldr     x1,[sp,#48]      @ mode
        ldr     x0,[sp,#40]      @ filename
.endif
        mov     x2, x1
        mov     x1, x0
        mov     x0, #-100
# AT_FDCWD
        mov     x8,#34
#           @ SYS_mkdirat

        svc     #0

        ldr     x2, [sp, #16]
        ldr     x1, [sp, #8]
        ldr     x8, [sp, #0]
        add     sp,sp,#32
        ret




# AArch64 requires unlinkat with AT_REMOVEDIR

# int ___rmdir(const char *filename);

        .globl  __rmdir
        .globl  ___rmdir
.if ELF
        .type  __rmdir, %function
.endif
        .align  2
__rmdir:
___rmdir:
        sub     sp,sp,#32
        str     x8, [sp, #0]
        str     x1, [sp, #8]
        str     x2, [sp, #16]
.if STACKPARM
        ldr     x0,[sp,#40]      @ path
.endif
        mov     x2,#0x200
# flags (setting AT_REMOVEDIR)
        mov     x1, x0
        mov     x0, #-100
# AT_FDCWD
        mov     x8,#35
#           @ SYS_unlinkat

        svc     #0

        ldr     x2, [sp, #16]
        ldr     x1, [sp, #8]
        ldr     x8, [sp, #0]
        add     sp,sp,#32
        ret



# int __getcwd(char *buf, size_t size);

        .globl  __getcwd
        .globl  ___getcwd
.if ELF
        .type  __getcwd, %function
.endif
        .align  2
__getcwd:
___getcwd:
        sub     sp,sp,#16
        str     x8, [sp, #0]
.if STACKPARM
        ldr     x1,[sp,#32]      @ size
        ldr     x0,[sp,#24]      @ buf
.endif
        mov     x8,#17
#           @ SYS_getcwd

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret





# AArch64 doesn't have getdents - only getdents64

# int ___getdents64(unsigned int fd, struct linux_dirent64 *dirent, int count);

        .globl  _getdents64
        .globl  __getdents64
.if ELF
        .type  _getdents64, %function
.endif
        .align  2
_getdents64:
__getdents64:

        sub     sp,sp,#16
        str     x8, [sp, #0]
.if STACKPARM
        ldr     x2,[sp,#40]      @ count
        ldr     x1,[sp,#32]      @ dirent
        ldr     x0,[sp,#24]      @ fd
.endif
        mov     x8,#61
#           @ SYS_getdents64

        svc     #0

        ldr     x8, [sp, #0]
        add     sp,sp,#16
        ret



# LINUX
.endif
