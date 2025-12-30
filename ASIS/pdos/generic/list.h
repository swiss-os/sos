/*********************************************************************/
/*                                                                   */
/*  This Program Written by Dat Nguyen.                              */
/*  Released to the Public Domain                                    */
/*                                                                   */
/*********************************************************************/
/*********************************************************************/
/*                                                                   */
/*  list.c - implementation of stuff in list.h                       */
/*                                                                   */
/*********************************************************************/
#ifndef __LIST_INCLUDED
#define __LIST_INCLUDED

#include <stdio.h>

typedef struct
{
    void *m_data;
    struct item_t *m_prev;
    struct item_t *m_next;
} item_t;

typedef void (*add_clone_cb_fn)(void *list, void *val);
typedef void (*del_cb_fn)(void *list, void *val);
typedef void (*clean_all_cb_fn)(void *list);
typedef item_t *(*find_cb_fn)(void *list, void *val);

typedef void (*cpy_cb_fn)(void *dst, void *src, int sztype);
typedef int (*cmp_cb_fn)(void *dst, void *src, int sztype);

typedef struct
{
    unsigned int m_sztype;
    unsigned int m_size;
    item_t *m_first;
    item_t *m_last;

    /**
     * new a item_t and copy data to this.
     */
    add_clone_cb_fn add_clone;
    del_cb_fn delete;
    clean_all_cb_fn clean_all;
    find_cb_fn find;
    cpy_cb_fn cp_data;
    cmp_cb_fn cmp_data;

} list_t;


/**
 * if type is not Primary Data Type in C, then cpy_cb_fn and cmp_cb_fn should be defined for that.
 * @param: sztype is sizeof data type.
 */
list_t *list_init(int sztype, ...);
#endif
