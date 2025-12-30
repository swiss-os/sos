# Produce 64-bit z/Windows executables
# links with PDPCLIB created with:
# genimp msvcrt.wat zarch.lib unknown

# Although it currently has an entry point of main
# instead of maincrtstartup (which doesn't yet exist),
# it should work anyway

CC=pdccz
AS=as370 -mhlasm -mebcdic
LD=pdlde --64 --oformat coff --emit-relocs --no-insert-timestamp

COPTS=-D__MF32__ -D__WIN32__ -D__NOBIVA__ \
    -D__NODECLSPEC__ -D__SHORTNAMES__ -D__NOBIVA__ \
    -I../pdpclib -I../src -fno-common

#EXTRA=../pdpclib/mfsupa.obj ../pdpclib/setjmp.obj ../pdpclib/msvcrt.lib
EXTRA=../pdpclib/zarch.lib

all: world.exe

world.exe: world.obj
#  $(LD) -s -nostdlib -o world.exe ../pdpclib/w32start.obj world.obj $(EXTRA)
  $(LD) -s -nostdlib -o world.exe world.obj $(EXTRA)

.c.obj:
  $(CC) $(COPTS) -o $*.s $<
  $(AS) -o $*.tmp $*.s
  rm -f $*.s
  forc4to8 $*.tmp $@
  rm -f $*.tmp
