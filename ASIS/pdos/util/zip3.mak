# Released to the public domain.
#
# Anyone and anything may copy, edit, publish,
# use, compile, sell and distribute this work
# and all its parts in any form for any purpose,
# commercial and non-commercial, without any restrictions,
# without complying with any conditions
# and by any means.

# Produces ARM64 PDOS-generic executable.

# This builds a PDOS-generic executable for ARM64
# Using the standard ARM64 (including UEFI) calling convention
# We don't have an appropriate subsystem for this executable
# as it is neither Windows nor UEFI - it is PDOS-generic
# So we set it to 0 - unknown

# This makefile is standalone

CC=cl
CFLAG=-O2 -Oi-
LD=pdld --oformat coff --no-insert-timestamp --subsystem 0
LDFLAGS=
AS=armasm64
AR=lib
COPTS=$(CFLAGS) -c -nologo -GS- -Za -Zl -u -X -D__MSC__ -D__64BIT__ \
    -I. -I../pdpclib -D__ARM__ \
    -I../generic -I../../pdcrc -I../src \
    -D__PDOS386__ -D__PDOSGEN__ -D__ARMGEN__ -D__NOBIVA__ 

all: clean zip.exe

zip.exe: ../pdpclib/pgastart.obj zip.obj ../pdpclib/a64supb.obj ../pdpclib/string.obj
  rm -f zip.exe
  $(LD) $(LDFLAGS) -s -e __crt0 -o zip.exe ../pdpclib/pgastart.obj zip.obj ../pdpclib/string.obj ../pdpclib/a64supb.obj

.c.obj:
    $(CC) $(COPTS) -Fo$@ $<

.asm.obj:
     $(AS) -nologo -o $@ $<

clean:
  rm -f *.obj zip.exe
