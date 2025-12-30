***********************************************************************
*                                                                     *
*  This program written by Paul Edwards.                              *
*  Released to the public domain                                      *
*                                                                     *
*  Contributions from Louis Millon et al also public domain.          *
*                                                                     *
***********************************************************************
*                                                                     *
*  VSESUPA - Support routines for PDPCLIB under DOS/VSE               *
*                                                                     *
*  This assembler code has a long history - starting off as C/370     *
*  under MVS then modified for GCC, then ported to CMS, MUSIC/SP      *
*  and then finally VSE. A rewrite by someone with deep VSE           *
*  experience should be considered. Also, it will probably be         *
*  necessary at some point to introduce a flag to say whether it is   *
*  being built for z/VSE or DOS/VS R34, as new functionality like     *
*  the use of LABEL/LPL for dynamic file allocation shouldn't be      *
*  held back by the older DOS/VS. Perhaps dummy macros can be         *
*  created rather than a flag, but either way, z/VSE should never be  *
*  seriously compromised.                                             *
*                                                                     *
***********************************************************************
*
*
* LDINT macro
*
         MACRO ,             COMPILER DEPENDENT LOAD INTEGER
&NM      LDINT &R,&A         LOAD INTEGER VALUE FROM PARM LIST
         GBLC  &COMP         COMPILER GCC OR IBM C
&NM      L     &R,&A         LOAD PARM VALUE
         AIF ('&COMP' EQ 'GCC').MEND
.* THIS LINE IS FOR ANYTHING NOT GCC: IBM C
         L     &R,0(,&R)     LOAD INTEGER VALUE
.MEND    MEND  ,
*
*
*
         COPY  PDPTOP
*
         CSECT
         PRINT GEN
* REGEQU is not standard
*         REGEQU
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
***********************************************************************
*                                                                     *
*  AOPEN - Open a file                                                *
*                                                                     *
*  Parameters are:                                                    *
*  DDNAME - space-padded, 8 character DDNAME to be opened             *
*    Note that in VSE, the DDNAME may be expanded to be more than 8   *
*    bytes. It represents not just the 7-character filename on the    *
*    DLBL, but may also include recfm, lrecl and blksize info.        *
*    It is not expected that there is much call for that though,      *
*    so there are reasonable defaults.                                *
*    First we have a fairly fixed portion - e.g. SDO1, which is the   *
*    disk label, which is also the macro name, the typefle (I or O)   *
*    of the macro, and it's sequence number (currently statically     *
*    defined, but potentially it will be dynamic).                    *
*    All files are defined as RECFM=U, since that gives the program   *
*    the flexibility to decide how to treat it, and in DOS there is   *
*    no-one else who will disagree, with the info not stored in the   *
*    VTOC or catalog or DCB or anywhere else.                         *
*    The next bit of the DDNAME says how you want the file to be      *
*    internally treated. The default is RECFM=U which for input files *
*    is the maximum possible for a 3350, but on output it is a        *
*    figure that is more flexible for the sort of data that may be    *
*    stored - 6480 - a multiple of both 80 and 81, that fits on most  *
*    disk types, while still being over 90% efficient on a 3390.      *
*    Otherwise the user may specify FB80 which will treat the data    *
*    as F80 records, blocked to 6480, which depending on other things *
*    may trigger breakdown of records, stripping of blanks etc.       *
*    For output only, F80 may be specified to force the data to be    *
*    unblocked. It has no meaning (and is invalid) on input.          *
*    A similar situation exists for tapes.                            *
*    That's the theoretical input - sort of like an SDI1,FB,80,6480   *
*    In practice we don't yet have the ability to deblock, so any     *
*    FB80 file must in actual fact be F80.                            *
*  MODE - 0 = READ, 1 = WRITE, 2 = UPDATE (update not supported)      *
*  RECFM - 0 = F, 1 = V, 2 = U. This is an output from this function  *
*  LRECL - This function will determine the LRECL                     *
*  BLKSIZE - This function will determine the block size              *
*  ASMBUF - pointer to a 32K area which can be written to (only       *
*    needs to be set in move mode)                                    *
*  MEMBER - *pointer* to space-padded, 8 character member name.       *
*    If pointer is 0 (NULL), no member is requested                   *
*                                                                     *
*  Return value:                                                      *
*  An internal "handle" that allows the assembler routines to         *
*  keep track of what's what when READ etc are subsequently           *
*  called.                                                            *
*                                                                     *
*                                                                     *
*  Note - more documentation for this and other I/O functions can     *
*  be found halfway through the stdio.c file in PDPCLIB.              *
*                                                                     *
*                                                                     *
*                                                                     *
*  In the general case of an open of a disk file, ideally the         *
*  OPEN should allocate its storage area (ZDCBAREA - what "handle"    *
*  points to, and then it should copy the DTFSD into part of that     *
*  "DCB area" (it is called that for historical reasons and will      *
*  probably be renamed). The OPEN macro, using register notation,     *
*  points to that area, which will have first been modified to put    *
*  in the DDNAME (DLBL) being opened. This way we only need a         *
*  single DTFSD in the main code, which is reused any number of       *
*  times. However, at the moment we have simply assumed a small       *
*  number of files, which is sufficient to allow a C compile to go    *
*  through.                                                           *
*                                                                     *
*  The stdin/stdout/stderr are treated differently - each of those    *
*  has its own DTF, because they are special files (not disks).       *
*  The special files are SYSIPT, SYSLST and SYSLOG respectively.      *
*                                                                     *
*  Another technique that has been used is for accessing members of   *
*  a PDS - they are assumed to be in the CIL, and loaded, then        *
*  data is read from them as if it was a RECFM=U dataset.             *
*  It is expected that this technique will be expanded in the future  *
*  to also allow a similar operation from a source statement          *
*  library.                                                           *
*                                                                     *
*  Also note that the C code is totally flexible in that it will      *
*  do whatever this assembler code tells it to. ie you can set any    *
*  file to any RECFM/LRECL and it will do its work based on that.     *
*  This makes it possible to change anything in here that isn't       *
*  working to your satisfaction, without needing to change the C      *
*  code at all.                                                       *
*                                                                     *
***********************************************************************
         ENTRY @@AOPEN
@@AOPEN  DS    0H
         SAVE  (14,12),,@@AOPEN
         LR    R12,R15
         USING @@AOPEN,R12
         LR    R11,R1
         L     R0,=A(ZDCBLEN)
         AIF   ('&ZSYS' EQ 'S390').BELOW
* USE DEFAULT LOC=RES for S/370 and S/380
         GETVIS
         AGO   .CHKBLWE
.BELOW   ANOP
         GETVIS LOC=BELOW
.CHKBLWE ANOP
         ST    R13,4(R1)
         ST    R1,8(R13)
         LR    R13,R1
         LR    R1,R11
         USING WORKAREA,R13
*
         L     R3,0(R1)           R3 POINTS TO DDNAME
         L     R6,4(R1)
         LDINT R6,0(R6)           R6 now has value of mode
* 08(,R1) has RECFM
* Note that R5 is used as a scratch register
         L     R8,12(,R1)         R8 POINTS TO LRECL
* 16(,R1) has BLKSIZE
* 20(,R1) has ASMBUF pointer
*
         LA    R9,0
         ST    R9,ISMEM
         ST    R9,ISDI
         L     R9,24(,R1)         R9 POINTS TO MEMBER NAME (OF PDS)
         LA    R9,0(,R9)          Strip off high-order bit or byte
*
         LR    R2,R13             Access DCB
         LA    R2,WORKLEN(R2)     Point past save area
         LR    R0,R2              Load output DCB area address
         L     R1,=A(ZDCBLEN)     Load output length of DCB area
         S     R1,=A(WORKLEN)     Adjust for save area
         LR    R5,R11             Preserve parameter list
         LA    R11,0              Pad of X'00' and no input length
         MVCL  R0,R10             Clear DCB area to binary zeroes
         LR    R11,R5             Restore parameter list
* R5 free again
*
*
         LTR   R6,R6
         BNZ   WRITING
*
* So now we're doing the reading code
*
* Something like RDJFCB would be good here, if VSE has such a thing
*
         LTR   R9,R9
         BZ    NOMEM
*
* Although VSE doesn't have PDSes with members, it has something
* similar - libraries. It is actually the Core Image library that
* is the most flexible, allowing binary data to be stored.
* Unfortunately this can't be directly read or written! But what
* we can do is use LNKEDT to build a module, then load it later,
* to be read as a file.
*
         ST    R9,ISMEM
         MVC   MEMBER24,0(R9)
         LA    R9,=C'OPEN    '
         ST    R9,P1VF
         LA    R9,MEMBER24
         ST    R9,P2VF
         LA    R1,PMVF
         CALL  @@VSEFIL
*
* We should be able to have 32k records here
         L     R6,=F'19069'   +++ hardcode to 19069
         ST    R6,DCBLRECL
         LA    R6,2           +++ hardcode to recfm=U
         ST    R6,DCBRECFM
         B     DONEOPEN
NOMEM    DS    0H
*
* Normal datasets just need to be opened - but unfortunately
* we don't know what their DCB info is. What we basically do
* to get around that problem is to hardcode DCB info based on
* the DDNAME. There are various techniques that could be used
* to work around this limitation, and one should be implemented.
*
* We use the register notation, because other than the standard
* files, all files will read/write data from a field in ZDCBAREA
* rather than a variable defined in this CSECT.
*
         CLC   0(8,R3),=C'SYSIN   '
         BNE   NOTSYSI
         LA    R6,80          +++ hardcode to 80
         ST    R6,DCBLRECL
         LA    R6,0           +++ hardcode to fixed
         ST    R6,DCBRECFM
         LA    R6,1
         ST    R6,ISDI   sysin is device-independent
         LA    R5,SYSIN
         ST    R5,PTRDTF
         OPEN  (R5)
         B     DONEOPEN
*
NOTSYSI  DS    0H
*
* All other files currently defined are RECFM=U
*
         L     R6,=F'19069'   +++ hardcode to 19069
         ST    R6,DCBLRECL
         LA    R6,2           +++ hardcode to recfm=U
         ST    R6,DCBRECFM
*
* Here we need to choose tape or disk
* There's probably a better way than looking at the name of
* the DD, to see if it starts with "MT", as a convention, 
* but of course it would be better if this was
* transparent to the programmer in the first place!
*
         CLC   0(2,R3),=C'MT'
         BNE   NOTTAP
         LA    R5,MTI1
         ST    R5,PTRDTF
         OPEN  (R5)
         B     DONEOPEN
*
NOTTAP   DS    0H
*
* Need to allow more input files, and DCB info
*
         CLC   0(8,R3),=C'SDI1FB80'
         BNE   NFB80I1
*
* Warning - either this assembler code, or the calling C program,
* should be made sophisticated enough to handle FB. But at the
* moment, such deblocking is not available, so although the
* syntax caters for FB, we actually only support F.
*
         LA    R6,0           +++ hardcode to recfm=F
         ST    R6,DCBRECFM
         L     R6,=F'80'      +++ hardcode to 80
         ST    R6,DCBLRECL
NFB80I1  DS    0H
         LA    R5,SDI1
         CLC   0(4,R3),=C'SDI1'
         BE    GOTSDI1
         LA    R5,SDI2        +++ assume SDI2
GOTSDI1  DS    0H
         ST    R5,PTRDTF
         OPEN  (R5)
         B     DONEOPEN
* Can't reach here, since all files are currently considered valid
         B     BADOPEN
*
*
*
WRITING  DS    0H
*
* Would be good if we could do a RDJFCB here to get DCB info.
* Instead, we just assume it from the DD name.
*
* Writing to a member of a library is not directly supported in VSE,
* and the workaround for this situation is done outside of this
* assembler code, so nothing to see here folks!
*
* We use the register notation, because other than the standard
* files, all files will read/write data from a field in ZDCBAREA
* rather than a variable defined in this CSECT.
*
WNOMEM   DS    0H
         CLC   0(8,R3),=C'SYSPRINT'
         BNE   NOTSYSPR
         LA    R6,120         lrecl = 120
         ST    R6,DCBLRECL
         LA    R6,0           recfm = fixed
         ST    R6,DCBRECFM
         LA    R6,1
         ST    R6,ISDI   sysprint is device-independent
         L     R6,DCBLRECL
         LA    R5,SYSPRT
         ST    R5,PTRDTF
         OPEN  (R5)
         B     DONEOPEN
*
NOTSYSPR DS    0H
         CLC   0(8,R3),=C'SYSTERM '
         BNE   NOTSYST
         LA    R6,80          +++ hardcode to 80
         ST    R6,DCBLRECL
         LA    R6,0           +++ hardcode to fixed
         ST    R6,DCBRECFM
         L     R6,DCBLRECL
         LA    R5,SYSTRM
         ST    R5,PTRDTF
         OPEN  (R5)
         B     DONEOPEN
*
NOTSYST  DS    0H
         CLC   0(8,R3),=C'SYSPUNCH'
         BNE   NOTSYSPU
         LA    R6,80          lrecl = 80
         ST    R6,DCBLRECL
         LA    R6,0           recfm = fixed
         ST    R6,DCBRECFM
         LA    R6,1
         ST    R6,ISDI   syspunch is device-independent
         L     R6,DCBLRECL
         LA    R5,SYSPCH
         ST    R5,PTRDTF
         OPEN  (R5)
         B     DONEOPEN
*
NOTSYSPU DS    0H
*
* We should really make this smart enough to be allocated to
* any SDO file, and for it to pick up the LRECL as well.
*
         CLC   0(8,R3),=C'SDO1F80 '
         BNE   NOTF80O1
         LA    R6,80          +++ hardcode to 80
         ST    R6,DCBLRECL
         LA    R6,0           +++ hardcode to fixed
         ST    R6,DCBRECFM
         L     R6,DCBLRECL
         LA    R5,SDO1
         ST    R5,PTRDTF
         OPEN  (R5)
         B     DONEOPEN
*
NOTF80O1 DS    0H
*
* Assume RECFM=U
* Note that output files can't really use up to the full 19069
* and 18452 is a better match for a 3390 anyway. However, this
* is set to 80 * 81 for ease of use by other programs.
* Also note that we need to cater for SDO2 etc too
*
         L     R6,=F'6480'    +++ hardcode to 6480
         ST    R6,DCBLRECL
         LA    R6,2           +++ hardcode to undefined
         ST    R6,DCBRECFM
         L     R6,DCBLRECL
*
*
* Here we need to choose tape or disk. Actually only MTO1 is
* currently supported, but we don't check for that.
*
         CLC   0(2,R3),=C'MT'
         BNE   NOTTAPW
         LA    R5,MTO1
         ST    R5,PTRDTF
         OPEN  (R5)
         B     DONEOPEN
*
*
*
NOTTAPW  DS    0H
         LA    R5,SDO1
         ST    R5,PTRDTF
         OPEN  (R5)
         B     DONEOPEN
* Can't reach here, since all files are currently considered valid
         B     BADOPEN
*
*
*
*
DONEOPEN DS    0H
*
* We've done the open (read or write), and now need to allocate a 
* buffer that the C code can write to (or in the case of read,
* that the assembler code can use). The buffer needs to be below the
* line, so it's simpler if the assembler code allocates it on
* behalf of the C caller. We should really allocate a buffer size
* based on what is actually required rather than this hardcoded
* maximum possible.
*
         L     R6,=F'32768'
*
* S/370 can't handle LOC=BELOW
*
         AIF   ('&ZSYS' EQ 'S390').MVT8090  If not 390
         GETVIS LENGTH=(R6)  Use default LOC=RES for S/370 and S/380
         AGO   .GETOENE
.MVT8090 ANOP  ,                  S/390
         GETVIS LENGTH=(R6),LOC=BELOW
.GETOENE ANOP
*
* Give this buffer pointer back to caller
         ST    R1,ASMBUF
         L     R5,20(,R11)        R5 points to ASMBUF
         ST    R1,0(R5)           save the pointer
* Note that in the case of read, the caller doesn't need to know
* the address (something appropriate is returned in the read
* function - and appropriate means that the assembler may have
* deblocked the records and be pointing to that), but it seems 
* harmless to set the value anyway.
*
*
* Set other values that the caller needs to know
*
* The LRECL
         L     R6,DCBLRECL
         ST    R6,0(R8)
* The RECFM
         L     R6,DCBRECFM
         L     R5,8(,R11)         Point to RECFM
         ST    R6,0(R5)
* Now return success
         B     RETURNOP
*
*
* We failed to open the file, so free the allocated memory and
* return an error.
*
BADOPEN  DS    0H
         L     R0,=A(ZDCBLEN)
         LR    R1,R13
         L     R7,SAVEAREA+4
         FREEVIS
         L     R15,=F'-1'
         LR    R13,R7
         RETURN (14,12),RC=(15)
*
*
* Good return - handle is in ZDCBAREA, which is R13. So we don't
* want to free that memory!
*
RETURNOP DS    0H
         LR    R15,R13
         L     R13,SAVEAREA+4
         RETURN (14,12),RC=(15)
         LTORG
*
*
***********************************************************************
*                                                                     *
*  AREAD - Read from file                                             *
*                                                                     *
*  This function takes 3 parameters:                                  *
*                                                                     *
*  1. A handle (previously returned by AOPEN)                         *
*  2. A buffer pointer - this is an output variable - the assembler   *
*     routine will read the data and then inform the caller where     *
*     the data is located.                                            *
*  3. Length of data (also output).                                   *
*                                                                     *
***********************************************************************
         ENTRY @@AREAD
@@AREAD  DS    0H
         SAVE  (14,12),,@@AREAD
         LR    R12,R15
         USING @@AREAD,R12
         LR    R11,R1
*
         AIF ('&ZSYS' EQ 'S370').NOMOD1
         CALL  @@SETM24
.NOMOD1  ANOP
*
         L     R1,0(R1)         R1 CONTAINS HANDLE
         ST    R13,4(R1)
         ST    R1,8(R13)
         LR    R13,R1
         LR    R1,R11
         USING WORKAREA,R13
*
         L     R3,4(R1)         R3 POINTS TO BUF POINTER
         L     R4,8(R1)         R4 points to a length
*
* See if this is a library file
*
         L     R9,ISMEM
         LTR   R9,R9
         BNZ   GMEM
*
* For non-library files, we read into an internal buffer that
* was allocated earlier and is pointed to by the zdcbarea. Set 
* that fact immediately.
*
         L     R5,ASMBUF
         ST    R5,0(R3)
*
* The DTF macro is expecting to get the maximum length in R8
*
         L     R8,DCBLRECL
         L     R7,PTRDTF
*
         L     R9,ISDI            Is this device-independent?
         LTR   R9,R9
         BNZ   GDIR
*
* Normal file. GET needs the DTF pointer, the buffer, and our
* DTF is expecting the length in R8
*
         GET   (R7),(R5)
         B     DONEGET
*
* Got a device-indepentent DTF - we only support a RECSIZE of 80,
* and do not support a file containing an intiial control 
* character, so if you have such a file you will need to trim
* it down using a separate utility first.
*
GDIR     DS    0H          Got a device-independent
         GET   (R7)
         LA    R8,80     +++ hardcoded length of 80
         MVC   0(80,R5),IO1  +++ hardcode IO1 and length
DONEGET  DS    0H
* If GET reaches EOF, the "GOTEOF" label will be branched to
* automatically.
         LA    R15,0             SUCCESS
         ST    R8,0(R4)          store length actually read
         B     FINFIL
*
* This is a library file, so we need to call VSEFIL
*
GMEM     DS    0H                got member
         LA    R9,=C'GET     '
         ST    R9,P1VF
         LA    R9,MEMBER24
         ST    R9,P2VF
* Let VSEFIL directly set our caller's parameters
         ST    R3,P3VF
         ST    R4,P4VF
         LA    R1,PMVF
         CALL  @@VSEFIL
         L     R9,0(R4)
         LTR   R9,R9
         BNZ   FINFIL
         B     GOTEOF
GOTEOF   DS    0H
         LA    R15,1             FAIL
FINFIL   DS    0H
*
RETURNAR DS    0H
         LR    R1,R13
         L     R13,SAVEAREA+4
*
         AIF ('&ZSYS' EQ 'S370').NOMOD2
         LR    R7,R15            Preserve R15 over call
         CALL  @@SETM31
         LR    R15,R7
.NOMOD2  ANOP
*
         RETURN (14,12),RC=(15)
         LTORG
*
*
*
***********************************************************************
*                                                                     *
*  AWRITE - Write to file                                             *
*                                                                     *
*  This function takes 3 parameters:                                  *
*                                                                     *
*  1. A handle (previously returned by AOPEN)                         *
*  2. Address of buffer to be written (also previously obtained       *
*     from AOPEN).                                                    *
*  3. Length of data to be written (which may be ignored for a file   *
*     that is of an expected length, e.g. fixed 80)                   *
*                                                                     *
***********************************************************************
         ENTRY @@AWRITE
@@AWRITE DS    0H
         SAVE  (14,12),,@@AWRITE
         LR    R12,R15
         USING @@AWRITE,R12
         LR    R11,R1             SAVE
*
         AIF   ('&ZSYS' NE 'S380').N380WR1
         CALL  @@SETM24
.N380WR1 ANOP
*
         L     R1,0(R1)           R1 IS NOW HANDLE
         ST    R13,4(,R1)
         ST    R1,8(,R13)
         LR    R13,R1
         LR    R1,R11             RESTORE
         USING WORKAREA,R13
*
         L     R2,0(,R1)          R2 contains GETMAINed address
         L     R3,4(,R1)          R3 points to the record address
         L     R3,0(,R3)          R3 now has actual buffer address
         L     R8,8(,R1)          R8 points to the length
         L     R8,0(,R8)          R8 now has actual length
*
         L     R5,PTRDTF
         L     R9,ISDI            Is this device-independent?
         LTR   R9,R9
         BNZ   GDIW
*
* Normal file. PUT needs the DTF pointer, the buffer, and our
* DTF is expecting the length in R8 (unless the DTF is fixed)
*
         PUT   (R5),(R3)
         B     DONEPUT
*
* Got a device-independent DTF (which requires a control character)
*
GDIW     DS    0H
         EX    R8,WRMOVE
         MVI   IO1,C' '          space seems universal rather than V/W
         PUT   (R5)
*
* We have written to file, but should really check for any error
*
DONEPUT  DS    0H
*
         AIF   ('&ZSYS' NE 'S380').N380WR2
         CALL  @@SETM31
.N380WR2 ANOP
*
         L     R13,4(R13)
         LA    R15,0             +++ hardcode success
         RETURN (14,12),RC=(15)
WRMOVE   MVC   IO1+1(0),0(R3)    +++ hardcode IO1
         LTORG
*
***********************************************************************
*                                                                     *
*  ACLOSE - Close file                                                *
*                                                                     *
*  This routine takes a single parameter - a handle as given by the   *
*  (successful) return from AOPEN.                                    *
*                                                                     *
***********************************************************************
         ENTRY @@ACLOSE
@@ACLOSE DS    0H
         SAVE  (14,12),,@@ACLOSE
         LR    R12,R15
         USING @@ACLOSE,R12
         LR    R11,R1           SAVE
*
* The CLOSE appears to be abending when called in 31-bit mode,
* despite it being an SVC. So we need to switch to 24-bit mode
         AIF   ('&ZSYS' NE 'S380').N380CL1
         CALL  @@SETM24
.N380CL1 ANOP
*
         L     R1,0(R1)         R1 CONTAINS HANDLE
         ST    R13,4(R1)
         ST    R1,8(R13)
         LR    R13,R1
         LR    R1,R11
         USING WORKAREA,R13
*
*
         L     R5,ASMBUF
         LTR   R5,R5
         BZ    NFRCL
         L     R6,=F'32768'     +++ hardcode length of ASMBUF
         FREEVIS LENGTH=(R6),ADDRESS=(R5)
NFRCL    DS    0H
*
*
         L     R5,PTRDTF        Get DTF
         LTR   R5,R5
         BZ    NOTOPEN
         L     R9,ISMEM         Is this a library member?
         LTR   R9,R9
         BNZ   GMEM2
*
* Normal file - just do a close.
*
         CLOSE (R5)
         B     DONECLOS
*
* We have a library member, so call VSEFIL to close
*
GMEM2    DS    0H
         LA    R9,=C'CLOSE   '
         ST    R9,P1VF
         LA    R9,MEMBER24
         ST    R9,P2VF
         LA    R1,PMVF
         CALL  @@VSEFIL
         B     DONECLOS
*
* We probably shouldn't have a specific detection for a close
* of a file that is not open, as it's a logic error regardless.
*
NOTOPEN  DS    0H
         LA    R15,1
         B     RETURNAC
*
* We should have some error detection here, but for now, just
* set success unconditionally
*
DONECLOS DS    0H
         LA    R15,0
*
RETURNAC DS    0H
         LR    R1,R13
         L     R13,SAVEAREA+4
         LR    R7,R15
         L     R0,=A(ZDCBLEN)
         FREEVIS
*
         AIF   ('&ZSYS' NE 'S380').N380CL2
         CALL  @@SETM31
.N380CL2 ANOP
*
         LR    R15,R7
         RETURN (14,12),RC=(15)
         LTORG
*
*
*
* Note that a lot of these macros use the same storage buffer,
* because by their nature, the C caller will always read or
* write an entire block at a time.
*
*
* This is for reading from stdin
SYSIN    DTFDI DEVADDR=SYSIPT,IOAREA1=IO1,RECSIZE=80,EOFADDR=GOTEOF
*
* This is for writing to SYSPUNCH in a device-independent manner
* Note that it is a requirement to allow for a control character
SYSPCH   DTFDI DEVADDR=SYSPCH,IOAREA1=IO1,RECSIZE=81
*
* This is for writing to stdout (SYSPRINT)
SYSPRT   DTFDI DEVADDR=SYSLST,IOAREA1=IO1,RECSIZE=121
*
* This is for writing to stderr (SYSTERM)
SYSTRM   DTFPR CONTROL=YES,BLKSIZE=80,DEVADDR=SYS005,MODNAME=PRINTMOD, X
               IOAREA1=IO1,RECFORM=FIXUNB,WORKA=YES
PRINTMOD PRMOD CONTROL=YES,RECFORM=FIXUNB,WORKA=YES
*
* This is for reading from a sequential disk file
SDI1     DTFSD BLKSIZE=19069,DEVADDR=SYS000,DEVICE=3350,               X
               IOAREA1=WORKI1,RECFORM=UNDEF,WORKA=YES,                 X
               TYPEFLE=INPUT,RECSIZE=(8),EOFADDR=GOTEOF
*
* Another SD
SDI2     DTFSD BLKSIZE=19069,DEVADDR=SYS000,DEVICE=3350,               X
               IOAREA1=WORKI1,RECFORM=UNDEF,WORKA=YES,                 X
               TYPEFLE=INPUT,RECSIZE=(8),EOFADDR=GOTEOF
*
* This is for writing to a sequential disk file
SDO1     DTFSD BLKSIZE=19069,DEVICE=3350,                              X
               IOAREA1=WORKO1,RECFORM=UNDEF,WORKA=YES,                 X
               TYPEFLE=OUTPUT,RECSIZE=(8)
*
* This is for reading from a tape
MTI1     DTFMT BLKSIZE=19069,DEVADDR=SYS011,MODNAME=MTMOD,             X
               IOAREA1=WORKI1,RECFORM=UNDEF,WORKA=YES,FILABL=NO,       X
               TYPEFLE=INPUT,RECSIZE=(8),EOFADDR=GOTEOF
*
* This is for writing to a tape
MTO1     DTFMT BLKSIZE=19069,DEVADDR=SYS011,MODNAME=MTMOD,             X
               IOAREA1=WORKO1,RECFORM=UNDEF,WORKA=YES,FILABL=STD,      X
               TYPEFLE=OUTPUT,RECSIZE=(8)
*
* For some reason this MOD can be shared by both input and
* output, and in fact, there's not much choice, because otherwise
* we get duplicate symbols.
MTMOD    MTMOD WORKA=YES,RECFORM=UNDEF
*
* For the standard files, this is sufficient for input and output
IO1      DS    CL200
*
*
*
* This is pretty crappy - storing large variables in the CSECT
* instead of the dynamically-allocated DSECT. But at least the
* fact that they are being shared makes it not so bad.
* An extra 100 bytes to be helpful.
WORKI1   DS    CL32767
WORKO1   DS    CL32767
*
*
***********************************************************************
*                                                                     *
*  GETM - GET MEMORY                                                  *
*                                                                     *
***********************************************************************
         ENTRY @@GETM
@@GETM   DS    0H
         SAVE  (14,12),,@@GETM
         LR    R12,R15
         USING @@GETM,R12
*
         LDINT R3,0(,R1)          LOAD REQUESTED STORAGE SIZE
         LR    R4,R3
         LA    R3,8(,R3)
*
* To avoid fragmentation, round up size to 64 byte multiple
*
         A     R3,=A(64-1)
         N     R3,=X'FFFFFFC0'
*
         AIF   ('&ZSYS' NE 'S380').N380GM1
*
* When in 380 mode, we need to keep the program below the
* line, but we have the ability to use storage above the
* line, and this is where we get it, with the LOC=ANY parameter.
* For other environments, the default LOC=RES is fine.
*
         GETVIS LENGTH=(R3),LOC=ANY
         AGO   .N380GM2
.N380GM1 ANOP
         GETVIS LENGTH=(R3)
.N380GM2 ANOP
*
         LTR   R15,R15
         BZ    GOODGM
         LA    R15,0
         B     RETURNGM
GOODGM   DS    0H
* WE STORE THE AMOUNT WE REQUESTED FROM VSE INTO THIS ADDRESS
         ST    R3,0(R1)
* AND JUST BELOW THE VALUE WE RETURN TO THE CALLER, WE SAVE
* THE AMOUNT THEY REQUESTED
         ST    R4,4(R1)
         A     R1,=F'8'
         LR    R15,R1
*
RETURNGM DS    0H
         RETURN (14,12),RC=(15)
         LTORG
*
***********************************************************************
*                                                                     *
*  FREEM - FREE MEMORY                                                *
*                                                                     *
***********************************************************************
         ENTRY @@FREEM
@@FREEM  DS    0H
         SAVE  (14,12),,@@FREEM
         LR    R12,R15
         USING @@FREEM,R12
*
         L     R2,0(,R1)
         S     R2,=F'8'
         L     R3,0(,R2)
*
         FREEVIS LENGTH=(R3),ADDRESS=(R2)
*
RETURNFM DS    0H
         RETURN (14,12),RC=(15)
         LTORG
*
***********************************************************************
*                                                                     *
*  GETCLCK - GET THE VALUE OF THE MVS CLOCK TIMER AND MOVE IT TO AN   *
*  8-BYTE FIELD.  THIS 8-BYTE FIELD DOES NOT NEED TO BE ALIGNED IN    *
*  ANY PARTICULAR WAY.                                                *
*                                                                     *
*  E.G. CALL 'GETCLCK' USING WS-CLOCK1                                *
*                                                                     *
*  THIS FUNCTION ALSO RETURNS THE NUMBER OF SECONDS SINCE 1970-01-01  *
*  BY USING SOME EMPERICALLY-DERIVED MAGIC NUMBERS                    *
*                                                                     *
***********************************************************************
         ENTRY @@GETCLK
@@GETCLK DS    0H
         SAVE  (14,12),,@@GETCLK
         LR    R12,R15
         USING @@GETCLK,R12
*
         L     R2,0(,R1)
         STCK  0(R2)
         L     R4,0(,R2)
         L     R5,4(,R2)
         SRDL  R4,12
         SL    R4,=X'0007D910'
         D     R4,=F'1000000'
         SL    R5,=F'1220'
         LR    R15,R5
*
RETURNGC DS    0H
         RETURN (14,12),RC=(15)
         LTORG
*
*
*
**********************************************************************
*                                                                    *
*  GETAM - get the current AMODE                                     *
*                                                                    *
*  This function returns 24 if we are running in exactly AMODE 24,   *
*  31 if we are running in exactly AMODE 31, and 64 for anything     *
*  else (user-defined/infinity/16/32/64/37)                          *
*                                                                    *
*  Be aware that MVS 3.8j I/O routines require an AMODE of exactly   *
*  24 - nothing more, nothing less - so applications are required    *
*  to ensure they are in AM24 prior to executing any I/O routines,   *
*  and then they are free to return to whichever AMODE they were in  *
*  previously (ie anything from 17 to infinity), which is normally   *
*  done using a BSM to x'01', although this instruction was not      *
*  available in S/370-XA so much software does a BSM to x'80'        *
*  instead of the user-configurable x'01', which is unfortunate.     *
*                                                                    *
*  For traditional reasons, people refer to 24, 31 and 64, when what *
*  they should really be saying is 24, 31 and user-defined.          *
*                                                                    *
**********************************************************************
         ENTRY @@GETAM
@@GETAM  DS    0H
         SAVE  (14,12),,@@GETAM
         LR    R12,R15
         USING @@GETAM,R12
*
         L     R2,=X'C1800000'
         LA    R2,0(,R2)
         CLM   R2,B'1100',=X'0080'
         BE    GAIS24
         CLM   R2,B'1000',=X'41'
         BE    GAIS31
         LA    R15,64
         B     RETURNGA
GAIS24   DS    0H
         LA    R15,24
         B     RETURNGA
GAIS31   LA    R15,31
*
RETURNGA DS    0H
         RETURN (14,12),RC=(15)
         LTORG ,
         SPACE 2
*
*
*
***********************************************************************
*                                                                     *
*  LOAD - load a module into memory                                   *
*                                                                     *
*  parm1 = program name                                               *
*  parm2 = memory address                                             *
*                                                                     *
*  entry point address returned in R15                                *
*                                                                     *
*  Not currently used, but it might be!                               *
*                                                                     *
***********************************************************************
         ENTRY @@LOAD
@@LOAD   DS    0H
         SAVE  (14,12),,@@LOAD
         LR    R12,R15
         USING @@LOAD,R12
*
         L     R2,0(,R1)
         L     R3,4(,R1)
         LOAD  (R2),(R3)
         LR    R15,R1
*
RETURNLD DS    0H
         RETURN (14,12),RC=(15)
         LTORG
*
***********************************************************************
*                                                                     *
*  SYSTEM - execute another command                                   *
*                                                                     *
*  Not currently implemented, but ideally should be                   *
*                                                                     *
***********************************************************************
         ENTRY @@SYSTEM
@@SYSTEM DS    0H
         SAVE  (14,12),,@@SYSTEM
         LR    R12,R15
         USING @@SYSTEM,R12
         LR    R11,R1
*
*         GETVIS LENGTH=SYSTEMLN,SP=SUBPOOL
         ST    R13,4(,R1)
         ST    R1,8(,R13)
         LR    R13,R1
         LR    R1,R11
         USING SYSTMWRK,R13
*
         MVC   CMDPREF,FIXEDPRF
         L     R2,0(R1)
         CL    R2,=F'200'
         BL    LENOK
         L     R2,=F'200'
LENOK    DS    0H
         STH   R2,CMDLEN
         LA    R4,CMDTEXT
         LR    R5,R2
         L     R6,4(R1)
         LR    R7,R2
         MVCL  R4,R6
         LA    R1,CMDPREF
*         SVC   $EXREQ
*
RETURNSY DS    0H
         LR    R1,R13
         L     R13,SYSTMWRK+4
*         FREEMAIN RU,LV=SYSTEMLN,A=(1),SP=SUBPOOL
*
         LA    R15,0
         RETURN (14,12),RC=(15)
* For documentation on this fixed prefix, see SVC 221
* documentation.
FIXEDPRF DC    X'7F01E000000000'
         LTORG
SYSTMWRK DSECT ,             MAP STORAGE
         DS    18A           OUR OS SAVE AREA
CMDPREF  DS    CL8           FIXED PREFIX
CMDLEN   DS    H             LENGTH OF COMMAND
CMDTEXT  DS    CL200         COMMAND ITSELF
SYSTEMLN EQU   *-SYSTMWRK    LENGTH OF DYNAMIC STORAGE
         CSECT ,
*
*
*
***********************************************************************
*                                                                     *
*  DBGMSG - print a debug message for debugging purposes              *
*                                                                     *
***********************************************************************
         ENTRY @@DBGMSG
@@DBGMSG DS    0H
         SAVE  (14,12),,@@DBGMSG
         LR    R12,R15
         USING @@DBGMSG,R12
*
         EXCP  CCB
         WAIT  CCB
         B     BYPASS1
ERRMSG   DC    C'DEBUG MESSAGE'
         DS    0F
CCB      CCB   SYSLOG,CCW
CCW      CCW   X'09',ERRMSG,0,L'ERRMSG
BYPASS1  DS    0H
         LA    R15,0
*
         RETURN (14,12),RC=(15)
         LTORG
*
*
*
***********************************************************************
*                                                                     *
*  IDCAMS - dummy function to keep VSE happy                          *
*                                                                     *
***********************************************************************
         ENTRY @@IDCAMS
@@IDCAMS DS    0H
         SAVE  (14,12),,@@IDCAMS
         LR    R12,R15
         USING @@IDCAMS,R12
*
         LA    R15,0
*
         RETURN (14,12),RC=(15)
         LTORG
*
***********************************************************************
*                                                                     *
*  DYNAL - dummy function to keep VSE happy                           *
*                                                                     *
***********************************************************************
         ENTRY @@DYNAL
@@DYNAL  DS    0H
         SAVE  (14,12),,@@DYNAL
         LR    R12,R15
         USING @@DYNAL,R12
*
         LA    R15,0
*
         RETURN (14,12),RC=(15)
         LTORG
*
*
***********************************************************************
*                                                                     *
*  APOINT - dummy function to keep VSE happy                          *
*                                                                     *
***********************************************************************
         ENTRY @@APOINT
@@APOINT DS    0H
         SAVE  (14,12),,@@APOINT
         LR    R12,R15
         USING @@APOINT,R12
*
         LA    R15,0
*
         RETURN (14,12),RC=(15)
         LTORG
*
*
***********************************************************************
*                                                                     *
*  ADCBA - dummy function to keep VSE happy                           *
*                                                                     *
***********************************************************************
         ENTRY @@ADCBA
@@ADCBA  DS    0H
         SAVE  (14,12),,@@ADCBA
         LR    R12,R15
         USING @@ADCBA,R12
*
         LA    R15,0
*
         RETURN (14,12),RC=(15)
         LTORG
*
*
***********************************************************************
*                                                                     *
*  GETEPF - dummy function to keep VSE happy                          *
*                                                                     *
***********************************************************************
         ENTRY @@GETEPF
@@GETEPF  DS    0H
         SAVE  (14,12),,@@GETEPF
         LR    R12,R15
         USING @@GETEPF,R12
*
         LA    R15,0
*
         RETURN (14,12),RC=(15)
         LTORG
*
*
***********************************************************************
*                                                                     *
*  SVC99 - dummy function to keep VSE happy                           *
*                                                                     *
***********************************************************************
         ENTRY @@SVC99
@@SVC99  DS    0H
         SAVE  (14,12),,@@SVC99
         LR    R12,R15
         USING @@SVC99,R12
*
         LA    R15,0
*
         RETURN (14,12),RC=(15)
         LTORG
*
*
*
**********************************************************************
*                                                                    *
*  These functions are normally resolved from system libraries.      *
*  They are known to be used, so we cannot define dummy functions    *
*  here. That means we can't link on the PC using pdld until these   *
*  or equivalent object code is found and put on the PC.             *
*  Also note that these functions technically violate the user's     *
*  namespace, so we need to document that the user needs to provide  *
*  a -Dijjpcizd=xxxx or whatever if they wish to have a function     *
*  named as such.                                                    *
*                                                                    *
**********************************************************************
*         ENTRY IJJFCIZD
*         USING IJJFCIZD,R15
*IJJFCIZD BR    R14
*         ENTRY IJJFCBZD
*         USING IJJFCBZD,R15
*IJJFCBZD  BR    R14
*         ENTRY IJGUIZZZ
*         USING IJGUIZZZ,R15
*IJGUIZZZ BR    R14
*         ENTRY IJGUOZZZ
*         USING IJGUOZZZ,R15
*IJGUOZZZ BR    R14
*
*
*
*
* Keep the below functions last because they use different
* base registers
*
         DROP  R12
*
*
*
* This is used by VSEFIL
*
TABDDN   DSECT
         USING     *,R9
DDN      DS        CL8
POINTER  DS        F
TABLEN   EQU       *-TABDDN
*
         CSECT
***********************************************************************
*                                                                     *
*  VSEFIL - contributed by Louis Millon                               *
*                                                                     *
*  Allows access to CIL in order to read RECFM=U binary files in a    *
*  PDS-like manner.                                                   *
*                                                                     *
*  CALL      @@VSEFIL,(OPEN,DDN)                                      *
*  CALL      @@VSEFIL,(GET,DDN,RECADDR,RECLEN)                        *
*  CALL      @@VSEFIL,(CLOSE,DDN)                                     *
*                                                                     *
*  "OPEN" etc must be CL8 with that string. DDN is CL8. Other two F   *
*                                                                     *
***********************************************************************
         ENTRY @@VSEFIL
@@VSEFIL DS    0H
         USING     *,R3
         SAVE      (14,12)
         LR        R3,R15
         LR        R10,R1
         B         DEBCODE
MAXFILE  EQU       200                           NUMBER OF FILES
*                                                WHICH MAY BE OPENED AT
*                                                THE SAME TIME
AREA     DC        (TABLEN*MAXFILE)X'00'
         DC        F'-1'                         END OF TABLE
FILENAME DS        CL8
DEBCODE  DS        0H
         L         R15,0(R10)                    FUNCTION
         CLC       =C'GET',0(R15)
         BE        GET
         CLC       =C'OPEN',0(R15)
         BE        OPEN
         CLC       =C'CLOSE',0(R15)
         BE        CLOSE
         RETURN    (14,12),RC=8                  INVALID FUNCTION
OPEN     DS        0H
         L         R15,4(R10)
         MVC       FILENAME,0(R15)               DDNAME
         LA        R9,AREA
         LA        R15,MAXFILE
LOOPOPEN DS        0H
         CLC       DDN,FILENAME
         BE        ALREADY                       THIS FILE IS ALREADY
*                                                OPENED
         LA        R9,TABLEN(R9)
         BCT       R15,LOOPOPEN                  THE FILE IS NOT OPEN
         LA        R9,AREA                       SEEK FOR A VACANT
         LA        R15,MAXFILE                   POSITION IN THE ARRAY
LOOPOPN2 DS        0H
         CLC       DDN,=8X'0'                    POSITION IS FREE?
         BE        OKOPEN                        YES
         LA        R9,TABLEN(R9)
         BCT       R15,LOOPOPN2                  NEXT OCCURENCE
         RETURN    (14,12),RC=12                 ARRAY IS FULL
ALREADY  RETURN    (14,12),RC=8                  FILE ALREADY OPENED
OKOPEN   DS        0H
         LA        R1,FILENAME
         CDLOAD    (1)
         ST        R0,POINTER
         LTR       R15,R15
         BZ        R15OK
         LNR       R15,R15
         RETURN    (14,12),RC=(15)              CDLOAD FAIL
R15OK    EQU       *
         MVC       DDN,FILENAME
         RETURN    (14,12),RC=0
CLOSE    DS        0H
         L         R15,4(R10)
         MVC       FILENAME,0(R15)
         LA        R9,AREA
         LA        R15,MAXFILE
LOOPCLOS DS        0H
         CLC       DDN,FILENAME
         BE        OKCLOSE
         LA        R9,TABLEN(R9)
         BCT       R15,LOOPCLOS
         RETURN    (14,12),RC=8                  DDNAME NOTFND IN ARRAY
OKCLOSE  DS        0H
         LA        R1,FILENAME
*
* This function is not available on DOS/VS, which is a real
* shame. It should probably be added to VSE/380 (at least as
* a dummy) and then reinstated, so that it produces better
* results on z/VSE.
*         CDDELETE  (1)                       REMOVE PHASE FROM GETV
         XC        DDN,DDN
         XC        POINTER,POINTER
         RETURN    (14,12),RC=0
GET      DS        0H
         LA        R15,FILENAME
         MVC       FILENAME,0(R15)
         LA        R9,AREA
         LA        R15,MAXFILE
LOOPGET  DS        0H
         CLC       DDN,FILENAME
         BE        OKGET
         LA        R9,TABLEN(R9)
         BCT       R15,LOOPGET
         RETURN    (14,12),RC=12                 DDNAME NOTFND IN ARRAY
OKGET    DS        0H
         L         R15,POINTER
         CLC       0(4,R15),=F'0'
         BNE       NOEOF
         RETURN    (14,12),RC=8                  EOF
NOEOF    DS        0H
         L         R14,POINTER
         L         R15,12(R10)
         MVC       0(4,R15),0(R14)               LENGTH OF RECORD
         LA        R14,4(R14)                    SKIP RECLEN
         L         R15,08(R10)
         ST        R14,0(R15)                    AADR OF RECORD
         L         R14,POINTER
         AL        R14,0(R14)                    SKIP RECORD
         LA        R14,4(R14)                    AND LENGTH
         ST        R14,POINTER                   NEXT RECORD
         RETURN    (14,12),RC=0
         LTORG
         DROP      R3
*
***********************************************************************
*                                                                     *
*  GETTZ - Get the offset from GMT in 1.048576 seconds                *
*                                                                     *
***********************************************************************
         ENTRY @@GETTZ
@@GETTZ  LA    R15,0
         BR    R14
*
***********************************************************************
*                                                                     *
*  SETJ - SAVE REGISTERS INTO ENV                                     *
*                                                                     *
***********************************************************************
         ENTRY @@SETJ
         USING @@SETJ,R15
@@SETJ   L     R15,0(R1)          get the env variable
         STM   R0,R14,0(R15)      save registers to be restored
         LA    R15,0              setjmp needs to return 0
         BR    R14                return to caller
         LTORG ,
*
***********************************************************************
*                                                                     *
*  LONGJ - RESTORE REGISTERS FROM ENV                                 *
*                                                                     *
***********************************************************************
         ENTRY @@LONGJ
         USING @@LONGJ,R15
@@LONGJ  L     R2,0(R1)           get the env variable
         L     R15,60(R2)         get the return code
         LM    R0,R14,0(R2)       restore registers
         BR    R14                return to caller
         LTORG ,
*
*
*
* Note that unlike MVS, CMS, MUSIC/SP and MTS, DOS/VS link in
* some subroutines, specifically IJJFCBZD, IJGUIZZZ IJGUOZZZ
* that become part of the final executable. As such, if IBM
* were to claim copyright of those object files (something
* like 2000 bytes of machine code), they could theoretically
* claim to own almost every DOS/VS to VSEn executable ever
* produced. However, since these routines originated from
* DOS/VS R34, which is believed to be in the public domain,
* there is almost no chance of that being possible. However,
* since they were undisputably authored by IBM, they could
* likely take you to court if they wanted to. You're screwed
* either way - either linking in their object code, or doing
* what I have done here, which is disassemble the object code
* (using the Waterloo disassembler in disasm.zip at
* http://csg.uwaterloo.ca/sdtp/watcutil/index.html
* )
* and then include that disassembled code in this source file,
* so that it is "more manageable" when it comes to using pdld.
*
* Also, in the long term, the plan is to decipher this fairly
* small amount of object code, to see the algorithm used that
* eventually calls the SVC. Even if they were to attempt to
* claim copyright, the algorithm is not copyrightable. It is
* theoretically patentable, but it is highly unlikely that this
* small amount of code was ever subject to a software patent,
* and even if it was, the patent would have expired DECADES ago,
* since patents only last 20 years, and this code was released
* in 1977 at the latest.
*
* When this code is replaced, it will be with C code, which is
* necessarily an independent work, since the original source
* code would have been written in assembler (I haven't attempted
* to find it - but it should be both available and theoretically
* public domain). My own C code will take away any possible
* "theoretical" from the equation, as although the algorithm is
* likely to be similar (and straightforward - not something that
* is likely to be patentable in the first place), the result will
* be something that is neither copyrighted nor patented. But I
* haven't done that body of work yet. Also note that there is no
* choice but to replace the IBM code at this level for what I
* want to do. Because what I want to do is CONDITIONALLY execute
* an SVC. On real DOS/VS I would do a real SVC, but when running
* under a flavor of PDOS-generic, I would instead provide a
* "callback" function, which the application is expected to
* execute (if provided), in lieu of doing a real SVC. That way
* I can override the SVCs, and not need privilege to install an
* SVC, and still be able to stand up a DOS/VS (or DOS/VSE)
* mini-clone.
*
* Note that the original object code had a type code with the
* high nibble set to x'F', so there was an x'F0' and x'F1'
* instead of the normal (and documented) x'00' and x'01'. This
* caused linking problems (with pdld) also, so this problem is
* also eliminated by including the disassembled object code here.
*
* Regardless, I attempted to contact IBM via an email address on
* their website, to see if they were going to attempt to claim
* ownership of this object code. The email bounced, so I posted
* the contents of the email in IBM-MAIN on 2025-11-20 to see if
* anyone had any comments (some IBM employees post there).
*
* I doubt that I would have gotten a sensible answer from IBM.
* They wouldn't want to devote resources to doing a somewhat
* silly thing with this ancient code, and would have just given
* a vague canned response that "all copyrighted IBM code is
* copyrighted", without answering the actual question about whether
* they consider this particular code to be subject to copyright.
*
*
* With the original disassembled code, I needed to have this
* EQU plus I needed to change some MVCK to MVC which was a guess.
* I need to clean up this code with reference to a hexdump of the
* object code.
*
* F0       EQU   0
*
*
*
*000000  02C5E2C4 40404040 40400010 40400001  .ESD      ..  ..
*000010  C9D1C7E4 C9E9E9E9 00000000 4000024D  IJGUIZZZ.... ..(
*000020  40404040 40404040 40404040 40404040                  
*000030  40404040 40404040 40404040 40404040                  
*000040  40404040 40404040 40404040 F0F0F0F1              0001
*
*000050  02E3E7E3 40000000 40400038 40400001  .TXT ...  ..  ..
*000060  0A320000 0A320000 47F0F02A 0A320000  .........00.....
*000070  0A320000 0A320000 C9D1C7E4 C9E9E9E9  ........IJGUIZZZ
*000080  3400FFFF D9E5FFFF 3400909D F2309180  ....RV......2.j.
*000090  10264780 F03E9110 40404040 F0F0F0F2  ....0.j.    0002
*
*0000A0  02E3E7E3 40000038 40400038 40400001  .TXT ...  ..  ..
*0000B0  10274710 F1629180 10494710 F0E89680  ....1.j.....0Yo.
*0000C0  10499200 10409200 10949292 108845D0  ..k.. k..mkk.h.}
*0000D0  F0FC9180 10024710 F0640A07 91011004  0.j.....0...j...
*0000E0  4710F162 91101015 40404040 F0F0F0F3  ..1.j...    0003
*
*0000F0  02E3E7E3 40000070 40400018 40400001  .TXT ...  ..  ..
*000100  4710F0B4 D2021061 1085D202 10591081  ..0.K../.eK....a
*000110  58901080 D2021081 40404040 40404040  ....K..a        
*000120  40404040 40404040 40404040 40404040                  
*000130  40404040 40404040 40404040 F0F0F0F4              0004
*
*000140  02E3E7E3 40000088 40400038 40400001  .TXT ..h  ..  ..
*000150  102D5090 102C9108 10644780 F09E45D0  ..&...j.....0..}
*000160  F0FC47F0 F0A69110 10154710 F096989D  0..00wj.....0oq.
*000170  F2304400 105C4400 105407FE 58901080  2....*..........
*000180  48C01086 18D018B9 40404040 F0F0F0F5  .{.f.}..    0005
*
*000190  02E3E7E3 400000C0 40400038 40400001  .TXT ..{  ..  ..
*0001A0  41A00100 1BCA47C0 F0D6D2FF D000B000  .......{0OK.}...
*0001B0  1ADA86BA F0C441CC 00FF44C0 F0E247F0  ..f.0D.....{0S.0
*0001C0  F074D200 D000B000 91081064 4710F05A  0.K.}...j.....0!
*0001D0  91101015 4780F056 40404040 F0F0F0F6  j.....0.    0006
*
*0001E0  02E3E7E3 400000F8 40400018 40400001  .TXT ..8  ..  ..
*0001F0  47F0F05A 95001094 4770F108 45C0F1FA  .00!n..m..1..{1.
*000200  4890104A 41990001 40404040 40404040  .....r..        
*000210  40404040 40404040 40404040 40404040                  
*000220  40404040 40404040 40404040 F0F0F0F7              0007
*
*000230  02E3E7E3 40000110 40400038 40400001  .TXT ...  ..  ..
*000240  49901096 4720F11C 40901096 D5011096  ...o..1. ..oN..o
*000250  F2224770 F12A9208 1097D500 10471093  2...1.k..pN....l
*000260  4780F13E D5031090 10364770 F1529501  ..1.N.......1.n.
*000270  10944770 F1529512 40404040 F0F0F0F8  .m..1.n.    0008
*
*000280  02E3E7E3 40000148 40400038 40400001  .TXT ...  ..  ..
*000290  10884780 F1989212 1088D201 10861096  .h..1qk..hK..f.o
*0002A0  D204103C 10900A00 07FD9001 F24494EF  K...........2.m.
*0002B0  102750D0 F224989D F2304100 F2484110  ..&}2.q.2...2...
*0002C0  F21A0A02 9801F244 40404040 F0F0F0F9  2...q.2.    0009
*
*0002D0  02E3E7E3 40000180 40400018 40400001  .TXT ...  ..  ..
*0002E0  909DF230 58D0F224 91201010 4710F0A6  ..2..}2.j.....0w
*0002F0  92001040 47F0F104 40404040 40404040  k.. .01.        
*000300  40404040 40404040 40404040 40404040                  
*000310  40404040 40404040 40404040 F0F0F1F0              0010
*
*000320  02E3E7E3 40000198 40400038 40400001  .TXT ..q  ..  ..
*000330  92921088 41900004 48C01034 D203104C  kk.h.....{..K..<
*000340  109018AB 43A91043 43B9104B 15BA4770  .....z..........
*000350  F1C642C9 104B88C0 00084690 F1AA41BB  1F.I..h{....1...
*000360  000142B9 104BD203 40404040 F0F0F1F1  ......K.    0011
*
*000370  02E3E7E3 400001D0 40400038 40400001  .TXT ..}  ..  ..
*000380  103C104C 92001040 D5031036 104C47B0  ...<k.. N....<..
*000390  F1049108 10644780 F1629180 10264780  1.j.....1.j.....
*0003A0  F1629610 102747F0 F0A6D207 F2281080  1.o....00wK.2...
*0003B0  D2071080 10880A00 40404040 F0F0F1F2  K....h..    0012
*
*0003C0  02E3E7E3 40000208 40400018 40400001  .TXT ...  ..  ..
*0003D0  91801002 4710F212 0A07D207 1080F228  j.....2...K...2.
*0003E0  07FC5B5B C2D6D7C5 40404040 40404040  ..$$BOPE        
*0003F0  40404040 40404040 40404040 40404040                  
*000400  40404040 40404040 40404040 F0F0F1F3              0013
*
*000410  02E3E7E3 40000220 4040002D 40400001  .TXT ...  ..  ..
*000420  D5400000 00000000 00000000 00000000  N ..............
*000430  00000000 00000000 00000000 00000000  ................
*000440  00000000 00000000 00000000 FF404040  .............   
*000450  40404040 40404040 40404040 F0F0F1F4              0014
*
*000460  02C5D5C4 40404040 40404040 40404040  .END            
*000470  40404040 40404040 40404040 40404040                  
*000480  F1F5F7F4 F1E2C3F1 F0F340F0 F1F0F5F7  15741SC103 01057
*000490  F6F3F6F3 40404040 40404040 40404040  6363            
*0004A0  40404040 40404040 F0F0F0F0 F0F0F1F5          00000015
*
*
*
         ENTRY IJGUIZZZ
IJGUIZZZ DS    0D
*000050  02E3E7E3 40000000 40400038 40400001  .TXT ...  ..  ..
*000060  0A320000 0A320000 47F0F02A 0A320000  .........00.....
*000070  0A320000 0A320000 C9D1C7E4 C9E9E9E9  ........IJGUIZZZ
*000080  3400FFFF D9E5FFFF 3400909D F2309180  ....RV......2.j.
*000090  10264780 F03E9110 40404040 F0F0F0F2  ....0.j.    0002
         SVC   50
         DC    X'0000'
         SVC   50
         DC    X'0000'
         B     42(R0,R15)
         SVC   50
         DC    X'0000'
         SVC   50
         DC    X'0000'
         SVC   50
         DC    X'0000'
         DC    C'IJGUIZZZ'
         DC    X'3400'
         DC    X'FFFF'
         DC    X'D9E5'
         DC    X'FFFF'
         DC    X'3400'
*         DC    X'FFFFFFC9FFFFFFD1'
*         DC    X'FFFFFFC7FFFFFFE4'
*         DC    X'FFFFFFC9FFFFFFE9'
*         DC    X'FFFFFFE9FFFFFFE9'
*         HER   F0,F0
*         DC    X'FFFFFFFFFFFFFFFF'
*         MVCK  4095(R14,R15),1024(R3),R5
*         MVC   4095(R14,R15),1024(R3)
         STM   R9,R13,560(R15)
         TM    38(R1),128
         BZ    62(R0,R15)
         TM    39(R1),16
*0000A0  02E3E7E3 40000038 40400038 40400001  .TXT ...  ..  ..
*0000B0  10274710 F1629180 10494710 F0E89680  ....1.j.....0Yo.
*0000C0  10499200 10409200 10949292 108845D0  ..k.. k..mkk.h.}
*0000D0  F0FC9180 10024710 F0640A07 91011004  0.j.....0...j...
*0000E0  4710F162 91101015 40404040 F0F0F0F3  ..1.j...    0003
         BO    354(R0,R15)
         TM    73(R1),128
         BO    232(R0,R15)
         OI    73(R1),128
         MVI   64(R1),0
         MVI   148(R1),0
         MVI   136(R1),146
         BAL   R13,252(R0,R15)
         TM    2(R1),128
         BO    100(R0,R15)
         SVC   7
         TM    4(R1),1
         BO    354(R0,R15)
         TM    21(R1),16
*0000F0  02E3E7E3 40000070 40400018 40400001  .TXT ...  ..  ..
*000100  4710F0B4 D2021061 1085D202 10591081  ..0.K../.eK....a
*000110  58901080 D2021081 40404040 40404040  ....K..a        
*000120  40404040 40404040 40404040 40404040                  
*000130  40404040 40404040 40404040 F0F0F0F4              0004
         BO    180(R0,R15)
         MVC   97(3,R1),133(R1)
         MVC   89(3,R1),129(R1)
         L     R9,128(R0,R1)
         MVC   129(3,R1),45(R1)
*000140  02E3E7E3 40000088 40400038 40400001  .TXT ..h  ..  ..
*000150  102D5090 102C9108 10644780 F09E45D0  ..&...j.....0..}
*000160  F0FC47F0 F0A69110 10154710 F096989D  0..00wj.....0oq.
*000170  F2304400 105C4400 105407FE 58901080  2....*..........
*000180  48C01086 18D018B9 40404040 F0F0F0F5  .{.f.}..    0005
         ST    R9,44(R0,R1)
         TM    100(R1),8
         BZ    158(R0,R15)
         BAL   R13,252(R0,R15)
         B     166(R0,R15)
         TM    21(R1),16
         BO    150(R0,R15)
         LM    R9,R13,560(R15)
         EX    R0,92(R0,R1)
         EX    R0,84(R0,R1)
         BR    R14
         L     R9,128(R0,R1)
         LH    R12,134(R0,R1)
         LR    R13,R0
         LR    R11,R9
*000190  02E3E7E3 400000C0 40400038 40400001  .TXT ..{  ..  ..
*0001A0  41A00100 1BCA47C0 F0D6D2FF D000B000  .......{0OK.}...
*0001B0  1ADA86BA F0C441CC 00FF44C0 F0E247F0  ..f.0D.....{0S.0
*0001C0  F074D200 D000B000 91081064 4710F05A  0.K.}...j.....0!
*0001D0  91101015 4780F056 40404040 F0F0F0F6  j.....0.    0006
         LA    R10,256(R0,R0)
         SR    R12,R10
         BC    12,214(R0,R15)
         MVC   0(256,R13),0(R11)
         AR    R13,R10
         BXH   R11,R10,196(R15)
         LA    R12,255(R12,R0)
         EX    R12,226(R0,R15)
         B     116(R0,R15)
         MVC   0(1,R13),0(R11)
         TM    100(R1),8
         BO    90(R0,R15)
         TM    21(R1),16
         BZ    86(R0,R15)
*0001E0  02E3E7E3 400000F8 40400018 40400001  .TXT ..8  ..  ..
*0001F0  47F0F05A 95001094 4770F108 45C0F1FA  .00!n..m..1..{1.
*000200  4890104A 41990001 40404040 40404040  .....r..        
*000210  40404040 40404040 40404040 40404040                  
*000220  40404040 40404040 40404040 F0F0F0F7              0007
         B     90(R0,R15)
         CLI   148(R1),0
         BNZ   264(R0,R15)
         BAL   R12,506(R0,R15)
         LH    R9,74(R0,R1)
         LA    R9,1(R9,R0)
*000230  02E3E7E3 40000110 40400038 40400001  .TXT ...  ..  ..
*000240  49901096 4720F11C 40901096 D5011096  ...o..1. ..oN..o
*000250  F2224770 F12A9208 1097D500 10471093  2...1.k..pN....l
*000260  4780F13E D5031090 10364770 F1529501  ..1.N.......1.n.
*000270  10944770 F1529512 40404040 F0F0F0F8  .m..1.n.    0008
         CH    R9,150(R0,R1)
         BP    284(R0,R15)
         STH   R9,150(R0,R1)
         CLC   150(2,R1),546(R15)
         BNZ   298(R0,R15)
         MVI   151(R1),8
         CLC   71(1,R1),147(R1)
         BZ    318(R0,R15)
         CLC   144(4,R1),54(R1)
         BNZ   338(R0,R15)
         CLI   148(R1),1
         BNZ   338(R0,R15)
         CLI   136(R1),18
*000280  02E3E7E3 40000148 40400038 40400001  .TXT ...  ..  ..
*000290  10884780 F1989212 1088D201 10861096  .h..1qk..hK..f.o
*0002A0  D204103C 10900A00 07FD9001 F24494EF  K...........2.m.
*0002B0  102750D0 F224989D F2304100 F2484110  ..&}2.q.2...2...
*0002C0  F21A0A02 9801F244 40404040 F0F0F0F9  2...q.2.    0009
         BZ    408(R0,R15)
         MVI   136(R1),18
         MVC   134(2,R1),150(R1)
         MVC   60(5,R1),144(R1)
         SVC   0
         BR    R13
         STM   R0,R1,580(R15)
         NI    39(R1),239
         ST    R13,548(R0,R15)
         LM    R9,R13,560(R15)
         LA    R0,584(R0,R15)
         LA    R1,538(R0,R15)
         SVC   2
         LM    R0,R1,580(R15)
*0002D0  02E3E7E3 40000180 40400018 40400001  .TXT ...  ..  ..
*0002E0  909DF230 58D0F224 91201010 4710F0A6  ..2..}2.j.....0w
*0002F0  92001040 47F0F104 40404040 40404040  k.. .01.        
*000300  40404040 40404040 40404040 40404040                  
*000310  40404040 40404040 40404040 F0F0F1F0              0010
         STM   R9,R13,560(R15)
         L     R13,548(R0,R15)
         TM    16(R1),32
         BO    166(R0,R15)
         MVI   64(R1),0
         B     260(R0,R15)
*000320  02E3E7E3 40000198 40400038 40400001  .TXT ..q  ..  ..
*000330  92921088 41900004 48C01034 D203104C  kk.h.....{..K..<
*000340  109018AB 43A91043 43B9104B 15BA4770  .....z..........
*000350  F1C642C9 104B88C0 00084690 F1AA41BB  1F.I..h{....1...
*000360  000142B9 104BD203 40404040 F0F0F1F1  ......K.    0011
         MVI   136(R1),146
         LA    R9,4(R0,R0)
         LH    R12,52(R0,R1)
         MVC   76(4,R1),144(R1)
         LR    R10,R11
         IC    R10,67(R9,R1)
         IC    R11,75(R9,R1)
         CLR   R11,R10
         BNZ   454(R0,R15)
         STC   R12,75(R9,R1)
         SRL   R12,8(R0)
         BCT   R9,426(R0,R15)
         LA    R11,1(R11,R0)
         STC   R11,75(R9,R1)
*000370  02E3E7E3 400001D0 40400038 40400001  .TXT ..}  ..  ..
*000380  103C104C 92001040 D5031036 104C47B0  ...<k.. N....<..
*000390  F1049108 10644780 F1629180 10264780  1.j.....1.j.....
*0003A0  F1629610 102747F0 F0A6D207 F2281080  1.o....00wK.2...
*0003B0  D2071080 10880A00 40404040 F0F0F1F2  K....h..    0012
         MVC   60(4,R1),76(R1)
         MVI   64(R1),0
         CLC   54(4,R1),76(R1)
         BNM   260(R0,R15)
         TM    100(R1),8
         BZ    354(R0,R15)
         TM    38(R1),128
         BZ    354(R0,R15)
         OI    39(R1),16
         B     166(R0,R15)
         MVC   552(8,R15),128(R1)
         MVC   128(8,R1),136(R1)
         SVC   0
*0003C0  02E3E7E3 40000208 40400018 40400001  .TXT ...  ..  ..
*0003D0  91801002 4710F212 0A07D207 1080F228  j.....2...K...2.
*0003E0  07FC5B5B C2D6D7C5 40404040 40404040  ..$$BOPE        
*0003F0  40404040 40404040 40404040 40404040                  
*000400  40404040 40404040 40404040 F0F0F1F3              0013
         TM    2(R1),128
         BO    530(R0,R15)
         SVC   7
         MVC   128(8,R1),552(R15)
         BR    R12
         DC    C'$$BOPEN '
*         S     R5,726(R11,R12)
*         XC    1344(198,R13),0(R0)
*000410  02E3E7E3 40000220 4040002D 40400001  .TXT ...  ..  ..
*000420  D5400000 00000000 00000000 00000000  N ..............
*000430  00000000 00000000 00000000 00000000  ................
*000440  00000000 00000000 00000000 FF404040  .............   
*000450  40404040 40404040 40404040 F0F0F1F4              0014
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
*         DC    X'FFFFFFFF'
         DC    X'FF'
*
*
*
*000000  02C5E2C4 40404040 40400010 40400001  .ESD      ..  ..
*000010  C9D1C7E4 D6E9E9E9 00000000 400002D9  IJGUOZZZ.... ..R
*000020  40404040 40404040 40404040 40404040                  
*000030  40404040 40404040 40404040 40404040                  
*000040  40404040 40404040 40404040 F0F0F0F1              0001
*
*000050  02E3E7E3 40000000 40400038 40400001  .TXT ...  ..  ..
*000060  0A320000 0A320000 0A320000 47F0F02E  .............00.
*000070  47F0F262 0A320000 47F0F236 C9D1C7E4  .02......02.IJGU
*000080  D6E9E9E9 3401FFFF D9E5FFFF 3401908D  OZZZ....RV......
*000090  F2B89180 10494710 40404040 F0F0F0F2  2.j.....    0002
*
*0000A0  02E3E7E3 40000038 40400038 40400001  .TXT ...  ..  ..
*0000B0  F0889680 10494400 105C908D F2B845C0  0ho......*..2..{
*0000C0  F14C9110 10154780 F0564590 F09445A0  1<j.....0...0m..
*0000D0  F0E645C0 F1245890 102C4199 00085090  0W.{1......r..&.
*0000E0  10589108 10644710 40404040 F0F0F0F3  ..j.....    0003
*
*0000F0  02E3E7E3 40000070 40400018 40400001  .TXT ...  ..  ..
*000100  F07E9110 10154710 F07E45C0 F24E988D  0=j.....0=.{2+q.
*000110  F2B84400 105407FE 40404040 40404040  2.......        
*000120  40404040 40404040 40404040 40404040                  
*000130  40404040 40404040 40404040 F0F0F0F4              0004
*
*000140  02E3E7E3 40000088 40400038 40400001  .TXT ..h  ..  ..
*000150  45D0F0C8 988DF2B8 47F0F03E 48C01042  .}0Hq.2..00..{..
*000160  58D0102C 41DD0008 18B041A0 01001BCA  .}..............
*000170  47C0F0B8 D2FFD000 B0001ADA 86BAF0A6  .{0.K.}.....f.0w
*000180  41CC00FF 44C0F0C2 40404040 F0F0F0F5  .....{0B    0005
*
*000190  02E3E7E3 400000C0 40400038 40400001  .TXT ..{  ..  ..
*0001A0  07F9D200 D000B000 91081064 4710F0D8  .9K.}...j.....0Q
*0001B0  91101015 4780F0E4 50D0F2D0 45C0F24E  j.....0U&}2}.{2+
*0001C0  58D0F2D0 07FD5890 1080D202 1081102D  .}2}......K..a..
*0001D0  5090102C 07FA4190 40404040 F0F0F0F6  &.......    0006
*
*0001E0  02E3E7E3 400000F8 40400018 40400001  .TXT ..8  ..  ..
*0001F0  00044880 103418AB 43A91043 43B9104B  .........z......
*000200  15BA4770 F11A4289 40404040 40404040  ....1..i        
*000210  40404040 40404040 40404040 40404040                  
*000220  40404040 40404040 40404040 F0F0F0F7              0007
*
*000230  02E3E7E3 40000110 40400038 40400001  .TXT ...  ..  ..
*000240  104B8880 00084690 F0FE41BB 000142B9  ..h.....0.......
*000250  104B07FD 48A01042 41AA0008 40A01086  ............ ..f
*000260  41900005 45D0F0FA 58A01080 D204A000  .....}0.....K...
*000270  104CD202 A0051041 40404040 F0F0F0F8  .<K.....    0008
*
*000280  02E3E7E3 40000148 40400038 40400001  .TXT ...  ..  ..
*000290  0A0007FC 48A0104A 41AA0001 49A01042  ................
*0002A0  4720F160 40A01042 91201049 4710F27E  ..1- ...j.....2=
*0002B0  48A010A0 49A01042 4740F1F6 48901042  ......... 16....
*0002C0  9504101D 4780F1BC 40404040 F0F0F0F9  n.....1.    0009
*
*0002D0  02E3E7E3 40000180 40400018 40400001  .TXT ...  ..  ..
*0002E0  9505101D 4780F1C4 9108101D 4710F1CC  n.....1Dj.....1.
*0002F0  9507101D 4780F1D4 40404040 40404040  n.....1M        
*000300  40404040 40404040 40404040 40404040                  
*000310  40404040 40404040 40404040 F0F0F1F0              0010
*
*000320  02E3E7E3 40000198 40400038 40400001  .TXT ..q  ..  ..
*000330  9501101D 4780F1DC 4C90F29E 88900009  n.....1.<.2.h...
*000340  4199003D 9502101D 4770F1E8 41990017  .r..n.....1Y.r..
*000350  47F0F1E8 41990087 47F0F1E8 41990087  .01Y.r.g.01Y.r.g
*000360  47F0F1E8 419900A7 40404040 F0F0F1F1  .01Y.r.x    0011
*
*000370  02E3E7E3 400001D0 40400038 40400001  .TXT ..}  ..  ..
*000380  47F0F1E8 419900B9 47F0F1E8 4C90F2A0  .01Y.r...01Y<.2.
*000390  88900009 41990065 1BA940A0 10A0D204  h....r...z ...K.
*0003A0  103C104C 07FCD201 10A01052 45D0F0F6  ...<..K......}06
*0003B0  92001050 D503104C 40404040 F0F0F1F2  k..&N..<    0012
*
*0003C0  02E3E7E3 40000208 40400018 40400001  .TXT ...  ..  ..
*0003D0  10364720 F21247F0 F1604111 00009001  ....2..01-......
*0003E0  F2D050C0 F2B0988D 40404040 40404040  2}&{2.q.        
*0003F0  40404040 40404040 40404040 40404040                  
*000400  40404040 40404040 40404040 F0F0F1F3              0013
*
*000410  02E3E7E3 40000220 40400038 40400001  .TXT ...  ..  ..
*000420  F2B84100 F2D49120 10494780 F2300A09  2...2Mj.....2...
*000430  4110F2A4 0A029801 F2D0908D F2B858C0  ..2u..q.2}..2..{
*000440  F2B09120 10104710 F07E47F0 F16050C0  2.j.....0=.01-&{
*000450  F2B49180 10024710 40404040 F0F0F1F4  2.j.....    0014
*
*000460  02E3E7E3 40000258 40400038 40400001  .TXT ...  ..  ..
*000470  F25C0A07 58C0F2B4 07FC908D F2B845D0  2*...{2.....2..}
*000480  F0C848D0 10A049D0 F2AC47B0 F2829620  0H.}...}2...2bo.
*000490  104947F0 F1F69720 1049D201 1042F2A2  ...016p...K...2s
*0004A0  45A0F0E6 45C0F14C 40404040 F0F0F1F5  ..0W.{1<    0015
*
*0004B0  02E3E7E3 40000290 40400018 40400001  .TXT ...  ..  ..
*0004C0  45C0F124 45C0F24E 988DF2B8 0A090219  .{1..{2+q.2.....
*0004D0  02160000 5B5BC2D6 40404040 40404040  ....$$BO        
*0004E0  40404040 40404040 40404040 40404040                  
*0004F0  40404040 40404040 40404040 F0F0F1F6              0016
*
*000500  02E3E7E3 400002A8 40400031 40400001  .TXT ..y  ..  ..
*000510  D7C5D540 00010000 00000000 00000000  PEN ............
*000520  00000000 00000000 00000000 00000000  ................
*000530  00000000 00000000 00000000 00000000  ................
*000540  FF404040 40404040 40404040 F0F0F1F7  .           0017
*
*000550  02C5D5C4 40404040 40404040 40404040  .END            
*000560  40404040 40404040 40404040 40404040                  
*000570  F1F5F7F4 F1E2C3F1 F0F340F0 F2F0F1F7  15741SC103 02017
*000580  F9F0F7F3 40404040 40404040 40404040  9073            
*000590  40404040 40404040 F0F0F0F0 F0F0F1F8          00000018
*
*
*
         ENTRY IJGUOZZZ
IJGUOZZZ DS    0D
*
*000050  02E3E7E3 40000000 40400038 40400001  .TXT ...  ..  ..
*000060  0A320000 0A320000 0A320000 47F0F02E  .............00.
*000070  47F0F262 0A320000 47F0F236 C9D1C7E4  .02......02.IJGU
*000080  D6E9E9E9 3401FFFF D9E5FFFF 3401908D  OZZZ....RV......
*000090  F2B89180 10494710 40404040 F0F0F0F2  2.j.....    0002
         SVC   50
         DC    X'0000'
         SVC   50
         DC    X'0000'
         SVC   50
         DC    X'0000'
         B     46(R0,R15)
         B     610(R0,R15)
         SVC   50
         DC    X'0000'
         B     566(R0,R15)
         DC    C'IJGUOZZZ'
         DC    X'3401'
         DC    X'FFFF'
         DC    X'D9E5'
         DC    X'FFFF'
         DC    X'3401'
*         DC    X'FFFFFFC9FFFFFFD1'
*         DC    X'FFFFFFC7FFFFFFE4'
*         OC    2537(234,R14),1025(R3)
*         DC    X'FFFFFFFFFFFFFFFF'
***         MVCK  4095(R14,R15),1025(R3),R5
*         MVC   4095(R14,R15),1025(R3)
         STM   R8,R13,696(R15)
         TM    73(R1),128
*0000A0  02E3E7E3 40000038 40400038 40400001  .TXT ...  ..  ..
*0000B0  F0889680 10494400 105C908D F2B845C0  0ho......*..2..{
*0000C0  F14C9110 10154780 F0564590 F09445A0  1<j.....0...0m..
*0000D0  F0E645C0 F1245890 102C4199 00085090  0W.{1......r..&.
*0000E0  10589108 10644710 40404040 F0F0F0F3  ..j.....    0003
         BO    136(R0,R15)
         OI    73(R1),128
         EX    R0,92(R0,R1)
         STM   R8,R13,696(R15)
         BAL   R12,332(R0,R15)
         TM    21(R1),16
         BZ    86(R0,R15)
         BAL   R9,148(R0,R15)
         BAL   R10,230(R0,R15)
         BAL   R12,292(R0,R15)
         L     R9,44(R0,R1)
         LA    R9,8(R9,R0)
         ST    R9,88(R0,R1)
         TM    100(R1),8
         BO    126(R0,R15)
*0000F0  02E3E7E3 40000070 40400018 40400001  .TXT ...  ..  ..
*000100  F07E9110 10154710 F07E45C0 F24E988D  0=j.....0=.{2+q.
*000110  F2B84400 105407FE 40404040 40404040  2.......        
*000120  40404040 40404040 40404040 40404040                  
*000130  40404040 40404040 40404040 F0F0F0F4              0004
         TM    21(R1),16
         BO    126(R0,R15)
         BAL   R12,590(R0,R15)
         LM    R8,R13,696(R15)
         EX    R0,84(R0,R1)
         BR    R14
*000140  02E3E7E3 40000088 40400038 40400001  .TXT ..h  ..  ..
*000150  45D0F0C8 988DF2B8 47F0F03E 48C01042  .}0Hq.2..00..{..
*000160  58D0102C 41DD0008 18B041A0 01001BCA  .}..............
*000170  47C0F0B8 D2FFD000 B0001ADA 86BAF0A6  .{0.K.}.....f.0w
*000180  41CC00FF 44C0F0C2 40404040 F0F0F0F5  .....{0B    0005
         BAL   R13,200(R0,R15)
         LM    R8,R13,696(R15)
         B     62(R0,R15)
         LH    R12,66(R0,R1)
         L     R13,44(R0,R1)
         LA    R13,8(R13,R0)
         LR    R11,R0
         LA    R10,256(R0,R0)
         SR    R12,R10
         BC    12,184(R0,R15)
         MVC   0(256,R13),0(R11)
         AR    R13,R10
         BXH   R11,R10,166(R15)
         LA    R12,255(R12,R0)
         EX    R12,194(R0,R15)
*000190  02E3E7E3 400000C0 40400038 40400001  .TXT ..{  ..  ..
*0001A0  07F9D200 D000B000 91081064 4710F0D8  .9K.}...j.....0Q
*0001B0  91101015 4780F0E4 50D0F2D0 45C0F24E  j.....0U&}2}.{2+
*0001C0  58D0F2D0 07FD5890 1080D202 1081102D  .}2}......K..a..
*0001D0  5090102C 07FA4190 40404040 F0F0F0F6  &.......    0006
         BR    R9
         MVC   0(1,R13),0(R11)
         TM    100(R1),8
         BO    216(R0,R15)
         TM    21(R1),16
         BZ    228(R0,R15)
         ST    R13,720(R0,R15)
         BAL   R12,590(R0,R15)
         L     R13,720(R0,R15)
         BR    R13
         L     R9,128(R0,R1)
         MVC   129(3,R1),45(R1)
         ST    R9,44(R0,R1)
         BR    R10
*0001E0  02E3E7E3 400000F8 40400018 40400001  .TXT ..8  ..  ..
*0001F0  00044880 103418AB 43A91043 43B9104B  .........z......
*000200  15BA4770 F11A4289 40404040 40404040  ....1..i        
*000210  40404040 40404040 40404040 40404040                  
*000220  40404040 40404040 40404040 F0F0F0F7              0007
         LA    R9,4(R0,R0)
         LH    R8,52(R0,R1)
         LR    R10,R11
         IC    R10,67(R9,R1)
         IC    R11,75(R9,R1)
         CLR   R11,R10
         BNZ   282(R0,R15)
         STC   R8,75(R9,R1)
*000230  02E3E7E3 40000110 40400038 40400001  .TXT ...  ..  ..
*000240  104B8880 00084690 F0FE41BB 000142B9  ..h.....0.......
*000250  104B07FD 48A01042 41AA0008 40A01086  ............ ..f
*000260  41900005 45D0F0FA 58A01080 D204A000  .....}0.....K...
*000270  104CD202 A0051041 40404040 F0F0F0F8  .<K.....    0008
         SRL   R8,8(R0)
         BCT   R9,254(R0,R15)
         LA    R11,1(R11,R0)
         STC   R11,75(R9,R1)
         BR    R13
         LH    R10,66(R0,R1)
         LA    R10,8(R10,R0)
         STH   R10,134(R0,R1)
         LA    R9,5(R0,R0)
         BAL   R13,250(R0,R15)
         L     R10,128(R0,R1)
         MVC   0(5,R10),76(R1)
         MVC   5(3,R10),65(R1)
*000280  02E3E7E3 40000148 40400038 40400001  .TXT ...  ..  ..
*000290  0A0007FC 48A0104A 41AA0001 49A01042  ................
*0002A0  4720F160 40A01042 91201049 4710F27E  ..1- ...j.....2=
*0002B0  48A010A0 49A01042 4740F1F6 48901042  ......... 16....
*0002C0  9504101D 4780F1BC 40404040 F0F0F0F9  n.....1.    0009
         SVC   0
         BR    R12
         LH    R10,74(R0,R1)
         LA    R10,1(R10,R0)
         CH    R10,66(R0,R1)
         BP    352(R0,R15)
         STH   R10,66(R0,R1)
         TM    73(R1),32
         BO    638(R0,R15)
         LH    R10,160(R0,R1)
         CH    R10,66(R0,R1)
         BM    502(R0,R15)
         LH    R9,66(R0,R1)
         CLI   29(R1),4
         BZ    444(R0,R15)
*0002D0  02E3E7E3 40000180 40400018 40400001  .TXT ...  ..  ..
*0002E0  9505101D 4780F1C4 9108101D 4710F1CC  n.....1Dj.....1.
*0002F0  9507101D 4780F1D4 40404040 40404040  n.....1M        
*000300  40404040 40404040 40404040 40404040                  
*000310  40404040 40404040 40404040 F0F0F1F0              0010
         CLI   29(R1),5
         BZ    452(R0,R15)
         TM    29(R1),8
         BO    460(R0,R15)
         CLI   29(R1),7
         BZ    468(R0,R15)
*000320  02E3E7E3 40000198 40400038 40400001  .TXT ..q  ..  ..
*000330  9501101D 4780F1DC 4C90F29E 88900009  n.....1.<.2.h...
*000340  4199003D 9502101D 4770F1E8 41990017  .r..n.....1Y.r..
*000350  47F0F1E8 41990087 47F0F1E8 41990087  .01Y.r.g.01Y.r.g
*000360  47F0F1E8 419900A7 40404040 F0F0F1F1  .01Y.r.x    0011
         CLI   29(R1),1
         BZ    476(R0,R15)
         MH    R9,670(R0,R15)
         SRL   R9,9(R0)
         LA    R9,61(R9,R0)
         CLI   29(R1),2
         BNZ   488(R0,R15)
         LA    R9,23(R9,R0)
         B     488(R0,R15)
         LA    R9,135(R9,R0)
         B     488(R0,R15)
         LA    R9,135(R9,R0)
         B     488(R0,R15)
         LA    R9,167(R9,R0)
*000370  02E3E7E3 400001D0 40400038 40400001  .TXT ..}  ..  ..
*000380  47F0F1E8 419900B9 47F0F1E8 4C90F2A0  .01Y.r...01Y<.2.
*000390  88900009 41990065 1BA940A0 10A0D204  h....r...z ...K.
*0003A0  103C104C 07FCD201 10A01052 45D0F0F6  ...<..K......}06
*0003B0  92001050 D503104C 40404040 F0F0F1F2  k..&N..<    0012
         B     488(R0,R15)
         LA    R9,185(R9,R0)
         B     488(R0,R15)
         MH    R9,672(R0,R15)
         SRL   R9,9(R0)
         LA    R9,101(R9,R0)
         SR    R10,R9
         STH   R10,160(R0,R1)
         MVC   60(5,R1),76(R1)
         BR    R12
         MVC   160(2,R1),82(R1)
         BAL   R13,246(R0,R15)
         MVI   80(R1),0
         CLC   76(4,R1),54(R1)
*0003C0  02E3E7E3 40000208 40400018 40400001  .TXT ...  ..  ..
*0003D0  10364720 F21247F0 F1604111 00009001  ....2..01-......
*0003E0  F2D050C0 F2B0988D 40404040 40404040  2}&{2.q.        
*0003F0  40404040 40404040 40404040 40404040                  
*000400  40404040 40404040 40404040 F0F0F1F3              0013
         BP    530(R0,R15)
         B     352(R0,R15)
         LA    R1,0(R1,R0)
         STM   R0,R1,720(R15)
         ST    R12,688(R0,R15)
         LM    R8,R13,696(R15)
*000410  02E3E7E3 40000220 40400038 40400001  .TXT ...  ..  ..
*000420  F2B84100 F2D49120 10494780 F2300A09  2...2Mj.....2...
*000430  4110F2A4 0A029801 F2D0908D F2B858C0  ..2u..q.2}..2..{
*000440  F2B09120 10104710 F07E47F0 F16050C0  2.j.....0=.01-&{
*000450  F2B49180 10024710 40404040 F0F0F1F4  2.j.....    0014
         LA    R0,724(R0,R15)
         TM    73(R1),32
         BZ    560(R0,R15)
         SVC   9
         LA    R1,676(R0,R15)
         SVC   2
         LM    R0,R1,720(R15)
         STM   R8,R13,696(R15)
         L     R12,688(R0,R15)
         TM    16(R1),32
         BO    126(R0,R15)
         B     352(R0,R15)
         ST    R12,692(R0,R15)
         TM    2(R1),128
         BO    604(R0,R15)
*000460  02E3E7E3 40000258 40400038 40400001  .TXT ...  ..  ..
*000470  F25C0A07 58C0F2B4 07FC908D F2B845D0  2*...{2.....2..}
*000480  F0C848D0 10A049D0 F2AC47B0 F2829620  0H.}...}2...2bo.
*000490  104947F0 F1F69720 1049D201 1042F2A2  ...016p...K...2s
*0004A0  45A0F0E6 45C0F14C 40404040 F0F0F1F5  ..0W.{1<    0015
         SVC   7
         L     R12,692(R0,R15)
         BR    R12
         STM   R8,R13,696(R15)
         BAL   R13,200(R0,R15)
         LH    R13,160(R0,R1)
         CH    R13,684(R0,R15)
         BNM   642(R0,R15)
         OI    73(R1),32
         B     502(R0,R15)
         XI    73(R1),32
         MVC   66(2,R1),674(R15)
         BAL   R10,230(R0,R15)
         BAL   R12,332(R0,R15)
*0004B0  02E3E7E3 40000290 40400018 40400001  .TXT ...  ..  ..
*0004C0  45C0F124 45C0F24E 988DF2B8 0A090219  .{1..{2+q.2.....
*0004D0  02160000 5B5BC2D6 40404040 40404040  ....$$BO        
*0004E0  40404040 40404040 40404040 40404040                  
*0004F0  40404040 40404040 40404040 F0F0F1F6              0016
         BAL   R12,292(R0,R15)
         BAL   R12,590(R0,R15)
         LM    R8,R13,696(R15)
         SVC   9
         DC    X'0219'
         DC    X'0216'
         DC    X'0000'
         DC    C'$$BOPEN '
*000500  02E3E7E3 400002A8 40400031 40400001  .TXT ..y  ..  ..
*000510  D7C5D540 00010000 00000000 00000000  PEN ............
*000520  00000000 00000000 00000000 00000000  ................
*000530  00000000 00000000 00000000 00000000  ................
*000540  FF404040 40404040 40404040 F0F0F1F7  .           0017
*         S     R5,726(R11,R12)
*         XC    1344(198,R13),1(R0)
         DC    X'0001'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
*         DC    X'FFFFFFFF'
         DC    X'FF'
*
*
*
*000000  02C5E2C4 40404040 40400020 40400001  .ESD      ..  ..
*000010  C9D1D1C6 C3C2E9C4 00000000 40000395  IJJFCBZD.... ..n
*000020  C9D1D1C6 C3C9E9C4 01000000 40000001  IJJFCIZD.... ...
*000030  40404040 40404040 40404040 40404040                  
*000040  40404040 40404040 40404040 F0F0F0F1              0001
*
*000050  02E3E7E3 40000000 40400038 40400001  .TXT ...  ..  ..
*000060  0A320000 47F0F000 47F0F032 47F0F032  .....00..00..00.
*000070  47F0F000 47F0F000 47F0F036 47F0F1E0  .00..00..00..01\
*000080  C9D1D1C6 C3C2E9C4 3401FFFF D9E5FFFF  IJJFCBZD....RV..
*000090  34009026 F3145860 40404040 F0F0F0F2  ....3..-    0002
*
*0000A0  02E3E7E3 40000038 40400038 40400001  .TXT ...  ..  ..
*0000B0  100895FF 101E4780 F0464A60 104A9103  ..n.....0..-..j.
*0000C0  102B4710 F2024740 F1949140 102C4780  ....2.. 1mj ....
*0000D0  F06294BF 102C4530 F1865846 00000640  0.m.....1f..... 
*0000E0  9180102A 4780F0A2 40404040 F0F0F0F3  j.....0s    0003
*
*0000F0  02E3E7E3 40000070 40400018 40400001  .TXT ...  ..  ..
*000100  4B60104A 96606004 D2006000 104195E6  .-..o--.K.-...nW
*000110  40004780 F09AD200 40404040 40404040   ...0.K.        
*000120  40404040 40404040 40404040 40404040                  
*000130  40404040 40404040 40404040 F0F0F0F4              0004
*
*000140  02E3E7E3 40000088 40400038 40400001  .TXT ..h  ..  ..
*000150  60001040 95E54000 4780F09A D2006000  -.. nV ...0.K.-.
*000160  40004A60 104A47F0 F1949200 F34891F0   ..-...01mk.3.j0
*000170  40004710 F0EA95C1 40004780 F0EA95C2   ...0.nA ...0.nB
*000180  40004780 F0EA95C3 40404040 F0F0F0F5   ...0.nC    0005
*
*000190  02E3E7E3 400000C0 40400038 40400001  .TXT ..{  ..  ..
*0001A0  40004780 F0EA4800 F3664130 F36F4133   ...0...3...3?..
*0001B0  0012D500 40003000 4780F0EA 06304600  ..N. .....0.....
*0001C0  F0D29201 F34847F0 F1161830 43040000  0Kk.3..01.......
*0001D0  41400012 4334F36F 40404040 F0F0F0F6  . ....3?    0006
*
*0001E0  02E3E7E3 400000F8 40400018 40400001  .TXT ..8  ..  ..
*0001F0  19304780 F1024640 F0F44940 F36447B0  ....1.. 04. 3...
*000200  F112920B 60004530 40404040 40404040  1.k.-...        
*000210  40404040 40404040 40404040 40404040                  
*000220  40404040 40404040 40404040 F0F0F0F7              0007
*
*000230  02E3E7E3 40000110 40400038 40400001  .TXT ...  ..  ..
*000240  F1864144 F3829108 102A4710 F1369541  1f..3bj.....1.n.
*000250  40004780 F1369581 40004780 F1369201   ...1.na ...1.k.
*000260  600047F0 F13CD200 60004000 D6006000  -..01.K.-. .O.-.
*000270  10289108 102C4780 40404040 F0F0F0F8  ..j.....    0008
*
*000280  02E3E7E3 40000148 40400038 40400001  .TXT ...  ..  ..
*000290  F1949180 10024710 F1540A07 91101003  1mj.....1...j...
*0002A0  4780F166 18314110 F3680A02 1813D200  ..1.....3.....K.
*0002B0  10401038 D2001038 1030D24F 10981048  . ..K.....K|.q..
*0002C0  58301030 D24F1048 40404040 F0F0F0F9  ....K|..    0009
*
*0002D0  02E3E7E3 40000180 40400018 40400001  .TXT ...  ..  ..
*0002E0  300047F0 F1940A00 91801002 4710F192  ...01m..j.....1k
*0002F0  0A0707F3 4530F186 40404040 40404040  ...3..1f        
*000300  40404040 40404040 40404040 40404040                  
*000310  40404040 40404040 40404040 F0F0F1F0              0010
*
*000320  02E3E7E3 40000198 40400038 40400001  .TXT ..q  ..  ..
*000330  9108102A 4780F1B0 9501F348 4780F1B0  j.....1.n.3...1.
*000340  92016000 4530F186 91011004 4710F1CC  k.-...1fj.....1.
*000350  91401005 4710F2CA 91101003 4710F2E2  j ....2.j.....2S
*000360  47F0F1E0 9108102A 40404040 F0F0F1F1  .01\j...    0011
*
*000370  02E3E7E3 400001D0 40400038 40400001  .TXT ..}  ..  ..
*000380  4710F1E0 9102102C 4710F2B8 58E01040  ..1\j.....2..\. 
*000390  9826F314 9506101D 4770F200 91801003  q.3.n.....2.j...
*0003A0  4780F200 96401026 97801003 47F0F032  ..2.o ..p....00.
*0003B0  07FED200 10401050 40404040 F0F0F1F2  ..K.. .&    0012
*
*0003C0  02E3E7E3 40000208 40400018 40400001  .TXT ...  ..  ..
*0003D0  D5001040 10484770 F2A85820 103C4A20  N.. ....2y......
*0003E0  F3601842 43401047 40404040 40404040  3-... ..        
*0003F0  40404040 40404040 40404040 40404040                  
*000400  40404040 40404040 40404040 F0F0F1F3              0013
*
*000410  02E3E7E3 40000220 40400038 40400001  .TXT ...  ..  ..
*000420  192447D0 F22E5A20 F3604320 10355020  ...}2.!.3-....&.
*000430  103CD503 103C1036 4740F29C 4780F24C  ..N...... 2...2<
*000440  9506101D 4770F15C 4780F254 9506101D  n.....1*..2.n...
*000450  4770F29C 91801026 40404040 F0F0F1F4  ..2.j...    0014
*
*000460  02E3E7E3 40000258 40400038 40400001  .TXT ...  ..  ..
*000470  4780F268 9180102C 4780F27E 47F0F1CC  ..2.j.....2=.01.
*000480  4120F350 50201008 0A004530 F1884120  ..3&&.......1h..
*000490  10585020 10089006 F32C92FF F3344100  ..&.....3.k.3...
*0004A0  F3304110 F3580A02 40404040 F0F0F1F5  3...3...    0015
*
*0004B0  02E3E7E3 40000290 40400018 40400001  .TXT ...  ..  ..
*0004C0  9200F334 9806F32C 47F0F194 D2001040  k.3.q.3..01mK.. 
*0004D0  1049D203 104C103C 40404040 40404040  ..K..<..        
*0004E0  40404040 40404040 40404040 40404040                  
*0004F0  40404040 40404040 40404040 F0F0F1F6              0016
*
*000500  02E3E7E3 400002A8 40400038 40400001  .TXT ..y  ..  ..
*000510  43401040 41440001 42401050 47F0F194  . . ..... .&.01m
*000520  18214802 00064110 10160A02 181247F0  ...............0
*000530  F1E094DF 102C9147 10E84710 10E850E0  1\m...j..Y...Y&\
*000540  F32858E0 10E847F0 40404040 F0F0F1F7  3..\.Y.0    0017
*
*000550  02E3E7E3 400002E0 40400038 40400001  .TXT ..\  ..  ..
*000560  F2F694DF 102C9147 10EC4710 10EC50E0  26m...j.......&\
*000570  F32858E0 10EC90F1 F32C5816 00009826  3..\...13.....q.
*000580  F3140700 070005EE 98F1E024 58E0F328  3.......q1\..\3.
*000590  47F0F032 00000000 40404040 F0F0F1F8  .00.....    0018
*
*0005A0  02E3E7E3 40000318 40400018 40400001  .TXT ...  ..  ..
*0005B0  00000000 00000000 00000000 00000000  ................
*0005C0  00000000 00000000 40404040 40404040  ........        
*0005D0  40404040 40404040 40404040 40404040                  
*0005E0  40404040 40404040 40404040 F0F0F1F9              0019
*
*0005F0  02E3E7E3 40000330 40400038 40400001  .TXT ...  ..  ..
*000600  00000000 00000000 00000000 00000000  ................
*000610  00000000 00000000 00000000 00000000  ................
*000620  17000350 00000001 5B5BC2D6 D7C5D540  ...&....$$BOPEN 
*000630  00010000 000D0006 40404040 F0F0F2F0  ........    0020
*
*000640  02E3E7E3 40000368 4040002D 40400001  .TXT ...  ..  ..
*000650  5B5BC2C5 D9D9E3D5 F1F2F3F4 F5F6F7F8  $$BERRTN12345678
*000660  F9C1C2C3 4EE5E660 F0400B8B 939BA3AB  9ABC+VW-0 ..l.t.
*000670  B3BBC3CB D3DBE303 01411B13 0B404040  ..C.L.T......   
*000680  40404040 40404040 40404040 F0F0F2F1              0021
*
*000690  02D9D3C4 40404040 40400008 40404040  .RLD      ..    
*0006A0  00010001 08000351 40404040 40404040  ........        
*0006B0  40404040 40404040 40404040 40404040                  
*0006C0  40404040 40404040 40404040 40404040                  
*0006D0  40404040 40404040 40404040 F0F0F2F2              0022
*0006E0  02C5D5C4 40404040 40404040 40404040  .END            
*0006F0  40404040 40404040 40404040 40404040                  
*000700  F1F5F7F4 F1E2C3F1 F0F340F0 F2F0F1F7  15741SC103 02017
*000710  F9F0F1F7 40404040 40404040 40404040  9017            
*000720  40404040 40404040 F0F0F0F0 F0F0F2F3          00000023
*
         ENTRY IJJFCBZD
IJJFCBZD DS    0D
         ENTRY IJJFCIZD
IJJFCIZD DS    0H
*000050  02E3E7E3 40000000 40400038 40400001  .TXT ...  ..  ..
*000060  0A320000 47F0F000 47F0F032 47F0F032  .....00..00..00.
*000070  47F0F000 47F0F000 47F0F036 47F0F1E0  .00..00..00..01\
*000080  C9D1D1C6 C3C2E9C4 3401FFFF D9E5FFFF  IJJFCBZD....RV..
*000090  34009026 F3145860 40404040 F0F0F0F2  ....3..-    0002
         SVC   50
         DC    X'0000'
         B     0(R0,R15)
         B     50(R0,R15)
         B     50(R0,R15)
         B     0(R0,R15)
         B     0(R0,R15)
         B     54(R0,R15)
         B     480(R0,R15)
         DC    X'C9D1'
         MVN   962(199,R12),2500(R14)
         DC    X'3401'
         DC    X'FFFF'
*         MVCK  4095(R14,R15),1024(R3),R5
*         MVC   4095(R14,R15),1024(R3)
         DC    X'D9E5'
         DC    X'FFFF'
         DC    X'3400'
*
         STM   R2,R6,788(R15)
         L     R6,8(R0,R1)
*0000A0  02E3E7E3 40000038 40400038 40400001  .TXT ...  ..  ..
*0000B0  100895FF 101E4780 F0464A60 104A9103  ..n.....0..-..j.
*0000C0  102B4710 F2024740 F1949140 102C4780  ....2.. 1mj ....
*0000D0  F06294BF 102C4530 F1865846 00000640  0.m.....1f..... 
*0000E0  9180102A 4780F0A2 40404040 F0F0F0F3  j.....0s    0003
         CLI   30(R1),255
         BZ    70(R0,R15)
         AH    R6,74(R0,R1)
         TM    43(R1),3
         BO    514(R0,R15)
         BM    404(R0,R15)
         TM    44(R1),64
         BZ    98(R0,R15)
         NI    44(R1),191
         BAL   R3,390(R0,R15)
         L     R4,0(R6,R0)
         BCTR  R4,R0
         TM    42(R1),128
         BZ    162(R0,R15)
*0000F0  02E3E7E3 40000070 40400018 40400001  .TXT ...  ..  ..
*000100  4B60104A 96606004 D2006000 104195E6  .-..o--.K.-...nW
*000110  40004780 F09AD200 40404040 40404040   ...0.K.        
*000120  40404040 40404040 40404040 40404040                  
*000130  40404040 40404040 40404040 F0F0F0F4              0004
         SH    R6,74(R0,R1)
         OI    4(R6),96
         MVC   0(1,R6),65(R1)
         CLI   0(R4),230
         BZ    154(R0,R15)
         MVC   0(1,R6),64(R1)
*000140  02E3E7E3 40000088 40400038 40400001  .TXT ..h  ..  ..
*000150  60001040 95E54000 4780F09A D2006000  -.. nV ...0.K.-.
*000160  40004A60 104A47F0 F1949200 F34891F0   ..-...01mk.3.j0
*000170  40004710 F0EA95C1 40004780 F0EA95C2   ...0.nA ...0.nB
*000180  40004780 F0EA95C3 40404040 F0F0F0F5   ...0.nC    0005
         CLI   0(R4),229
         BZ    154(R0,R15)
         MVC   0(1,R6),0(R4)
         AH    R6,74(R0,R1)
         B     404(R0,R15)
         MVI   840(R15),0
         TM    0(R4),240
         BO    234(R0,R15)
         CLI   0(R4),193
         BZ    234(R0,R15)
         CLI   0(R4),194
         BZ    234(R0,R15)
         CLI   0(R4),195
*000190  02E3E7E3 400000C0 40400038 40400001  .TXT ..{  ..  ..
*0001A0  40004780 F0EA4800 F3664130 F36F4133   ...0...3...3?..
*0001B0  0012D500 40003000 4780F0EA 06304600  ..N. .....0.....
*0001C0  F0D29201 F34847F0 F1161830 43040000  0Kk.3..01.......
*0001D0  41400012 4334F36F 40404040 F0F0F0F6  . ....3?    0006
         BZ    234(R0,R15)
         LH    R0,870(R0,R15)
         LA    R3,879(R0,R15)
         LA    R3,18(R3,R0)
         CLC   0(1,R4),0(R3)
         BZ    234(R0,R15)
         BCTR  R3,R0
         BCT   R0,210(R0,R15)
         MVI   840(R15),1
         B     278(R0,R15)
         LR    R3,R0
         IC    R0,0(R4,R0)
         LA    R4,18(R0,R0)
         IC    R3,879(R4,R15)
*0001E0  02E3E7E3 400000F8 40400018 40400001  .TXT ..8  ..  ..
*0001F0  19304780 F1024640 F0F44940 F36447B0  ....1.. 04. 3...
*000200  F112920B 60004530 40404040 40404040  1.k.-...        
*000210  40404040 40404040 40404040 40404040                  
*000220  40404040 40404040 40404040 F0F0F0F7              0007
         CR    R3,R0
         BZ    258(R0,R15)
         BCT   R4,244(R0,R15)
         CH    R4,868(R0,R15)
         BNM   274(R0,R15)
         MVI   0(R6),11
*000230  02E3E7E3 40000110 40400038 40400001  .TXT ...  ..  ..
*000240  F1864144 F3829108 102A4710 F1369541  1f..3bj.....1.n.
*000250  40004780 F1369581 40004780 F1369201   ...1.na ...1.k.
*000260  600047F0 F13CD200 60004000 D6006000  -..01.K.-. .O.-.
*000270  10289108 102C4780 40404040 F0F0F0F8  ..j.....    0008
         BAL   R3,390(R0,R15)
         LA    R4,898(R4,R15)
         TM    42(R1),8
         BO    310(R0,R15)
         CLI   0(R4),65
         BZ    310(R0,R15)
         CLI   0(R4),129
         BZ    310(R0,R15)
         MVI   0(R6),1
         B     316(R0,R15)
         MVC   0(1,R6),0(R4)
         OC    0(1,R6),40(R1)
         TM    44(R1),8
         BZ    404(R0,R15)
*000280  02E3E7E3 40000148 40400038 40400001  .TXT ...  ..  ..
*000290  F1949180 10024710 F1540A07 91101003  1mj.....1...j...
*0002A0  4780F166 18314110 F3680A02 1813D200  ..1.....3.....K.
*0002B0  10401038 D2001038 1030D24F 10981048  . ..K.....K|.q..
*0002C0  58301030 D24F1048 40404040 F0F0F0F9  ....K|..    0009
         TM    2(R1),128
         BO    340(R0,R15)
         SVC   7
         TM    3(R1),16
         BZ    358(R0,R15)
         LR    R3,R1
         LA    R1,872(R0,R15)
         SVC   2
         LR    R1,R3
         MVC   64(1,R1),56(R1)
         MVC   56(1,R1),48(R1)
         MVC   152(80,R1),72(R1)
         L     R3,48(R0,R1)
         MVC   72(80,R1),0(R3)
*0002D0  02E3E7E3 40000180 40400018 40400001  .TXT ...  ..  ..
*0002E0  300047F0 F1940A00 91801002 4710F192  ...01m..j.....1k
*0002F0  0A0707F3 4530F186 40404040 40404040  ...3..1f        
*000300  40404040 40404040 40404040 40404040                  
*000310  40404040 40404040 40404040 F0F0F1F0              0010
         B     404(R0,R15)
         SVC   0
         TM    2(R1),128
         BO    402(R0,R15)
         SVC   7
         BR    R3
         BAL   R3,390(R0,R15)
*000320  02E3E7E3 40000198 40400038 40400001  .TXT ..q  ..  ..
*000330  9108102A 4780F1B0 9501F348 4780F1B0  j.....1.n.3...1.
*000340  92016000 4530F186 91011004 4710F1CC  k.-...1fj.....1.
*000350  91401005 4710F2CA 91101003 4710F2E2  j ....2.j.....2S
*000360  47F0F1E0 9108102A 40404040 F0F0F1F1  .01\j...    0011
         TM    42(R1),8
         BZ    432(R0,R15)
         CLI   840(R15),1
         BZ    432(R0,R15)
         MVI   0(R6),1
         BAL   R3,390(R0,R15)
         TM    4(R1),1
         BO    460(R0,R15)
         TM    5(R1),64
         BO    714(R0,R15)
         TM    3(R1),16
         BO    738(R0,R15)
         B     480(R0,R15)
         TM    42(R1),8
*000370  02E3E7E3 400001D0 40400038 40400001  .TXT ..}  ..  ..
*000380  4710F1E0 9102102C 4710F2B8 58E01040  ..1\j.....2..\. 
*000390  9826F314 9506101D 4770F200 91801003  q.3.n.....2.j...
*0003A0  4780F200 96401026 97801003 47F0F032  ..2.o ..p....00.
*0003B0  07FED200 10401050 40404040 F0F0F1F2  ..K.. .&    0012
         BO    480(R0,R15)
         TM    44(R1),2
         BO    696(R0,R15)
         L     R14,64(R0,R1)
         LM    R2,R6,788(R15)
         CLI   29(R1),6
         BNZ   512(R0,R15)
         TM    3(R1),128
         BZ    512(R0,R15)
         OI    38(R1),64
         XI    3(R1),128
         B     50(R0,R15)
         BR    R14
         MVC   64(1,R1),80(R1)
*0003C0  02E3E7E3 40000208 40400018 40400001  .TXT ...  ..  ..
*0003D0  D5001040 10484770 F2A85820 103C4A20  N.. ....2y......
*0003E0  F3601842 43401047 40404040 40404040  3-... ..        
*0003F0  40404040 40404040 40404040 40404040                  
*000400  40404040 40404040 40404040 F0F0F1F3              0013
         CLC   64(1,R1),72(R1)
         BNZ   680(R0,R15)
         L     R2,60(R0,R1)
         AH    R2,864(R0,R15)
         LR    R4,R2
         IC    R4,71(R0,R1)
*000410  02E3E7E3 40000220 40400038 40400001  .TXT ...  ..  ..
*000420  192447D0 F22E5A20 F3604320 10355020  ...}2.!.3-....&.
*000430  103CD503 103C1036 4740F29C 4780F24C  ..N...... 2...2<
*000440  9506101D 4770F15C 4780F254 9506101D  n.....1*..2.n...
*000450  4770F29C 91801026 40404040 F0F0F1F4  ..2.j...    0014
         CR    R2,R4
         BNP   558(R0,R15)
         A     R2,864(R0,R15)
         IC    R2,53(R0,R1)
         ST    R2,60(R0,R1)
         CLC   60(4,R1),54(R1)
         BM    668(R0,R15)
         BZ    588(R0,R15)
         CLI   29(R1),6
         BNZ   348(R0,R15)
         BZ    596(R0,R15)
         CLI   29(R1),6
         BNZ   668(R0,R15)
         TM    38(R1),128
*000460  02E3E7E3 40000258 40400038 40400001  .TXT ...  ..  ..
*000470  4780F268 9180102C 4780F27E 47F0F1CC  ..2.j.....2=.01.
*000480  4120F350 50201008 0A004530 F1884120  ..3&&.......1h..
*000490  10585020 10089006 F32C92FF F3344100  ..&.....3.k.3...
*0004A0  F3304110 F3580A02 40404040 F0F0F1F5  3...3...    0015
         BZ    616(R0,R15)
         TM    44(R1),128
         BZ    638(R0,R15)
         B     460(R0,R15)
         LA    R2,848(R0,R15)
         ST    R2,8(R0,R1)
         SVC   0
         BAL   R3,392(R0,R15)
         LA    R2,88(R0,R1)
         ST    R2,8(R0,R1)
         STM   R0,R6,812(R15)
         MVI   820(R15),255
         LA    R0,816(R0,R15)
         LA    R1,856(R0,R15)
         SVC   2
*0004B0  02E3E7E3 40000290 40400018 40400001  .TXT ...  ..  ..
*0004C0  9200F334 9806F32C 47F0F194 D2001040  k.3.q.3..01mK.. 
*0004D0  1049D203 104C103C 40404040 40404040  ..K..<..        
*0004E0  40404040 40404040 40404040 40404040                  
*0004F0  40404040 40404040 40404040 F0F0F1F6              0016
         MVI   820(R15),0
         LM    R0,R6,812(R15)
         B     404(R0,R15)
         MVC   64(1,R1),73(R1)
         MVC   76(4,R1),60(R1)
*000500  02E3E7E3 400002A8 40400038 40400001  .TXT ..y  ..  ..
*000510  43401040 41440001 42401050 47F0F194  . . ..... .&.01m
*000520  18214802 00064110 10160A02 181247F0  ...............0
*000530  F1E094DF 102C9147 10E84710 10E850E0  1\m...j..Y...Y&\
*000540  F32858E0 10E847F0 40404040 F0F0F1F7  3..\.Y.0    0017
         IC    R4,64(R0,R1)
         LA    R4,1(R4,R0)
         STC   R4,80(R0,R1)
         B     404(R0,R15)
         LR    R2,R1
         LH    R0,6(R2,R0)
         LA    R1,22(R0,R1)
         SVC   2
         LR    R1,R2
         B     480(R0,R15)
         NI    44(R1),223
         TM    232(R1),71
         BO    232(R0,R1)
         ST    R14,808(R0,R15)
         L     R14,232(R0,R1)
         B     758(R0,R15)
*000550  02E3E7E3 400002E0 40400038 40400001  .TXT ..\  ..  ..
*000560  F2F694DF 102C9147 10EC4710 10EC50E0  26m...j.......&\
*000570  F32858E0 10EC90F1 F32C5816 00009826  3..\...13.....q.
*000580  F3140700 070005EE 98F1E024 58E0F328  3.......q1\..\3.
*000590  47F0F032 00000000 40404040 F0F0F1F8  .00.....    0018
         NI    44(R1),223
         TM    236(R1),71
         BO    236(R0,R1)
         ST    R14,808(R0,R15)
         L     R14,236(R0,R1)
         STM   R15,R1,812(R15)
         L     R1,0(R6,R0)
         LM    R2,R6,788(R15)
         NOPR  R0
         NOPR  R0
         BALR  R14,R14
         LM    R15,R1,36(R14)
         L     R14,808(R0,R15)
         B     50(R0,R15)
         DC    X'0000'
         DC    X'0000'
*0005A0  02E3E7E3 40000318 40400018 40400001  .TXT ...  ..  ..
*0005B0  00000000 00000000 00000000 00000000  ................
*0005C0  00000000 00000000 40404040 40404040  ........        
*0005D0  40404040 40404040 40404040 40404040                  
*0005E0  40404040 40404040 40404040 F0F0F1F9              0019
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
*0005F0  02E3E7E3 40000330 40400038 40400001  .TXT ...  ..  ..
*000600  00000000 00000000 00000000 00000000  ................
*000610  00000000 00000000 00000000 00000000  ................
*000620  17000350 00000001 5B5BC2D6 D7C5D540  ...&....$$BOPEN 
*000630  00010000 000D0006 40404040 F0F0F2F0  ........    0020
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
* This is most likely data
*         XR    R0,R0
* And in fact, it appears to be an address somehow
* The x'350' is an offset from the beginning of this module to
* the start of this address field. ie the address of the address.
* But the value changes in this larger code.
*         DC    X'1700'
*         DC    X'0350'
         DC    X'17'
         DC    AL3(IJJFCBZD)
         DC    X'0000'
         DC    X'0001'
* This is data
*         S     R5,726(R11,R12)
*         XC    1344(198,R13),1(R0)
         DC    C'$$BOPEN '
         DC    X'0001'
         DC    X'0000'
         DC    X'000D'
         DC    X'0006'
*000640  02E3E7E3 40000368 4040002D 40400001  .TXT ...  ..  ..
*000650  5B5BC2C5 D9D9E3D5 F1F2F3F4 F5F6F7F8  $$BERRTN12345678
*000660  F9C1C2C3 4EE5E660 F0400B8B 939BA3AB  9ABC+VW-0 ..l.t.
*000670  B3BBC3CB D3DBE303 01411B13 0B404040  ..C.L.T......   
*000680  40404040 40404040 40404040 F0F0F2F1              0021
         DC    C'$$BERRTN'
         DC    C'123456789ABC'
         DC    X'4EE5'
         DC    X'E660'
         DC    X'F040'
         DC    X'0B8B'
         DC    X'939B'
         DC    X'A3AB'
         DC    X'B3BB'
         DC    X'C3CB'
         DC    X'D3DB'
         DC    X'E303'
         DC    X'0141'
         DC    X'1B13'
         DC    X'0B'
*
* This is data, not code:
*         S     R5,709(R11,R12)
***         MVCK  981(R13,R14),498(R15),R9
*         MVC  981(R13,R14),498(R15)
*         UNPK  1526(16,R15),2040(5,R15)
*         CP    707(13,R12),3813(2,R4)
*         DC    X'FFFFFFE660'
*         SRP   2955(5,R0),923(R9),0
*         DC    X'FFFFFFA3FFFFFFAB'
*         DC    X'FFFFFFB3FFFFFFBB'
*         DC    X'FFFFFFC3FFFFFFCB'
*         MVZ   771(220,R14),321(R0)
*         SR    R1,R3
*         DC    X'0B'
*         ORG   IJJFCBZD+X'351'
*         DC    AL3(IJJFCBZD)
*
*
*
* S/370 doesn't support switching modes so this code is useless,
* and won't compile anyway because "BSM" is not known.
*
         AIF   ('&ZSYS' EQ 'S370').NOMODE If S/370 we can't switch mode
***********************************************************************
*                                                                     *
*  SETM24 - Set AMODE to 24                                           *
*                                                                     *
***********************************************************************
         ENTRY @@SETM24
         USING @@SETM24,R15
@@SETM24 ICM   R14,8,=X'00'       Sure hope caller is below the line
         BSM   0,R14              Return in amode 24
*
***********************************************************************
*                                                                     *
*  SETM31 - Set AMODE to 31                                           *
*                                                                     *
***********************************************************************
         ENTRY @@SETM31
         USING @@SETM31,R15
@@SETM31 ICM   R14,8,=X'80'       Set to switch mode
         BSM   0,R14              Return in amode 31
         LTORG ,
*
.NOMODE  ANOP  ,                  S/370 doesn't support MODE switching
*
*
*
WORKAREA DSECT
SAVEAREA DS    18F
WORKLEN  EQU   *-WORKAREA
* Note that the handle starts from the WORKAREA DSECT, but
* initialization starts at ZDCBAREA (since we don't want to
* initialize our save area). Some more appropriate names
* should probably be found. And the WORKLEN is for functions
* unrelated to I/O which don't need access to the DCB stuff.
* ZDCBLEN includes the length of the work area, since the
* I/O functions still need a save area.
ZDCBAREA DS    0H
PTRDTF   DS    F                  Pointer to the DTF in use
DCBLRECL DS    F                  Logical record length
DCBRECFM DS    F                  Record format
*
* In the case of read, the internal assembler routines require
* a buffer (below the line) to read into, before the data can
* be given to the C caller.
* In the case of write, the C caller needs a BTL buffer to
* write to.
ASMBUF   DS    A                  Pointer to a 32k area for I/O
MEMBER24 DS    CL8
ISMEM    DS    F                  Flag whether this is a PDS
ISDI     DS    F                  Flag whether this is dev-independent
PMVF     DS    0F
P1VF     DS    A
P2VF     DS    A
P3VF     DS    A
P4VF     DS    A
ZDCBLEN  EQU   *-WORKAREA
*
         END
