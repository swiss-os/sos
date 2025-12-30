# This code was written by Paul Edwards
# Released to the public domain

# 64-bit LoongArch64 support files

# syscall numbers can be found here:
# https://docs.rs/syscall-numbers/latest/syscall_numbers/loongarch64/index.html

# registers are $r0 to $r31
# $r0 is always 0
# $r1 is the return address when a bl is done
#     (and so you need to preserve it if you call another function)
# $r3 appears to be stack pointer
# $r4, $r5 ... are arguments
# And arguments can be referenced as $a0, $a1 too, I think
# And $a0 aka $r4 is used for the return value too

.text

.ifndef LINUX
.set LINUX,0
.endif


.if LINUX

.globl __pdpent
.type __pdpent, %function
.align 2
__pdpent:
li.d $a0,5
#li.d $a7,93
#syscall 0
#bl __exita
bl _start

.endif



# int setjmp(jmp_buf env);

        .globl  __setj
        .type  __setj, %function
        .align  2
__setj:

# Not needed, always 0
#        st.d    $r0,$a0,0*8
        st.d    $r1,$a0,1*8
        st.d    $r2,$a0,2*8
        st.d    $r3,$a0,3*8

# Don't need this - longjmp will provide own return value
#        st.d    $r4,$a0,4*8

        st.d    $r5,$a0,5*8
        st.d    $r6,$a0,6*8
        st.d    $r7,$a0,7*8
        st.d    $r8,$a0,8*8
        st.d    $r9,$a0,9*8
        st.d    $r10,$a0,10*8
        st.d    $r11,$a0,11*8
        st.d    $r12,$a0,12*8
        st.d    $r13,$a0,13*8
        st.d    $r14,$a0,14*8
        st.d    $r15,$a0,15*8
        st.d    $r16,$a0,16*8
        st.d    $r17,$a0,17*8
        st.d    $r18,$a0,18*8
        st.d    $r19,$a0,19*8
        st.d    $r20,$a0,20*8
        st.d    $r21,$a0,21*8
        st.d    $r22,$a0,22*8
        st.d    $r23,$a0,23*8
        st.d    $r24,$a0,24*8
        st.d    $r25,$a0,25*8
        st.d    $r26,$a0,26*8
        st.d    $r27,$a0,27*8
        st.d    $r28,$a0,28*8
        st.d    $r29,$a0,29*8
        st.d    $r30,$a0,30*8
        st.d    $r31,$a0,31*8
        li.d    $a0,0

        jr      $r1



# void longjmp(jmp_buf env, int v);

        .globl  longjmp
        .type  longjmp, %function
        .align  2
longjmp:

# It is possible that the setjmp and longjmp are at the
# same stack level. And we want to store the return value
# in the setjmp stack position. So we subtract by 64 to
# get well away from setjmp

# Not sure if the stack needs 32-byte alignment

        addi.d  $r3,$r3,-64

# Get setjmp stack in $r6 temporarily
        ld.d    $r6,$a0,3*8

# Room to move
        addi.d  $r6,$r6,-32

# Preserve that for later use
        st.d    $r6,$r3,24

# Save return value for later use
# But first - if return value is 0, change it to 1
# so that setjmp will have correct behavior
        bnez    $r5,ljnz
        addi.d  $r5,$r0,1
ljnz:
        st.d    $r5,$r6,24

# Not needed, always 0
#        ld.d    $r0,$a0,0*8
        ld.d    $r1,$a0,1*8
        ld.d    $r2,$a0,2*8

# Don't adjust stack yet
#        ld.d    $r3,$a0,3*8

# We don't need the original argument value, as it is
# clobbered by the new return value anyway
# And that has previously been obtained and preserved
#        ld.d    $r4,$a0,4*8

        ld.d    $r5,$a0,5*8
        ld.d    $r6,$a0,6*8
        ld.d    $r7,$a0,7*8
        ld.d    $r8,$a0,8*8
        ld.d    $r9,$a0,9*8
        ld.d    $r10,$a0,10*8
        ld.d    $r11,$a0,11*8
        ld.d    $r12,$a0,12*8
        ld.d    $r13,$a0,13*8
        ld.d    $r14,$a0,14*8
        ld.d    $r15,$a0,15*8
        ld.d    $r16,$a0,16*8
        ld.d    $r17,$a0,17*8
        ld.d    $r18,$a0,18*8
        ld.d    $r19,$a0,19*8
        ld.d    $r20,$a0,20*8
        ld.d    $r21,$a0,21*8
        ld.d    $r22,$a0,22*8
        ld.d    $r23,$a0,23*8
        ld.d    $r24,$a0,24*8
        ld.d    $r25,$a0,25*8
        ld.d    $r26,$a0,26*8
        ld.d    $r27,$a0,27*8
        ld.d    $r28,$a0,28*8
        ld.d    $r29,$a0,29*8
        ld.d    $r30,$a0,30*8
        ld.d    $r31,$a0,31*8

# restore stack at the last minute, in case there is an
# interrupt. we have preserved that previously

        ld.d    $r3,$r3,24

# Get proper return value from the stack
        ld.d    $a0,$r3,24

# Restore stack to setjmp level
        addi.d  $r3,$r3,32

        jr      $r1





.if LINUX


# int ___write(int fd, void *buf, int len);

        .globl  __write
        .type  __write, %function
        .align  2
__write:
        li.d    $a7,64    # SYS_write

        syscall 0

        jr      $r1



# Does LoongArch64 require the use of rename, renameat
# or renameat2?

# int ___rename(char *old, char *new);

        .globl  __rename
        .type   __rename, %function
        .align  2
__rename:
        li.d    $a7,0x114   # SYS_renameat2

        syscall 0

        jr      $r1



# int _close(int fd);

        .globl  __close
        .type   __close, %function
        .align  2
__close:
        li.d    $a7,57    # SYS_close

        syscall 0

        jr      $r1



# int ___seek(int fd, int pos, int how);

        .globl  __seek
        .type  __seek, %function
        .align  2
__seek:
        li.d    $a7,62   # SYS_lseek

        syscall 0

        jr      $r1



# Does LoongArch64 require the use of unlinkat?

# int ___remove(char *path);

        .globl  __remove
        .type  __remove, %function
        .align  2
__remove:
        li.d    $a7,35   # SYS_unlinkat

        syscall 0

        jr      $r1




# LongArch64 requires the use of openat instead of open
# Not sure if we're required to preserve the parameter
# registers

# int _open(char *path, int flags);

        .globl  __open
        .type  __open, %function
        .align  2
__open:
        li.d    $a7,56   # SYS_openat

or $a3,$a2,$r0
or $a2,$a1,$r0
or $a1,$a0,$r0
# -100 means "current directory"
li.d $a0,-100

        syscall 0

        jr      $r1




# int ___ioctl(unsigned int fd, unsigned int cmd, unsigned long arg);

        .globl  __ioctl
        .type  __ioctl, %function
        .align  2
__ioctl:
        li.d    $a7,29     # SYS_ioctl

        syscall 0

        jr      $r1




# int ___getpid(void);

        .globl  __getpid
        .type  __getpid, %function
        .align  2
__getpid:
        li.d    $a7,172  # SYS_getpid

        syscall 0

        jr      $r1



# int ___read(int fd, void *buf, int len);

        .globl  __read
        .type  __read, %function
        .align  2
__read:
        li.d    $a7,63  # SYS_read

        syscall 0

        jr      $r1





# void _exita(int rc);

        .globl  __exita
.if ELF
        .type  __exita, %function
.endif
        .align  2
__exita:
        li.d    $a7,93     # SYS_exit

        syscall 0
        jr      $r1





# NOT YET IMPLEMENTED
# int __time(void);

        .globl  __time
.if ELF
        .type  __time, %function
.endif
        .align  2
__time:
        li.d    $a7,113  # SYS_clock_gettime

#        syscall 0
        jr      $r1




# int ___clone(...);

        .globl  __clone
        .type  __clone, %function
        .align  2
__clone:
        li.d    $a7,220   # SYS_clone

        syscall 0

        jr      $r1




# int ___waitid(...);

        .globl  __waitid
        .type  __waitid, %function
        .align  2
__waitid:
        li.d    $a7,95   # SYS_waitid

        syscall 0

        jr      $r1





# int ___execve(...);

        .globl  __execve
        .type  __execve, %function
        .align  2
__execve:
        li.d    $a7,221   # SYS_execve

        syscall 0

        jr      $r1





# int ___mmap(...);

        .globl  __mmap
        .type  __mmap, %function
        .align  2
__mmap:
        li.d    $a7,222   # SYS_mmap

        syscall 0

        jr      $r1




# int ___munmap(...);

        .globl  __munmap
        .type  __munmap, %function
        .align  2
__munmap:
        li.d    $a7,215   # SYS_munmap

        syscall 0

        jr      $r1




# mremap is 216


# int ___chdir(const char *filename);

        .globl  __chdir
.if ELF
        .type  __chdir, %function
.endif
        .align  2
__chdir:
        li.d    $a7,49   # SYS_chdir

        syscall 0
        jr      $r1





# Does Loongarch64 need mkdirat?

# int ___mkdir(const char *filename, int mode);

        .globl  __mkdir
.if ELF
        .type  __mkdir, %function
.endif
        .align  2
__mkdir:
        li.d    $a7,34  # SYS_mkdirat

        syscall 0

        jr      $r1




# NOT IMPLEMENTED
# Does LoongArch64 require unlinkat with AT_REMOVEDIR?

# int ___rmdir(const char *filename);

        .globl  __rmdir
.if ELF
        .type  __rmdir, %function
.endif
        .align  2
__rmdir:
        li.d    $a7,35  # SYS_unlinkat

        syscall 0

        jr      $r1





# LoongArch64 only has getdents64

# int ___getdents64(unsigned int fd, struct linux_dirent64 *dirent, int count);

        .globl  __getdents64
.if ELF
        .type  __getdents64, %function
.endif
        .align  2
__getdents64:

        li.d    $a7,61   # SYS_getdents64

        syscall 0

        jr      $r1



# char* __getcwd(char *buf, size_t len);

        .globl  __getcwd
        .type  __getcwd, %function
        .align  2
__getcwd:
        li.d    $a7,17    # SYS_getcwd

        syscall 0

        jr      $r1




# LINUX
.endif
