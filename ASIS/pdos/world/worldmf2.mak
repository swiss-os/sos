# Produce z/Windows executables using scc390
# links with PDPCLIB created by makefile.z32


CPP=pdcc
CC=scc390
AS=as370 -mhlasm -mebcdic
LD=pdlde --oformat coff --emit-relocs --no-insert-timestamp

COPTS=-E -D__SUBC__ -D__MF32__ -D__WIN32__ -D__NOBIVA__ \
    -D__NODECLSPEC__ -D__SHORTNAMES__ \
    -I../pdpclib -I../src \
    -Dunsigned= -Dlong=int -Dshort=int -Dconst= -Ddouble=int

EXTRA=../pdpclib/mfsupa.obj ../pdpclib/setjmp.obj ../pdpclib/msvcrt.lib

all: world.exe

world.exe: world.obj
  $(LD) -s -nostdlib -o world.exe ../pdpclib/w32start.obj world.obj $(EXTRA)

.c.obj:
  $(CPP) $(COPTS) -o $*.i $<
  $(CC) -S -o $*.s $*.i
  rm -f $*.i
  $(AS) -o $@ $*.s
  rm -f $*.s
