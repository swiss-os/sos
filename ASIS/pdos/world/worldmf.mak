# Produce z/Windows executables
# links with PDPCLIB created by makefile.z32


CC=pdccmf
AS=as370 -mhlasm -mebcdic
LD=pdlde --oformat coff --emit-relocs --no-insert-timestamp

COPTS=-D__MF32__ -D__WIN32__ -D__NOBIVA__ \
    -D__NODECLSPEC__ -D__SHORTNAMES__ \
    -I../pdpclib -I../src -fno-common

EXTRA=../pdpclib/mfsupa.obj ../pdpclib/setjmp.obj ../pdpclib/msvcrt.lib

all: world.exe

world.exe: world.obj
  $(LD) -s -nostdlib -o world.exe ../pdpclib/w32start.obj world.obj $(EXTRA)

.c.obj:
  $(CC) $(COPTS) -o $*.s $<
  $(AS) -o $@ $*.s
  rm -f $*.s
