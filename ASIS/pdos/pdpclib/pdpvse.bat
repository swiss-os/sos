rem in order to run this, first copy pdp370.mac
rem (or possibly others) to pdptop.mac

rem Note that on my Windows 2000 system, the
rem AUTOSTARTED message isn't seen by PCRE after
rem the first run for unknown reasons, so I need
rem to restart Windows.
rem Another option is to manually type in:
rem script auto_run1.rc plus all the others as
rem required up until term.rc
rem Note that the screen appears to freeze during
rem some script runs.

rem del pdpvse.zip
gccvse -Os -DXXX_MEMMGR -S -I . start.c
gccvse -Os -DXXX_MEMMGR -S -I . stdio.c
gccvse -Os -DXXX_MEMMGR -S -I . stdlib.c
gccvse -Os -DXXX_MEMMGR -S -I . ctype.c
gccvse -Os -DXXX_MEMMGR -S -I . string.c
gccvse -Os -DXXX_MEMMGR -S -I . time.c
gccvse -Os -DXXX_MEMMGR -S -I . errno.c
gccvse -Os -DXXX_MEMMGR -S -I . assert.c
gccvse -Os -DXXX_MEMMGR -S -I . locale.c
gccvse -Os -DXXX_MEMMGR -S -I . math.c
gccvse -Os -DXXX_MEMMGR -S -I . setjmp.c
gccvse -Os -DXXX_MEMMGR -S -I . signal.c
gccvse -Os -DXXX_MEMMGR -S -I . __memmgr.c
gccvse -Os -DXXX_MEMMGR -S -I . pdptest.c
rem zip -0X pdpvse *.s *.exec *.asm *.mac

m4 -I . pdpvse.m4 >pdpvse.jcl
rem call sub pdpvse.jcl
sleep 2
call runvse pdpvse.jcl output.txt
rem This option can be used to copy an object file off the system
rem To copy a phase (executable) off the system, you will need to
rem copy the code from util/vsesimp/pdpvse.m4
rem call runvse pdpvse.jcl output.txt none keep.dat
