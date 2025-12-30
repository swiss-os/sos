# Produce z/Windows LX (OS/2 format) executables
# links with PDPCLIB created with makefile.mf2

# The entry point for the OS/2 program is normally
# some startup code, but since we're not using
# parameters at the moment, that has been skipped

CC=pdccmf
AS=as370 -mhlasm -mebcdic
LD=pdlde --oformat lx --emit-relocs --no-insert-timestamp -e __start

COPTS=-D__MF32__ -D__OS2__ -D__NOBIVA__ -D__32BIT__ \
    -D__NODECLSPEC__ -D__SHORTNAMES__ \
    -I../pdpclib -I../src -fno-common

EXTRA=../pdpclib/pdpos2.lib ../pdpclib/os2.lib

all: world.exe

world.exe: world.obj
  $(LD) -s -nostdlib -o world.exe world.obj $(EXTRA)

.c.obj:
  $(CC) $(COPTS) -o $*.s $<
  $(AS) -o $@ $*.s
  rm -f $*.s
