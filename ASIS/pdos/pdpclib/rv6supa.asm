# rv6supa.asm - support code for C programs for RISC-V 64-bit
#
# This program written by Paul Edwards
# Released to the public domain

# Syscall numbers can be found here:

# https://docs.rs/syscall-numbers/latest/syscall_numbers/riscv64/index.html

# Keep stack 16-byte aligned

# ra contains return address of call and should normally
# be preserved

# a0 contains an int parm

.globl __pdpent
__pdpent:



call _start


li a0,3

li a7,0x5d

ecall



# Not expected to return, but better to loop than do random things
loop5: j loop5


.globl __setj
__setj:

ret



.globl __longj
__longj:

ret


.globl __exita
__exita:

li a7,0x5d

ecall

qqq: j qqq



.globl __write
__write:
.globl __read
__read:
.globl __open
__open:
.globl __seek
__seek:
.globl __ioctl
__ioctl:
.globl __close
__close:
.globl __clone
__clone:
.globl __mmap
__mmap:
.globl __munmap
__munmap:
.globl __rename
__rename:
.globl __remove
__remove:
.globl __getpid
__getpid:
.globl __execve
__execve:
.globl __waitid
__waitid:

xxx: j xxx
