/* libIntegra multimedia module interface
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

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _WINDOWS
#include "windows_build_stuff.h"
#define MIN min
#define MAX max
#endif

#ifdef __APPLE__
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
#endif /* __APPLE__ */

#ifdef __cplusplus
}
#endif

#endif
