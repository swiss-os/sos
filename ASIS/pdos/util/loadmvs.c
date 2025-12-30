/*********************************************************************/
/*                                                                   */
/*  This Program Written by Paul Edwards.                            */
/*  Released to the Public Domain                                    */
/*                                                                   */
/*********************************************************************/
/*********************************************************************/
/*                                                                   */
/*  loadmvs - load an MVS PE executable into memory and execute it   */
/*                                                                   */
/*  Need some JCL and run like this:                                 */
/*  runmvs loadmvs.jcl output.txt pdptest.exe                        */
/*                                                                   */
/*********************************************************************/

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    unsigned char *entry_point;
    unsigned char *p = NULL;
    char *prog_name = "dd:toload";
    int (*func)(void);
    int ret;
    int x;

    if (argc <= 2)
    {
        printf("loadmvs <MVS PE executable>\n");
        return (EXIT_FAILURE);
    }

    if (exeloadDoload(&entry_point, prog_name, &p) != 0)
    {
        printf("failed to load %s\n", prog_name);
        return (EXIT_FAILURE);
    }

    printf("loaded at %p\n", p);
    printf("executing %p\n", entry_point);
    func = (int (*)(void))entry_point;
    printf("func is still %p\n", func);
    for (x = 0; x < 26; x++)
    {
        printf("%p %02X\n", p + x, p[x]);
    }
    ret = func();
    printf("ret is %d\n", ret);

    return (0);
}
