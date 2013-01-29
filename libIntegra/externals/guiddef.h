
#ifndef GUIDDEF_H
#define GUIDDEF_H

#ifdef _WINDOWS 
#include <guiddef.h>
#else
#include <stdint.h>

typedef struct _GUID {
    uint32_t  Data1;
    uint16_t Data2;
    uint16_t Data3;
    uint8_t  Data4[ 8 ];
} GUID;

#endif /* #ifdef _WINDOWS */
#endif /* #ifndef GUIDDEF_H */
