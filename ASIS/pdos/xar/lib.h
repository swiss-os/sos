/******************************************************************************
 * @file            lib.h
 *****************************************************************************/
#ifndef     _LIB_H
#define     _LIB_H

char *xstrdup (const char *str);
char *xstrndup (const char *__p, unsigned long __size);

unsigned long array_to_integer (unsigned char *arr, int size, int bigendian);

void *xmalloc (unsigned long size);
void *xrealloc (void *ptr, unsigned long size);

void dynarray_add (void *ptab, long *nb_ptr, void *data);
void parse_args (int *pargc, char ***pargv, int optind);

#endif      /* _LIB_H */
