rem Produces an MVS PE executable and then executes it

rem This uses MVS/380 to assemble the MVS assembler files
call mvsasm mvsstart.asm mvsstart.obj
call mvsasm mvssupa.asm mvssupa.obj

rem An alternative option is to use z390 to assemble them
rem which requires you to do the following
rem cd \z390_1.8.3
rem md mymacs
rem cd mymacs
rem unzip maclib.zip modgen.zip and apvtmacs.zip
rem which can be obtained from:
rem https://sourceforge.net/projects/mvs380/files/mvs380/MVS_380%202.0/
rem cd ..
rem copy pdptop.mac from pdpclib and rename to pdptop.cpy
rem copy mvsstart.asm and mvssupa.asm
rem bat\asm mvsstart sysmac(mymac)
rem bat\asm mvssupa sysmac(mymac)
rem now you should have mvsstart.obj and mvssupa.obj
rem technically identical to the above

pdmake -f makefile.370

sleep 2

call runmvs pdpmvs2.jcl output.txt pdptest.exe
