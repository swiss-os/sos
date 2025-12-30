#!/bin/sh

# mvsasm comes with MVS/380. However, you may
# prefer to use z390. See instructions for
# doing that in pdpmvs4.bat
# Alternatively you can assemble and extract the
# object code via some adhoc/manual method

mvsasm mvsstart.asm mvsstart.obj
mvsasm mvssupa.asm mvssupa.obj

pdmake -f makefile.370

runmvs pdpmvs2.jcl output.txt pdptest.exe
