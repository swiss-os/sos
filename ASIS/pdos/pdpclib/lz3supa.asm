# lz3supa.asm - support code for C programs for 32-bit z/Linux
# also known as the s390 target
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

# If you activate these 2 lines, then if you run the
# executable and do:
# echo $?
# It will tell you "5"
# And this can be used to get a number from 0 to 255,
# so with enough patience you can find out the value of registers
# if you have a consistent execution environment.
#la %r2,5
#svc 1   # exit




# r15 is the stack, which grows down
# r14 is the return address
# r2, r3 etc are the parameters

balr    %r15,%r0
bctr    %r15,0
bctr    %r15,0


# Even though this is 32-bit code, we may wish to run
# in AM64. Which will work so long as we don't use
# negative indexes - which aren't that common.
# But we need to make sure the high halves of the 64-bit
# registers are zero. We could do that in a single
# z/Arch instruction, but it is better to stick with
# multiple S/370 instructions in case this code is ever
# used on older machines.
# r15 will have already been properly set by the above balr.

la %r0,0
la %r1,0
la %r2,0
la %r3,0
la %r4,0
la %r5,0
la %r6,0
la %r7,0
la %r8,0
la %r9,0
la %r10,0
la %r11,0
la %r12,0
la %r13,0
la %r14,0


# load a register with 0xffffffff and do a la
# of it and see if any bits are cleared.
# If bits are cleared, masking is in place, so
# no further actions is required.
# If it remains intact then it is either:
# 1. AM64 and we need to adjust mode
# 2. AM32 from unknown source and no need to do anything
# 3. AM32 on a S360/67 and we need to avoid doing a BSM

# S360/67 is going to be given an EC mode PSW which will
# set the ASCII bit
# Load 1 into a register, do a CVD, and you will get
# 1C if EBCDIC, or 1A for ASCII

# If not a S360/67 then it is mandatory that the BSM
# instruction is supported in whatever architecture
# potentially gave us AM32. Minimal BSM functionality.
# Behave the same as AM24 does - do nothing.
# So load a register with 0, BSM to R0, to preserve
# the current AMODE. If the register changes, assume
# AM64 and then do a BSM to set AM31

# Note that the S360/67 starts with a "standard PSW"
# and we need to convert it into an "extended PSW"
# by setting bit 8 of CR6 and then doing an LPSW.
# Having bit 4 in the new PSW set to 1 will enable
# AM32..

# ... to be implemented


# Experimentation with SAM31/SAM64 (note that these
# instructions should be replaced with BSM when we're
# doing the real thing) shows that qemu-s390x will
# honor a transition to AM31 as far as data references
# are concerned, but is not doing so for execution
# references. So a BASR, like BALR in AM31, will set
# the high bit of the return register, and if an LA
# is not done to clear the high bit before returning,
# the program will crash. A bug report should probably
# be created.


# Do a failsafe check on negative indexes.

la %r3,bbb2-__pdpent(%r15)
lhi %r4,-4
# This load instruction, which uses a negative index,
# will almost certainly fail if the
# OS is running AM64 and has failed to map the 4-8 GiB
# region to 0-4 GiB to give effective AM32. So this is a
# failsafe. If this fails, the executable should instead
# be marked as 32-bit so it is run as AM31 (or AM32 on a
# S360/67 or other AM32 environment, or an AM24 etc
# environment).
l %r2,0(%r4,%r3)
##svc 1




# This doesn't seem to exist
#.using __pdpent, %r15
#la      %r15,ttt
# and there doesn't seem to be a "lar" either,
# unlike the larl from s390x

la      %r15,ttt-__pdpent(%r15)

ahi     %r15,16384
ahi     %r15,16384
ahi     %r15,16384

lr      %r14,%r15
ahi     %r15,-104
st      %r14,0(%r15)

# need to put the stack pointer at entry to
# 176+160(%r15)

# We ideally want to have the 4-byte address
# constants 4-byte aligned.
# So we need to have some predictability, regardless
# of what the previous instructions generated.

        bras    %r13,.FIRST

.align 4
.FIRST:

# This instruction is 4 bytes, so we don't need a NOP
# instruction (nopr %r0) - it's already aligned.
# However, I'm putting in two nopr (nopr is a 2-byte
# instruction, so we add another 4 bytes) in case the
# situation changes in the future.
        nopr    %r0
        nopr    %r0
	bras	%r13,.LTN0
.LT0:
.LC0:
	.long	_start
.LTN0:

# This doesn't seem to work
#bras    %r14,_start

l	%r1,.LC0-.LT0(%r13)

# No idea why branching to r2 works, but r1 doesn't
# I suspect that the large stack is being detected as
# data at some point in qemu. Critical point is to not
# let this:
# D:\devel\pdos\pdpclib>hexdump works.exe 0x1004 4
# 001004  0040BFFE                             .@..
# clock over to 40C000
# which happens when the stack is around 45032 bytes

# Another way to get around the problem is to just rerun
# the program, perhaps more than once (e.g. once I had
# to run it 6 times), as it appears to be a bug in
# z/Linux or qemu

lr      %r2,%r1
basr	%r14,%r2

#lmg     %r14,%r15,272(%r15)
#br      %r14

# If we return, better to crash
ggg: .word 0

# Not expected to return, but better to loop than do random things
loop5: b loop5


.align 8
bbb1: .long 2
bbb2: .long 3, 4


.align 8
ttt: .long 0
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

svc 1
