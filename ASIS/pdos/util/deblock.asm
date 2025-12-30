* DEBLOCK A FILE WITH EMBEDED HALF WORD RECORD LENGTHS.
*
* CMS modules can have record lengths up to 64K-1 you can't use
* OS emulation as this is limited to 32K-1.
*
* written by Dave Wade 28-11-2025 and placed in the public domain
*
* USAGE
*           DEBLOCK <file-name>
*
* Where
*    <FILE-NAME> PACKED   INPUT FILE WITH EMBEDDED RECORD LENGTHS
*    <FILE-NAME> UNPACKED RE-BLOCKED OUTPUT FILE
*
* Limitations
*
*    1. If <file-name> is omitted it defaults to TMP-FILE
*
*    2. If the output module exists things go tubesville arizona.
*
*        R1 points to the CMS tokenized parameter list:
*
*              DC CL8'our name'
*              DC CL8'Module-Name'     (optional)
*              DC XL8'FFFFFFFF'
*
*
* Register Usage
*
*
*   R1 & R2 = => Parameters for CMS Macros
*
*   R3 - Address of Input Buffer
*   R4 - POINTER TO CURRENT CHAR IN INPUT BUFFER
*   R5 - Number of bytes left in input buffer
*
*   R7 - POINTER TO DISK BUFFER
*   R8 - POINTER TO NEXT FREE BYTE IN DISK BUFFER
*   R9 - NUMBER OF BYTES LEFT TO WRITE
*
*
         SPACE
DEBLOCK  CSECT
         SAVE (14,12)
         BALR  12,0
         USING *,R12
* INIT REGS
         SR    R5,R5          * START WITH EMPTY BUFFER
         SR    R8,R8          * NO BYTES TO WRITE
         ST    R8,INCHARS
         ST    R8,RECLN       * CLEAR RECORD LENGTH
*
*
* SEE IF A PARMAMETER WAS ENTERED
*
* Looks ok, stuff it in the RDTAPE Plist.
*
         CLC   8(8,R1),=XL8'FFFFFFFFFFFFFFFF'    Is there a filename
         BE    NOPARM                            No skip
         MVC   INSPEC,8(R1)     YES OVERWRITE FSREAD FILE SPEC
         MVC   OTSPEC,8(R1)     YES OVERWRITE FSWITE FILE SPEC
NOPARM   DS    0H
*
* OBTAIN DATA BUFFERS
*
         LA    0,=AL2(65536/8)    LENGTH OF 64K BUFFER
         DMSFREE DWORDS=(0)       OBTAIN IT FROM CMS
         ST    R1,INBUF            SAVE BUFFER ADDRESS
         LR    R3,R1
*
         LA    0,=AL2(65536/8)    LENGTH OF 64K BUFFER
         DMSFREE DWORDS=(0)       OBTAIN IT FROM CMS
         ST    R1,OTBUF           SAVE BUFFER ADDRESS
         LR    R7,R1              POINT TO BUFFER
         LR    R8,R1              WHERE HAVE WE GOT TO
*        LINEDIT TEXT='INBUF ........ OTBUFF ........',                X
               SUB=(HEX,(R3),HEX,(R7)),RENT=NO,DOT=NO
*
*  MAIN LOOP - DO WE HAVE ANY DATE
*
MAIN     LTR   R5,R5             ANY DATA?
         BNZ   GETMSB            YES - EXTRACT MSB
         BAL   R11,RDDATA        NO - GET SOME
         LTR   R5,R5             DID WE GET ANY ?
         BZ    GOBACK            NO EXIT
*        LINEDIT TEXT='DATAM= ................................... ',   X
               SUB=(HEX4A,(R4)),RENT=NO,DOT=NO
GETMSB   EQU   *
         MVC   RECLN3,0(4)
         S     R5,=F'1'
         A     R4,=F'1'
* NOW LSB
         LTR   R5,R5             ANY DATA?
         BNZ   GETLSB            YES - EXTRACT MSB
         BAL   R11,RDDATA        NO - GET SOME
         LTR   R5,R5             DID WE GET ANY ?
         BZ    GOBACK            NO EXIT
*        LINEDIT TEXT='DATA = ................................... ',   X
               SUB=(HEX4A,(R4)),RENT=NO,DOT=NO
GETLSB   EQU   *
         MVC   RECLN4,0(4)
         S     R5,=F'1'
         A     R4,=F'1'
*        LINEDIT TEXT='RECLN = ........',                              X
               SUB=(DECA,RECLN),RENT=NO,DOT=NO
         L     R6,RECLN
*
* GO A RECORD LENGTH - MOVE TO DISK BUFFER
*
MOVE1    EQU   *
*        LINEDIT TEXT='NEED = ........ HAVE = ........',               X
               SUB=(DEC,(R6),DEC,(R5)),RENT=NO,DOT=NO
         CR    R6,R5          * DO WE HAVE ENOUGH CHARACTERS
         BH    GETMORE        * NO WE NEED MORE
*
*  PUT THE LAST FEW CHARACTERS IN THE BUFFER AND WRITE IT OUT
*
         ST    R5,INCHARS     * SAVE NUMBER OF BYTES LEFT
         LR    R5,R6          *
         LR    R9,R6          *
*        LINEDIT TEXT='MVCL = ........  ........ ........ ........',   X
               SUB=(HEX,(R8),HEX,(R9),HEX,(R4),HEX,(R5)),              X
               RENT=NO,DOT=NO
         MVCL  R8,R4          * MOVE THE DATA
         L     R5,INCHARS     * PUT IN OLD COUNT
         SR    R5,R6          * TAKE OFF THE LAST FEW
         SR    R6,R6          * CLEAR COUNTER
*
*  WRITE IT OUT
*
         LA    R2,OTSPEC      * POINT TO FILE SPEC
         L     R9,RECLN
         FSWRITE (R2),BUFFER=(R7),BSIZE=(R9),RECFM=V
         LR    R8,R7          * SET TO BUFFER
         SR    R9,R9          * ZERO COUNT
*
*
*
         B     MAIN           * PROCESS THE NEXT RECORD..
*
* WE NEED MORE - MOVE WHAT WE HAVE THEN GET ANOTHER RECORD
*
GETMORE  EQU   *
         LTR   R5,R5          * DO WE HAVE ANY ?
         BZ    GETM1          * NO
         LR    R9,R5          * WE HAVE R5 BYTES TO MOVE
         SR    R6,R5          * REDUCE R6 BY COUNT WE ARE MOVING
*        LINEDIT TEXT='MVCL = ........  ........ ........ ........',   X
               SUB=(HEX,(R8),HEX,(R9),HEX,(R4),HEX,(R5)),              X
               RENT=NO,DOT=NO
         MVCL  R8,R4          * MOVE THE DATA
GETM1    BAL   R11,RDDATA     *  NO - GET SOME
         LTR   R5,R5          *  DID WE GET ANY ?
         BZ    GOBACK         *  NO EXIT
*        LINEDIT TEXT='DATA = ................................... ',   X
               SUB=(HEX4A,(R4)),RENT=NO,DOT=NO
         B     MOVE1
*
*  RETURN
GOBACK   EQU     *
         LA    0,=AL2(65536/8)    LENGTH OF 64K BUFFER
         L     R1,INBUF
         DMSFRET DWORDS=(0),LOC=(1)   GIVE IT BACK TO CMS
*
         LA    0,=AL2(65536/8)    LENGTH OF 64K BUFFER
         L     R1,OTBUF
         DMSFRET DWORDS=(0),LOC=(1)   GIVE IT BACK TO CMS
         LA    R8,OTSPEC
         FSCLOSE (R8)              CLOSE OUTPUT FILE
         RETURN (14,12),RC=0
*
* READ A RECORD
*
RDDATA   L     R3,INBUF            POINT TO DISK BUFFER
         LA    R2,INSPEC           POINT TO FILE SPEC
         FSREAD (2),BUFFER=(3),BSIZE=65535,NOREC=1,RECNO=0
         LR    R5,R0               SAVE BYTES IN INPUT BUFFER
         LR    R4,R3               RESET BUFFER POINTER
         LR    R10,R15             SAVE RETURN CODE
*        LINEDIT TEXT='FSREAD RC= .. RECLN = ........',                X
               SUB=(HEX,(R10),DEC,(R5)),RENT=NO,DOT=NO
         BR    R11
*
* SPACE FOR INPUT FILE NAME
*
INSPEC   DC     CL8'TMP-FILE'
         DC     CL8'PACKED  '
         DC     CL2'A1'
*
* OUTPUT
*
OTSPEC   DC     CL8'TMP-FILE'
         DC     CL8'UNPACKED'
         DC     CL2'A1'
*
* BUFFER POINTERS
*
INBUF    DS     1F
INPTR    DS     1F
INCHARS  DS     1F
*
OTBUF    DS     1F
OTPTR    DS     1F
OTCHARS  DS     1F
*
* RECORD LENGTH
*
RECLN    DS     0F
RECLN1   DS     C'0'
RECLN2   DS     C'0'
RECLN3   DS     C'0'
RECLN4   DS     C'0'
         LTORG
         REGEQU
         SPACE 2
         END
