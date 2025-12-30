* zshim - support 64-bit z/Arch under 32-bit
*
* Written by Paul Edwards
* Released to the public domain
*
*
*
#if REALHLASM
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
#endif
*
         AMODE ANY
         RMODE ANY
         CSECT
*
*
*
* We will receive control with a 32-bit stack, but we
* need to switch to a 64-bit stack
*
         DS    0H
         ENTRY E64ENT
E64ENT   DS    0H
         USING *,R12
         STM   R14,R12,12(R13)
         LR    R12,R15
         L     R15,76(,R13)
         ST    R13,4(,R15)
         ST    R15,8(,R13)
         LR    R13,R15
         A     R15,=A(96)
         ST    R15,76(,R13)
*
* First preserve R13
*
         LGR   R9,R13
*
* Now set up the 64-bit version of the stack
*
         L     R15,76(,R13)
         LGR   R13,R15
* It would be nice to have the proper backchain,
* but we are not currently doing that
*
* Dont use AG unless you support a 64-bit literal
         A     R15,=A(192)
         STG   R15,152(,R13)
*
         SGR   R2,R2
         L     R2,0(R1)
         STG   R2,176(,R13)
         LA    R1,176(,R13)
*
         SGR   R15,R15
         L     R15,=V(CB64ENT)
         L     R15,0(R15)
         BALR  R14,R15
*
         LGR   R13,R9
*
         L     R13,4(,R13)
         L     R14,12(,R13)
         LM    R0,R12,20(R13)
         BR    R14
         LTORG
*
*
*
*
* This is a 64-bit entry point
* But we are operating in 32-bit
* So we need to convert parameters to 32-bit
* We are only using 32-bit registers, so only
* need to save those halves for now.
* But we really need to save the full 64 bits
* and clear them as it is possible a negative
* number may populate the high bits. Not sure
* about that.
* But the stack is currently 64-bit, so we need
* to respect that.
*
         DS    0H
         ENTRY GPRINTF
GPRINTF  DS    0H
         USING *,R12
         STMG  R14,R12,8(R13)
         LGR   R12,R15
         LG    R15,152(,R13)
         STG   R13,128(,R15)
         STG   R15,136(,R13)
         LGR   R13,R15
*
* Dont use AG unless you have 64-bit literals
*         AG    R15,=A(192)
         A     R15,=A(192)
         STG   R15,152(,R13)
*
* Make the stack look like 32-bit
*
* First preserve R13
         LGR   R9,R13
*
* extra 4 bytes (156 instead of 152) because we want the
* lower 4 bytes
         L     R15,156(,R13)
         LR    R13,R15
         A     R15,=A(96)
         ST    R15,76(,R13)
*
* We want the second 4 bytes of the 8 byte string pointer
* ie the lower half of the 64-bit address
         L     R2,4(,R1)
         ST    R2,88(,R13)
         LA    R1,88(,R13)
         L     R15,=V(PRINTF)
         BALR  R14,R15
*
* Go back to previous 64-bit stack
         LGR   R13,R9
*
         LG    R13,128(,R13)
         LG    R14,8(,R13)
         LMG   R0,R12,24(R13)
         BR    R14
         LTORG
         DROP  R12
*
*
*
         END
