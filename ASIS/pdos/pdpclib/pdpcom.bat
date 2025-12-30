rem This builds a .com file using pdld, from object
rem code produced by makefile.wcd with the tiny
rem memory model and targeting a COM file

rem change "binary" to "a.out" and with SEGHACK
rem defined in makefile.wcd, you can link large/huge too
rem od386 -r will show you the relocations, but they
rem appear to be negative numbers, so do 100000000 minus
rem the number shown

pdas -o secend.obj ../src/secend.asm

pdld -Map map.txt -o pdptest.tmp --oformat binary dosstart.obj ^
assert.obj ^
ctype.obj ^
dossupa.obj ^
dossupc.obj ^
errno.obj ^
locale.obj ^
math.obj ^
pdptest.obj ^
setjmp.obj ^
signal.obj ^
start.obj ^
stdio.obj ^
stdlib.obj ^
string.obj ^
time.obj ^
secend.obj

xychop pdptest.tmp pdptest.com 0x100 0xffff
