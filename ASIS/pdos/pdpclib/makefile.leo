# This builds the PDOS-generic OS library for the
# EBCDIC version of the x64 mini-Windows clone

# See makefile.web for comments about iconv

# We need to get rid of PDOS386 one day and
# replace it with just PDOSGENOS (ie the define,
# not the product)

# Testing revealed that NOSPECBIVA was needed.
# Otherwise this doesn't print properly:
# printf("another %3d %3d\n", 123, 456);
# 123 is printed twice
# without the 3 in 3d it works, presumably because
# the code doesn't go through to examine().

CC=gcc
COPTS=-S -O2 -fno-builtin -D__64BIT__ -I . -m64 \
    -mno-red-zone \
    -fno-common -U__gnu_linux__ -fno-stack-protector \
    -D__USEBIVA__ -D__NOSPECBIVA__ -nostdlib -nostdinc \
    -U__WIN32__ --no-pie -fno-leading-underscore \
    -D__GENSHELL__ \
    -DNOLIBALLOC -I . -I../pdpclib -I../src \
    -DUSE_MEMMGR -DNOUNDMAIN -D__PDOSGENOS__ \
    -DWINNEWMOD -D__PDOS386__ \
    -D__EBCDIC__

# Use EBCDIC
COPTS:=$(COPTS) -funsigned-char \
    -fexec-charset=IBM1047

AR=xar

AS=pdas --64 --oformat coff
#AS=as --64

LD=pdld --64 --oformat elf -nostdlib
# --emit-relocs
#LD=ld -static -nostdlib --emit-relocs
# don't need to use gcc
###LD=gcc -static -s -m64 -nostdlib -L,-emit-relocs

# ld doesn't like -s and --emit-relocs at the same time,
# so we need to use strip
STRIP=strip --strip-unneeded

all: pdosgeno.a

pdosgeno.a: stdio.o string.o stdlib.o \
       start.o time.o errno.o assert.o signal.o locale.o \
       ctype.o setjmp.o math.o l64supb.o pdossupc.o
        rm -f pdosgeno.a
        xar r pdosgeno.a stdio.o string.o stdlib.o l64supb.o
        xar r pdosgeno.a start.o time.o errno.o assert.o signal.o
        xar r pdosgeno.a locale.o ctype.o setjmp.o math.o pdossupc.o
        xar s pdosgeno.a

.c.o:
	$(CC) $(COPTS) -o $*.s $<
        $(AS) -o $@ $*.s
        rm -f $*.s

l64supb.o: l64supb.asm
        pdas --64 --oformat coff -o $@ $<
#	as --64 -o $@ $*.asm
#	as -o $@ $*.asm
#	as --64 --defsym STACKPARM=0 -o $@ $*.asm
