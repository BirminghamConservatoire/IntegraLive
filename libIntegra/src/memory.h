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

#ifndef INTEGRA_MEMORY_H
#define INTEGRA_MEMORY_H

#include <stdlib.h>

#include "Integra/integra.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * \file memory.h 
 */

#if DEBUG_MEM_VERBOSE == 1
#define ntg_free(x) ntg_free_debug(x, __FILE__, __FUNCTION__, __LINE__)
#else
#define ntg_free(x) ntg_free_(x)
#endif


/** \brief Wrapper for glibc calloc function
 *
 * allocates memory for an array of nmemb elements of size bytes
 * each and returns a pointer to the allocated memory.  The memory is  set
 * to zero.
 *
 * \param size_t nmemb The number of elements to allocate
 * \param size_t size The size in bytes of each element
 * */
void *ntg_calloc(size_t nmemb, size_t size);

/** \brief Wrapper for glibc malloc function 
 *
 *  allocates  size  bytes and returns a pointer to the allocated 
 *  memory.  The memory is not cleared. 
 *
 * \param size_t size The size in bytes of each element
 *
 * */
void *ntg_malloc(size_t size);

/** \brief Wrapper for glibc free function 
 *
 * frees the memory space pointed to by ptr, which must  have  been
 * returned by a previous call to ntg_malloc(), ntg_calloc() or ntg_realloc().  
 * Other‐wise, or  if  ntg_free(ptr)  has  already  been  called  before,  
 * undefine behaviour occurs.  If ptr is NULL, no operation is performed.
 *
 * \param void *ptr a pointer to the memory to be freed
 *
 * */
void ntg_free_(void *ptr);
void ntg_free_debug(void *ptr, char *file, const char *function, int line);

/** \brief Wrapper for glibc realloc function 
 *
 * changes  the  size  of the memory block pointed to by ptr to size bytes. 
 * The contents will be unchanged to the minimum of  the  old  and new sizes; 
 * newly allocated memory will be uninitialized.  If ptr is  NULL, the call is 
 * equivalent to ntg_malloc(size); if size is equal to zero,  the  call is 
 * equivalent to ntg_free(ptr).  Unless ptr is NULL, it must have  been 
 * returned by an earlier call to ntg_malloc(),  ntg_calloc()  or  
 * ntg_realloc().  If the area pointed to was moved, a free(ptr) is done. 
 *
 * \param void *ptr a pointer to the memory to the memory to be reallocated
 * \param size_t size The size in bytes of the new memory block
 *
 * */
void *ntg_realloc(void *ptr, size_t size);


#ifdef __cplusplus
}
#endif

#endif
