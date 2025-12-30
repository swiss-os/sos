# Released to the public domain.
#
# Anyone and anything may copy, edit, publish,
# use, compile, sell and distribute this work
# and all its parts in any form for any purpose,
# commercial and non-commercial, without any restrictions,
# without complying with any conditions
# and by any means.

VPATH=../pdld/src;../pdld/src/bytearray



ifeq "$(targ)" "zpg"
# You need to have run makefile.zpg first
CC=gccmvs
CFLAGS=-Os
LD=pdlde
AS=as370 -mhlasm -mebcdic
AR=xar
COPTS=-S $(CFLAGS) -fno-common -ansi -I. \
    -I../pdld/src -I../pdld/src/bytearray -I../pdpclib \
    -I../generic -I../src -U__MVS__ -D__MF32__ -D__PDOSGEN__ \
    -D__NOBIVA__ -DNO_LONG_LONG -DSHORT_NAMES
EXTRA1=--oformat mvs -e __crt0 ../pdpclib/pgastart.o

else
CC=gccwin
CFLAGS=-O2
LD=pdld
LDFLAGS=-s
AS=pdas --oformat coff
COPTS=-S $(CFLAGS) -Wall -ansi -pedantic -fno-common \
    -I../pdld/src -I../pdld/src/bytearray -I../pdpclib \
    -D__WIN32__ -D__NOBIVA__ -DNO_LONG_LONG
EXTRA1=../pdpclib/w32start.obj
EXTRA2=../pdpclib/msvcrt.lib
endif


OBJS=forc4to8.obj elf_bytearray.obj bytearray.obj xmalloc.obj

TARGET=forc4to8.exe

all: clean $(TARGET)

$(TARGET): $(OBJS)
  $(LD) $(LDFLAGS) -o $(TARGET) $(EXTRA1) $(OBJS) $(EXTRA2)

.c.obj:
  $(CC) $(COPTS) -o $*.s $<
  $(AS) -o $@ $*.s
  rm -f $*.s

clean:
  rm -f $(OBJS) $(TARGET)
