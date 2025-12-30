rem If pdptop is set to S/370, you don't need MEMMGR
rem if it is set to S/380, you do need MEMMGR, because
rem it does an ATL GETMAIN which only works once, with
rem current VM/380 technology

del pdpcms.zip
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . start.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . stdio.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . stdlib.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . ctype.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . string.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . time.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . errno.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . assert.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . locale.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . math.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . setjmp.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . signal.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . __memmgr.c
gccmvs -U__MVS__ -D__CMS__ -Os -DXXX_MEMMGR -S -I . pdptest.c
zip -0X pdpcms *.s *.exec cms*.asm *.mac

rem Useful for VM/380
call runcms pdpcms.exec output.txt pdpcms.zip
rem Use this if you want to get an object file off the system
rem call runcms pdpcms.exec output.txt pdpcms.zip keep.dat

rem Useful for z/VM
rem mvsendec encb pdpcms.zip pdpcms.dat
rem loc2ebc pdpcms.dat xfer.card 80
