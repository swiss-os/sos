rem After running this script, you will have a "deblock module"
rem which can be copied to the E drive, like:
rem startcms
rem /copy deblock module a = = e (replace
rem
rem Then you can build an executable on the PC, e.g.
rem copy cms*.obj from https://pdos.org/obj.zip
rem don't need to copy pdp370.mac pdptop.mac
rem pdmake targ=cms -f makefile.370
rem copy pdptest.exe \vm380\io\hercules.dat
rem startcms
rem devinit 580 io/pctomf_bin.tdf
rem /att 580 * 181
rem /erase tmp-file packed
rem /filedef input tap1 (lrecl 0 blksize 32720 recfm u
rem /filedef output disk tmp-file packed
rem /movefile input output
rem /erase tmp-file unpacked
rem /deblock
rem /erase pdptest module
rem /copy tmp-file unpacked a pdptest module a

del deblock.zip
zip -0X deblock deblock.asm

rem Useful for VM/380
call runcms deblock.exec output.txt deblock.zip

rem Useful for z/VM
rem mvsendec encb deblock.zip deblock.dat
rem loc2ebc deblock.dat xfer.card 80
