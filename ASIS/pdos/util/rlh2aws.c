/*********************************************************************/
/*                                                                   */
/*  This Program Written by Paul Edwards.                            */
/*  Released to the Public Domain                                    */
/*                                                                   */
/*********************************************************************/
/*********************************************************************/
/*                                                                   */
/*  rlh2aws - convert a CMS RECFM=V with 2-byte length values        */
/*  (RLH - record length halfword) to a RECFM=U NL AWS tape          */
/*                                                                   */
/*********************************************************************/

#if 0
000000  05000000 A000C1C2 F1F2F302 000500A0  ................
000010  00C3C403 000200A0 00C5C6F1 02000300  ................
000020  A000C7C8 00000200 40000000 00004000  ........@.....@.
#endif

/* AWS tape consists of length of next record (2 bytes, little endian),
   then length of previous record (so zero if this is the first record,
   and this allows you to go backwards - a sort of linked list.
   Then x'A000' which I don't know what is for, but it is fixed in
   my tests.
   Then the data.
   And then this repeats until the end, which is signified by a
   next record of 0, then the previous record length,
   then x'40000000 00004000'.
*/

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    FILE *fp;
    FILE *fq;
    unsigned char rlh[2];
    unsigned char prev[2] = { 0, 0 };
    unsigned char *buf;

    if (argc != 3)
    {
        printf("usage: rlh2aws <in CMS executable> <out AWS tape>\n");
        exit(EXIT_FAILURE);
    }
    fp = fopen(argv[1], "rb");
    if (fp == NULL)
    {
        printf("failed to open %s for reading\n", argv[1]);
        exit(EXIT_FAILURE);
    }
    fq = fopen(argv[2], "wb");
    if (fq == NULL)
    {
        printf("failed to open %s for writing\n", argv[2]);
        exit(EXIT_FAILURE);
    }
    buf = malloc(65535U);
    if (buf == NULL)
    {
        printf("insufficient memory - need 64k\n");
        exit(EXIT_FAILURE);
    }
    while (1)
    {
        if (fread(rlh, sizeof rlh, 1, fp) != 1)
        {
            break;
        }
        fputc(rlh[1], fq);
        fputc(rlh[0], fq);
        fputc(prev[1], fq);
        fputc(prev[0], fq);
        memcpy(prev, rlh, 2);
        fwrite("\xA0\x00", 2, 1, fq);
        if (fread(buf, (rlh[0] << 8) | rlh[1], 1, fp) != 1)
        {
            printf("error reading input file\n");
            exit(EXIT_FAILURE);
        }
        fwrite(buf, (rlh[0] << 8) | rlh[1], 1, fq);
    }
    fwrite("\x00\x00", 2, 1, fq);
    fputc(prev[1], fq);
    fputc(prev[0], fq);
    fwrite("\x40\x00\x00\x00\x00\x00\x40\x00", 8, 1, fq);
    fclose(fp);
    fclose(fq);
    return (0);
}
