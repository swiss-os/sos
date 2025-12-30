/******************************************************************************
 * @file            ucrtwrap.c
 *
 * Released to the public domain.
 *
 * Anyone and anything may copy, edit, publish, use, compile, sell and
 * distribute this work and all its parts in any form for any purpose,
 * commercial and non-commercial, without any restrictions, without
 * complying with any conditions and by any means.
 *****************************************************************************/
#include <stdio.h>

/* Ideal would be to split this file into multiple files
 * with individual functions, so only the needed
 * wrapper functions are imported into user programs.
 */

/* Modified mix of stdio.c and Public Domain code copied
 * from public domain parts of mingw-w64,
 * still public domain.
 */
 
int printf(const char *format, ...)
{
    va_list arg;
    int ret;

    va_start(arg, format);
    ret = __stdio_common_vfprintf (_CRT_INTERNAL_LOCAL_PRINTF_OPTIONS,
                                   stdout,
                                   format,
                                   NULL,
                                   arg);
    va_end(arg);
    return (ret);
}

int fprintf(FILE *stream, const char *format, ...)
{
    va_list arg;
    int ret;

    va_start(arg, format);
    ret = __stdio_common_vfprintf (_CRT_INTERNAL_LOCAL_PRINTF_OPTIONS,
                                   stream,
                                   format,
                                   NULL,
                                   arg);
    va_end(arg);
    return (ret);
}

int vfprintf(FILE *stream, const char *format, va_list arg)
{
    int ret;

    ret = __stdio_common_vfprintf (_CRT_INTERNAL_LOCAL_PRINTF_OPTIONS,
                                   stream,
                                   format,
                                   NULL,
                                   arg);
    return (ret);
}

int vprintf(const char *format, va_list arg)
{
    int ret;

    ret = __stdio_common_vfprintf (_CRT_INTERNAL_LOCAL_PRINTF_OPTIONS,
                                   stdout,
                                   format,
                                   NULL,
                                   arg);
    return (ret);
}

int sprintf(char *s, const char *format, ...)
{
    va_list arg;
    int ret;

    va_start(arg, format);
    ret = __stdio_common_vsprintf (_CRT_INTERNAL_LOCAL_PRINTF_OPTIONS
                                   | _CRT_INTERNAL_PRINTF_STANDARD_SNPRINTF_BEHAVIOR,
                                   s,
                                   (size_t)-1,
                                   format,
                                   NULL,
                                   arg);
    va_end(arg);
    return (ret);
}

int vsprintf(char *s, const char *format, va_list arg)
{
    int ret;

    ret = __stdio_common_vsprintf (_CRT_INTERNAL_LOCAL_PRINTF_OPTIONS
                                   | _CRT_INTERNAL_PRINTF_STANDARD_SNPRINTF_BEHAVIOR,
                                   s,
                                   (size_t)-1,
                                   format,
                                   NULL,
                                   arg);
    return (ret);
}

int fscanf(FILE *stream, const char *format, ...)
{
    va_list arg;
    int ret;

    va_start(arg, format);
    ret = __stdio_common_vfscanf (_CRT_INTERNAL_LOCAL_SCANF_OPTIONS,
                                  stream,
                                  format,
                                  NULL,
                                  arg);
    va_end(arg);
    return (ret);
}

int scanf(const char *format, ...)
{
    va_list arg;
    int ret;

    va_start(arg, format);
    ret = __stdio_common_vfscanf (_CRT_INTERNAL_LOCAL_SCANF_OPTIONS,
                                  stdin,
                                  format,
                                  NULL,
                                  arg);
    va_end(arg);
    return (ret);
}

int sscanf(const char *s, const char *format, ...)
{
    va_list arg;
    int ret;

    va_start(arg, format);
    ret = __stdio_common_vsscanf (_CRT_INTERNAL_LOCAL_SCANF_OPTIONS,
                                  s,
                                  (size_t)-1,
                                  format,
                                  NULL,
                                  arg);
    va_end(arg);
    return (ret);
}

static unsigned __int64 options = (_CRT_INTERNAL_PRINTF_LEGACY_WIDE_SPECIFIERS
                                   | _CRT_INTERNAL_PRINTF_STANDARD_ROUNDING);

unsigned __int64 *__local_stdio_printf_options (void)
{
    return &options;
}

static unsigned __int64 scanf_options = _CRT_INTERNAL_SCANF_LEGACY_WIDE_SPECIFIERS;

unsigned __int64 * __local_stdio_scanf_options (void)
{
    return &scanf_options;
}
