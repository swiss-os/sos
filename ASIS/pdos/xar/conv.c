/******************************************************************************
 * @file            conv.c
 *****************************************************************************/
#include    "stdint.h"

uint32_t conv_dec (char *str, int32_t max) {

    char ch;
    uint32_t value = 0;
    
    while ((ch = *str)) {
    
        if (ch == ' ' || max == 0) {
            break;
        }
        
        value *= 10;
        
        value += (ch - '0');
        str++;
    
    }
    
    return value;

}
