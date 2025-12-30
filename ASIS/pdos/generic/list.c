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

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <assert.h>
#include <unused.h>
#include "list.h"

static void cpy_char(void *dst, void *src, int sztype);
static int cmp_char(void *dst, void *src, int sztype);
static void cpy_int(void *dst, void *src, int sztype);
static int cmp_int(void *dst, void *src, int sztype);
static void cpy_double(void *dst, void *src, int sztype);
static int cmp_double(void *dst, void *src, int sztype);
static void cpy_other(void *dst, void *src, int sztype);
static int cmp_other(void *dst, void *src, int sztype);
static void init_func_generic(list_t *list, int sztype, cpy_cb_fn cp, cmp_cb_fn cmp);

static item_t *clone_item(int sztype, void *data, cpy_cb_fn cpy_fp)
{
    item_t *temp_node = (item_t *)malloc(sizeof(item_t));
    if (temp_node)
    {
        temp_node->m_data = malloc(sztype);
        cpy_fp(temp_node->m_data, data, sztype);
        temp_node->m_prev = NULL;
        temp_node->m_next = NULL;
        return temp_node;
    }
    return NULL;
}

static void free_item(item_t **item)
{
    if (*item)
    {
        (*item)->m_next = NULL;
        (*item)->m_prev = NULL;
        if ((*item)->m_data)
        {
            free((*item)->m_data);
            (*item)->m_data = NULL;
        }
        free((*item));
        (*item) = NULL;
    }
}

list_t *list_init(int sztype, ...)
{
    list_t *list = (list_t *)malloc(sizeof(list_t));
    if (list)
    {
        cpy_cb_fn cp = NULL;
        cmp_cb_fn cmp = NULL;
        va_list ap;
        va_start(ap, sztype);
        cp = (cpy_cb_fn)va_arg(ap, cpy_cb_fn);
        if (cp)
        {
            cmp = (cmp_cb_fn)va_arg(ap, cmp_cb_fn);
        }
        va_end(ap);

        switch (sztype)
        {
        case sizeof(char):
            if (!cp)
                cp = cpy_char;
            if (!cmp)
                cmp = cmp_char;
            break;

        case sizeof(int):
            if (!cp)
                cp = cpy_int;
            if (!cmp)
                cmp = cmp_int;
            break;

        case sizeof(double):
            if (!cp)
                cp = cpy_double;
            if (!cmp)
                cmp = cmp_double;
            break;

        default:
            if (!cp)
                cp = cpy_other;
            if (!cmp)
                cmp = cmp_other;
            break;
        }

        list->m_sztype = sztype;
        list->m_size = 0;
        list->m_first = NULL;
        list->m_last = NULL;
        init_func_generic(list, sztype, cp, cmp);
        return list;
    }
    return NULL;
}

/*define generic fuctions*/
static void add_clone(list_t *self, void *val)
{
    item_t *item;
    if (!self) return;
    if (!self->cp_data)
    {
        printf("Define copy data function, size of this type: %d\n", self->m_sztype);
    }
    assert(self->cp_data != NULL);
    item = clone_item(self->m_sztype, val, (cpy_cb_fn)self->cp_data);
    if (self->m_size == 0)
    {
        self->m_first = item;
        self->m_last = item;
        item->m_prev = NULL;
        item->m_next = NULL;
    }
    else
    {
        item->m_prev = (struct item_t *)(self->m_last);
        self->m_last->m_next = (struct item_t *)item;
        item->m_next = NULL;
        self->m_last = item;
    }
    self->m_size++;
}

static item_t *find(list_t *self, void *val)
{
    item_t *next;
    item_t *prev;
    
    if (!self) return NULL;
    if (!self->cmp_data) return NULL;
    
    next = self->m_first;
    prev = self->m_last;

    while (next && prev)
    {
        if ((self->cmp_data)(next->m_data, val, self->m_sztype) == 0)
        {
            return next;
        }
        if ((self->cmp_data)(prev->m_data, val, self->m_sztype) == 0)
        {
            return prev;
        }
        if (prev == next)
            break;

        next = (item_t *)(next->m_next);
        prev = (item_t *)(prev->m_prev);
    }
    return NULL;
}

static void delete(list_t *self, void *val)
{
    item_t *item;

    if (!self) return;
    item = (self->find)(self, val);
    if (item == self->m_first)
    {
        self->m_first = (item_t *)(item->m_next);
        self->m_first->m_prev = NULL;
    }
    else if (item == self->m_last)
    {
        self->m_last = (item_t *)(item->m_prev);
        self->m_last->m_next = NULL;
    }
    else
    {
        ((item_t *)item->m_prev)->m_next = item->m_next;
        ((item_t *)item->m_next)->m_prev = item->m_prev;
    }

    /*free item*/
    free_item(&item);
    self->m_size--;
}

static void clean_all(list_t *self)
{
    item_t *item;
    item_t *cur;

    if (!self) return;
    
    cur = self->m_first;
    while (cur)
    {
        item = cur;
        cur = (item_t *)item->m_next;
        free_item(&item);
    }
    /*self->m_sztype = 0;*/
    self->m_size = 0;
    self->m_first = NULL;
    self->m_last = NULL;
}

/*define specific functions based on data type*/
/********char type*******/
static void cpy_char(void *dst, void *src, int sztype)
{
    unused(sztype);
    *(char *)dst = *(char *)src;
}

static int cmp_char(void *dst, void *src, int sztype)
{
    int ret;
    unused(sztype);
    ret = (((char*)dst)[0] == ((char*)src)[0]);
    return (ret == 1 ? 0 : 1);
}

/********int type*******/
static void cpy_int(void *dst, void *src, int sztype)
{
    unused(sztype);
    *(int *)dst = *(int *)src;
}

static int cmp_int(void *dst, void *src, int sztype)
{
    int ret;
    unused(sztype);
    ret = (*(int *)dst == *(int *)src);
    return (ret == 1 ? 0 : 1);
}

/********double type*******/
static void cpy_double(void *dst, void *src, int sztype)
{
    unused(sztype);
    *(double *)dst = *(double *)src;
}

static int cmp_double(void *dst, void *src, int sztype)
{
    int ret;
    unused(sztype);
    ret = (*(double *)dst == *(double *)src);
    return (ret == 1 ? 0 : 1);
}

/********other type*******/

static void cpy_other(void *dst, void *src, int sztype)
{
    char *p_dst = (char *)dst;
    char *p_src = (char *)src;
    memcpy(p_dst, p_src, sztype);
}

static int cmp_other(void *dst, void *src, int sztype)
{
    int ret;
    ret = memcmp(dst, src, sztype);
    return ret;
}

static void init_func_generic(list_t *list, int sztype, cpy_cb_fn cp, cmp_cb_fn cmp)
{
    list->add_clone = (add_clone_cb_fn)add_clone;
    list->delete = (del_cb_fn)delete;
    list->clean_all = (clean_all_cb_fn)clean_all;
    list->find = (find_cb_fn)find;
    list->cp_data = cp;
    list->cmp_data = cmp;
}
