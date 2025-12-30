# Load an MVS module and execute it

# You need to have run makefile.370 first

CFLAGS=-Os
EXTRA1=--oformat mvs --amode 31 --rmode any
EXTRA2= ../pdpclib/mvsstart.obj ../pdpclib/mvssupa.obj ../pdpclib/pdpclib.a



CC=gccmvs
AS=as370 -mhlasm -mebcdic

COPTS=-S -Os -fno-common $(CFLAGS) \
    -D__NOBIVA__ -I . -I../pdpclib -I../src \
    -fno-builtin -D__MVS__ -DNEED_MVS
AR=xar
LD=pdld --emit-relocs --entry __crt0


OBJS=loadmvs.obj ../bios/exeload.obj

all: clean loadmvs.exe

loadmvs.exe: $(OBJS)
        $(LD) $(EXTRA1) -o loadmvs.exe $(OBJS) $(EXTRA2)

.c.obj:
        $(CC) $(COPTS) -o $*.s $<
        $(AS) -o $@ $*.s
        rm -f $*.s

.asm.obj:
        $(AS) -o $@ $<

clean:
        rm -f loadmvs.exe
