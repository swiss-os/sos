rem Produces a CMS executable (including RDWs) and then executes it

pdmake targ=cms -B -f makefile.370

rem This is useful for debugging:
rem pause

call runcms pdpcms2.exec output.txt pdptest.exe
