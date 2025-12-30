del pdosflop.img
pdmake -f makek32.std
cd ..\pdpclib
pdmake -f makefile.pdw
pdmake -f makefile.std
cd ..\src
call comp4w
rem pdmake TARG=PDOS32 -f makeio.w32
call comp5w
call comp6w
call compb
mkdosfs --boot pbootsec.com --sectors 2880 -F 12 pdosflop.img
mcopy -i pdosflop.img pload.com ::IO.SYS
mcopy -i pdosflop.img pdos.exe ::PDOS.SYS
mcopy -i pdosflop.img pcomm.exe ::COMMAND.EXE
