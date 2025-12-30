*
* Build pdptest for MTS
*
* The commands used here are documented here:
* http://www.bitsavers.org/pdf/univOfMichigan/mts/volumes/
* MTSVol01-TheMichiganTerminalSystem-Nov1991.pdf
*
* Use with pdpmts.bat/.sh
*

$dest hercin.dat ok
$cre hercin.dat
* After this command is issued, on the Herc380 console type:
* /# OK TAPE1 T90B
$mount mts:TAPE1 9TP *PCTOMF*
$copy *PCTOMF* to hercin.dat
$release *PCTOMF*
* list hercin.dat with hex

* Test an old executable
* This relies on the input file above having
* 80-byte blocks, which is set in pctomf.tdf
* There might be a way of having an arbitrary block
* size for hercin.dat and then have it reblocked to
* 80 for oldexe.r, but I don't know it currently
$dest oldexe.r ok
$cre oldexe.r
$copy hercin.dat oldexe.r
$dest hercin.dat ok
$r oldexe.r par=abc def
$dest oldexe.r

* Mount output tape now, even though we won't
* write to it until the end of the job. To make
* it easier for the operator.
* The operator response is:
* /# OK TAPE2 T90C
$mount mts:TAPE2 9TP *MFTOPC* write=yes volume=MFTOPC recfm=u minsize=1

$dest one.asm ok
$cre one.asm
$copy *source* to one.asm
         CSECT
         PRINT GEN
* YREGS is not standard
*         YREGS
R0       EQU   0
R1       EQU   1
R2       EQU   2
R3       EQU   3
R4       EQU   4
R5       EQU   5
R6       EQU   6
R7       EQU   7
R8       EQU   8
R9       EQU   9
R10      EQU   10
R11      EQU   11
R12      EQU   12
R13      EQU   13
R14      EQU   14
R15      EQU   15
*
*
*
*
         ENTRY ONE
ONE      DS    0H
         SAVE  (14,12),,ONE
         LR    R12,R15
         USING ONE,R12
*
         LR    R5,R13
         LA    R13,SAVEAREA
         SPRINT 'Hello from ONE'
         SPRINT 'Hello again from ONE'
         CALL  TWO
         LR    R8,R15
         SPRINT 'Bye from ONE'
         LR    R15,R8
*
         LR    R13,R5
         RETURN (14,12),RC=(15)
         LTORG
*
SAVEAREA DS    18F
         END
$endfile

$dest two.asm ok
$cre two.asm
$copy *source* to two.asm
         CSECT
*
*
         ENTRY TWO
TWO      DS    0H
         USING *,7
         LR    7,15
         LR    4,13
         LA    13,SAVEAREA
         LR    3,14
         SPRINT 'Hello from TWO'
         LR    14,3
         LR    13,4
         LA    15,6
         BR    14
         LTORG
SAVEAREA DS    18F
         END
$endfile



*
* define a macro for repeated assemblies
*
>macro dobld n
>define srcf="{n}.asm"
>define runf="{n}.o"
>define listf="{n}.l"
>define errf="{n}.e"
>define rest="2=mtsmacs.mac par=test,size(20)"

$dest {listf} ok
$cr {listf}

$dest {errf} ok
$cr {errf}

$dest {runf} ok
$cre {runf}

$run *asmg scards={srcf} spunch={runf} sprint={listf} sercom={errf} {rest}

*li {listf} *print*
*li {errf} *print*

$dest {listf} ok
$dest {errf} ok

>endmacro



dobld one
dobld two

* We don't have enough disk space, so this is no longer available
* li two.l *print*

$dest pdptest.r
$cre pdptest.r

$copy one.o pdptest.r
$copy two.o pdptest.r(last+1)

filestatus ? type,lastchange,size,trunc,lines,avlen,maxlen,summary

* list one.o with hex

* list pdptest.r with hex

* The parameters are being uppercased and we need to call
* function PARSTR to get the original strings
$r pdptest.r par=ABD AbC

* Copy the executable onto tape
$copy pdptest.r to *MFTOPC*
$release *MFTOPC*
