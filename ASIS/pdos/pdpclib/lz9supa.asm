# lz9supa.asm - support code for C programs for 64-bit z/Linux
# also known as the s390x (as opposed to 32-bit s390) target
#
# This program written by Paul Edwards
# Released to the public domain

# syscall numbers can be found here:

# http://linuxvm.org/penguinvm/notes.html

# And calling convention (for 32-bit) can be found at
# the same place under "S390 Register Usage".

# r2-r6 are used for parameters, after that, they go
# on the stack. r6 is the only one that needs to be
# preserved by the called program

# And you can enable coredumps on Linux with:
# ulimit -c unlimited
# Check with:
# ulimit -a

# argc and argv arguments are on the stack as usual,
# which is pointed to by r15


# We can use this as the entry point rather than _start(),
# to take note of the stack pointer at entry, for potential
# use by __start()

.globl __pdpent
__pdpent:

# r15 is the stack, which grows down
# r14 is the return address
# r2, r3 etc are the parameters

larl    %r15,ttt
aghi    %r15,16384
aghi    %r15,16384
aghi    %r15,16384

lgr     %r14,%r15
aghi    %r15,-160
stg     %r14,0(%r15)

# need to put the stack pointer at entry to
# 176+160(%r15)

brasl   %r14,_start

#lmg     %r14,%r15,272(%r15)
#br      %r14

# If we return, better to crash
ggg: .word 0

# Not expected to return, but better to loop than do random things
loop5: b loop5

ttt: .quad 0
.space 65536





# This function is required by GCC but isn't used for anything
.globl __main
__main:
br %r14



.globl __setj
__setj:

la %r2,0
br %r14




.globl __longj
__longj:

br %r14



.globl __write
__write:

svc 4
br %r14


.globl __read
__read:

svc 3
br %r14



.globl __open
__open:

svc 5
br %r14


.globl __seek
__seek:


.globl __rename
__rename:




.globl __remove
__remove:


.globl __close
__close:

svc 6
br %r14



.globl __exita
__exita:

# first parameter is in r2 already, and
# that's what we need now

svc 1   # exit



.globl __time
__time:


.globl __ioctl
__ioctl:

svc 54
br %r14


.globl __getpid
__getpid:

svc 20
br %r14


.globl __chdir
__chdir:


.globl __rmdir
__rmdir:


.globl __mkdir
__mkdir:


.globl __getdents
__getdents:


.globl __mprotect
__mprotect:


.globl __mmap
__mmap:


.globl __munmap
__munmap:


.globl __mremap
__mremap:


.globl __fork
__fork:


.globl __clone
__clone:


.globl __execve
__execve:


.globl __waitid
__waitid:


# You need to provide a buffer that is apparently 6 * 65 bytes
# in size minimum, because there are 6 strings, each with a
# fixed 65 bytes reserved

.globl __uname
__uname:

