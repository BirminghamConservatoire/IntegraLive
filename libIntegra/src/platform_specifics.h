/* libIntegra modular audio framework
 *
 * Copyright (C) 2007 Birmingham City University
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, 
 * USA.
 */


#ifndef INTEGRA_PLATFORM_SPECIFICS_PRIVATE_H
#define INTEGRA_PLATFORM_SPECIFICS_PRIVATE_H


#ifdef _WINDOWS
#include "windows_build_stuff.h"
#define MIN( a, b ) ( ( a < b ) ? a : b )
#define MAX( a, b ) ( ( a > b ) ? a : b )
#endif

#if !defined MAX
#define MAX(a,b) \
    ({ __typeof__ (a) __a = (a); \
     __typeof__ (b) __b = (b); \
     __a > __b ? __a : __b; })
#endif

#if !defined MIN
#define MIN(a,b) \
    ({ __typeof__ (a) __a = (a); \
     __typeof__ (b) __b = (b); \
     __a < __b ? __a : __b; })
#endif

#ifdef __APPLE__

#if !defined sprintf_s
#define sprintf_s sprintf_s_alt
#define vsprintf_s vsprintf_s_alt
#include <string.h>
#include <stdarg.h>
int sprintf_s_alt (char *str, size_t size, const char *format, ...);
int vsprintf_s_alt (char *str, size_t size, const char *format, va_list ap);
#endif

#endif /* __APPLE__ */


#endif
