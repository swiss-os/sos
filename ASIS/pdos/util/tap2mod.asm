* Copy a module with variable length records from tape to disk
* CMS modules can have record lengths up to 64K-1 you can't use
* OS emulation as this is limited to 32K-1.
*
* written by Dave Wade 23-11-2025 and placed in the public domain
*
* USAGE
*           TAP2MOD <module-name>
*
* Where
*           <module-name> is the name of the module.
*
* Limitations
*
*    1. IF <MODULE-NAME> IS OMITTED THEN IT DEFAULTS TMPMOD
*
*    2. If the output module exists things go tubesville arizona.
*
*        R1 points to the CMS tokenized parameter list:
*
*              DC CL8'our name'
*              DC CL8'Module-Name'     (optional)
*              DC XL8'FFFFFFFF'
*
         SPACE
TAP2MOD  CSECT
         USING *,15
BEGIN    SAVE (2,8),,T
BUFADDR  EQU   3                   Address of tape buffer
BUFSZ    EQU   4                   Size of BUFFER combo
MNAME    EQU   5                   Pointer to file name
BASE     EQU   7                   Base register
R0       EQU   0
R1       EQU   1
R8       EQU   8
R9       EQU   9
R15      EQU   15
*
         LR    BASE,R15            Move base register
         DROP  R15
         USING BEGIN,BASE
*
* SEE IF A PARMAMETER WAS ENTERED
*
* Looks ok, stuff it in the RDTAPE Plist.
*
         CLC   8(8,R1),=XL8'FFFFFFFFFFFFFFFF'    Is there a filename
         BE    NOPARM                            No skip
         MVC   FSPEC,8(R1)     Yes overwrite FSWITE block
NOPARM   DS    0H
*
* Obtain data buffer
*
         LA    0,=AL2(65536/8)     Length of 32K buffer
         DMSFREE DWORDS=(0)        Obtain it from CMS
         LR    BUFADDR,R1          Save buffer address
         LA    MNAME,FSPEC         Get address of File Spec
*
* Read that tape
*
RTAPE    RDTAPE (BUFADDR),65535    Read maximum record
         LTR   15,15               Now, just how did that go
         BZ    RDOK                Read was OK
         C     15,=F'2'            End of file ?
         BNE   NOTEOF              NO - ITS AN ERROR
         SR    R15,R15             YES - NORMAL RETURN
         B     GOBACK
*
*  ERROR RETURN CODE
*
NOTEOF   LR    R8,R15              RC TO R15
         LINEDIT TEXT='RC=.. FROM RDTAPE',SUB=(HEX,(R8))
         LR    R15,R8              Put error back
         B     GOBACK
*
RDOK     LR    BUFSZ,0             Save Bytes read
*        LINEDIT TEXT='BYTES READ .......',SUB=(HEX,(BUFSZ))
         FSWRITE (MNAME),BUFFER=(BUFADDR),BSIZE=(BUFSZ),RECFM=V
         LTR   R8,R15        RC to R8
         BZ    RTAPE         Write OK - read again
         LINEDIT TEXT='RC=.. FROM FSWRITE',SUB=(HEX,(R8))
         LR    R15,R8        Put error back
         B     GOBACK        Exit with error code
*
*
*--Return
GOBACK   EQU     *
         LR    R9,R15              Save return code from above
         LA    0,=AL2(65536/8)     Length of 32K buffer
         LR    R1,BUFADDR          Buffer Address
         DMSFRET DWORDS=(0),LOC=(1)   Give it back to CMS
         FSCLOSE (R8)              Close output file
         LR    R15,R9              Put RC from above back
         RETURN (2,8)
*
* SPACE FOR FILE NAME
*
FSPEC    DC     CL8'TMPMOD  '
         DC     CL8'MODULE  '
         DC     CL2'A1'
*
         LTORG
         SPACE 2
         END
