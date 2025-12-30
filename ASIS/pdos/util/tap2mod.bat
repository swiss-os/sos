rem After running this script, you will have a "tap2mod module"
rem which can be copied to the E drive, like:
rem startcms
rem /copy tap2mod module a = = e (replace
rem
rem Then you can build an executable on the PC, e.g.
rem copy cms*.obj from https://pdos.org/obj.zip
rem don't need to copy pdp370.mac pdptop.mac
rem pdmake targ=cms -f makefile.370
rem rlhtoaws pdptest.exe temp.aws
rem copy temp.aws \vm380\io
rem startcms
rem devinit 580 io/temp.aws
rem /att 580 * 181
rem /tap2mod
rem /copy tmpmod module a pdptest module a (replace

del tap2mod.zip
zip -0X tap2mod tap2mod.asm

rem Useful for VM/380
call runcms tap2mod.exec output.txt tap2mod.zip

rem Useful for z/VM
rem mvsendec encb tap2mod.zip tap2mod.dat
rem loc2ebc tap2mod.dat xfer.card 80
