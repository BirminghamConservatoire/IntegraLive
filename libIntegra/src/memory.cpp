/** libIntegra multimedia module interface
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

#include "platform_specifics.h"

#include <stdio.h>
#include <errno.h>
#include <assert.h>
#include <pthread.h>
#include <string.h>

#include "memory.h"
#include "globals.h"



char *ntg_change_string_length( char *string, int new_length )
{
	assert( new_length >= 0 );

	int old_length = string ? strlen( string ) : 0;

	char *new_string = new char[ new_length + 1 ];
	if( string )
	{
		memcpy( new_string, string, MIN( old_length, new_length ) + 1 );
		delete[] string;
	}
	new_string[ new_length ] = 0;

	return new_string;
}



/* the following methods are deprecated by the switch to c++ and new/delete */
#if 0


void ntg_free_debug(void *ptr, char *file, const char *function, int line)
{
	char trace[NTG_LONG_STRLEN];
	snprintf(trace, NTG_LONG_STRLEN, "%s: %s(): line %d: ", file, function, line);
    NTG_TRACE_VERBOSE(trace);

    ntg_free_(ptr);
}


static void *ntg_alloc(size_t size)
{

    void *mem = NULL;

    if(size==0) {
        /* malloc(0) is implementation defined - make it consistent */
        return NULL;
    }

    errno = 0;

    mem = malloc(size);

    if (errno) {
        NTG_TRACE_ERROR_WITH_ERRNO("malloc failed");
        assert(false);
    }

    /* FIX: The comparison with EBADF is a complete kludge to work round a *
       bug on OS X, where errno seems to b global rather than per-thread! */
    if (errno && errno != EBADF) {
        assert(false);
        return NULL;
    } else {
        assert(mem != NULL);
        return mem;
    }
}

void *ntg_calloc(size_t nmemb, size_t size)
{
    void *mem = ntg_alloc(nmemb*size);
    memset(mem, 0, nmemb * size);
    return mem;
}

void *ntg_malloc(size_t size)
{
    return ntg_alloc(size);
}


void ntg_free_(void *ptr)
{

    if (ptr == NULL) {
        /* It's according to the standard to free(NULL), but we shouldn't see 
         it here */
        NTG_TRACE_ERROR("attempt to free NULL pointer");
        assert(false);
    }

    free(ptr);
}

void *ntg_realloc(void *ptr, size_t size)
{
    if (ptr != NULL) {
        return realloc(ptr, size);
    } else {
        return ntg_malloc(size);
    }
}


#endif /* deprecated functions */

