rem if you copy pdp370.mac to pdptop.mac in order
rem to activate S/370, be sure to change the AMODE
rem and RMODE to 24 in the IEWL step of pdpmvs.m4

gccmvs -Os -DXXX_MEMMGR -S -I . start.c
gccmvs -Os -DXXX_MEMMGR -S -I . stdio.c
gccmvs -Os -DXXX_MEMMGR -S -I . stdlib.c
gccmvs -Os -DXXX_MEMMGR -S -I . ctype.c
gccmvs -Os -DXXX_MEMMGR -S -I . string.c
gccmvs -Os -DXXX_MEMMGR -S -I . time.c
gccmvs -Os -DXXX_MEMMGR -S -I . errno.c
gccmvs -Os -DXXX_MEMMGR -S -I . assert.c
gccmvs -Os -DXXX_MEMMGR -S -I . locale.c
gccmvs -Os -DXXX_MEMMGR -S -I . math.c
gccmvs -Os -DXXX_MEMMGR -S -I . setjmp.c
gccmvs -Os -DXXX_MEMMGR -S -I . signal.c
gccmvs -Os -DXXX_MEMMGR -S -I . __memmgr.c
gccmvs -Os -DXXX_MEMMGR -S -I . pdptest.c
m4 -I . pdpmvs.m4 >pdpmvs.jcl
rem call sub pdpmvs.jcl
call runmvs pdpmvs.jcl output.txt
