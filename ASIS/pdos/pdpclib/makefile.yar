# This builds 64-bit Windows ARM64 (PE/coff) executables
# using gcc built with aarch64-mingw64

# run makek32.yar first

# Note that this compiler uses 32-bit long


CC=gcc
COPTS=-c -I../src -D__ARM__ -I. -D__WIN32__ -D__PDPCLIB_DLL \
    -DNOUNDMAIN -D__GENSHELL__ -O2 -U__gnu_linux__ \
    -D__64BIT__ -nostdlib -nostdinc \
    -D__NODECLSPEC__ \
    -fno-stack-protector --no-pie -fno-builtin

AR=ar
LD=pdld --no-insert-timestamp -s
#LD=ld
AS=as


TARGET=pdptest.exe
OBJS=w32start.obj stdio.obj string.obj stdlib.obj start.obj time.obj errno.obj \
    assert.obj signal.obj locale.obj ctype.obj math.obj dllcrt.obj \
    a64supa.obj

$(TARGET): clean pdptest.obj $(OBJS)
  rm -f temp.lib
  $(AR) r temp.lib $(OBJS)
  $(LD) --export-all-symbols -o msvcrt.dll --shared --out-implib msvcrt.lib dllcrt.obj temp.lib ../src/kernel32.lib
  rm -f temp.lib
  $(LD) -nostdlib -e mainCRTStartup -o pdptest.exe w32start.obj pdptest.obj msvcrt.lib

w32start.obj: w32start.c
  $(CC) -o $@ $(COPTS) -U__PDPCLIB_DLL $*.c

pdptest.obj: pdptest.c
  $(CC) -o $@ $(COPTS) -U__PDPCLIB_DLL $*.c

dllcrt.obj: dllcrt.c
  $(CC) -o $@ $(COPTS) -D__EXPORT__ -DNEED_START $*.c

.c.obj:
  $(CC) -o $@ $(COPTS) $<

a64supa.obj: a64supa.asm
  $(AS) -o a64supa.obj a64supa.asm

.asm.obj:
  $(AS) -o $@ $<

clean:
  rm -f *.obj
  rm -f $(TARGET)
