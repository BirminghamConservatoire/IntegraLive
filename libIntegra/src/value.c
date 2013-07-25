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
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>
#include <limits.h>

#include <libxml/xmlmemory.h>

#include "memory.h"
#include "helper.h"
#include "value.h"
#include "globals.h"


static const char *ntg_type_as_string[NTG_n_types] = {
    "undefined",
    "integer",
    "float",
    "string"
};

ntg_error_code ntg_value_sprintf( char *output, int chars_available, const ntg_value * value )
{
    unsigned int n;
    int rv = 0;
    size_t len_float;
    ntg_error_code error_code = NTG_NO_ERROR;

    if(value == NULL)
	{
        NTG_TRACE_ERROR("value was NULL");
        return NTG_ERROR;
    }

    if( chars_available < 0 )
	{
        NTG_TRACE_ERROR( "chars_available less than 1" );
        return NTG_ERROR;
    }

    switch (value->type) 
	{
        case NTG_FLOAT:
            rv = sprintf_s( output, chars_available, "%.6f", value->ctype.f);
            len_float = strlen( output );
            for( n = len_float - 1; n >= 0; n-- ) 
			{
                if( output[ n ] != '0') 
				{
                    break;
                }
            }
            output[ n + 1 ] = '\0';
            break;
        case NTG_STRING:
			if( strlen( value->ctype.s ) >= chars_available )
			{
				return NTG_ERROR;
			}
			else
			{
				rv = sprintf_s( output, chars_available, "%s", value->ctype.s);
			}
            break;
        case NTG_INTEGER:
            rv = sprintf_s( output, chars_available, "%d", value->ctype.i);
            break;
        default:
            NTG_TRACE_ERROR_WITH_INT( "invalid value type", value->type );
            break;
    }

    if(rv == -1)
	{
        error_code = NTG_ERROR;
    }

    return error_code;

}


ntg_value *ntg_value_duplicate(const ntg_value * value)
{
    ntg_value *dup;

    if (value == NULL) {
        NTG_TRACE_ERROR("attempt to duplicate a NULL value");
        return NULL;
    }

    dup = ntg_value_new(value->type, NULL);

    ntg_value_copy(dup, value);

    return dup;
}


ntg_value *ntg_value_change_type(const ntg_value *value, ntg_value_type newType)
{
    ntg_value *value_with_changed_type;

	assert( value );

    value_with_changed_type = ntg_value_new( newType, NULL);

    ntg_value_copy( value_with_changed_type, value );

    return value_with_changed_type;
}


void ntg_value_copy(ntg_value * target, const ntg_value * source)
{
    assert(target);
    assert(source);
    assert(source->type < NTG_n_types);
    assert(target->type < NTG_n_types);

    switch(source->type) 
	{
		case NTG_STRING:
			switch(target->type) 
			{
				case NTG_STRING:
					ntg_value_set(target, source->ctype.s);
					return;

				case NTG_INTEGER:
					target->ctype.i = atoi( source->ctype.s );
					return;

				case NTG_FLOAT:
					target->ctype.f = atof( source->ctype.s );
					return;

				default:
					assert( false );
					return;
			}

		case NTG_INTEGER:
			switch(target->type) 
			{
				case NTG_STRING:
					if (target->ctype.s) ntg_free(target->ctype.s);
			        target->ctype.s = ntg_malloc( NTG_LONG_STRLEN );
					ntg_value_sprintf( target->ctype.s, NTG_LONG_STRLEN, source );
					return;

				case NTG_INTEGER:
					ntg_value_set(target, &source->ctype.i);
					return;

				case NTG_FLOAT:
					target->ctype.f = (float)source->ctype.i;
					return;

				default:
					assert( false );
					return;
			}

		case NTG_FLOAT:
			switch(target->type) 
			{
				case NTG_STRING:
					if (target->ctype.s) ntg_free(target->ctype.s);
			        target->ctype.s = ntg_malloc( NTG_LONG_STRLEN );
					ntg_value_sprintf( target->ctype.s, NTG_LONG_STRLEN, source );
					return;

				case NTG_INTEGER:
					target->ctype.i = (int)source->ctype.f;
					return;

				case NTG_FLOAT:
	                ntg_value_set(target, &source->ctype.f);
					return;

				default:
					assert( false );
					return;
			}

		default:
			assert( false );
	}
}

void ntg_value_set(ntg_value *value, const void *v, ...)
{

    va_list argv;
    size_t length = 0;

    va_start(argv, v);
    length = va_arg(argv, size_t);
    va_end(argv);

    assert(value != NULL);
    assert(value->type < NTG_n_types);

    switch (value->type) {
        case NTG_STRING:
            if (value->ctype.s != NULL) {
                ntg_free(value->ctype.s);
            }
            if (v != NULL) {
                value->ctype.s = ntg_strdup(v);
            } else {
                /* we can't use a string literal because ntg_free() will
                 * fail to find it in the allocation table */
              value->ctype.s = ntg_malloc(sizeof(char));
              *value->ctype.s = '\0';
            }
            break;
        case NTG_FLOAT:
            if (v != NULL) {
                value->ctype.f = *(float *)v;
            } else {
                value->ctype.f = 0.f;
            }
            break;
        case NTG_INTEGER:
            if (v != NULL) {
                value->ctype.i = *(int *)v;
            } else {
                value->ctype.i = 0;
            }
            break;
        default:
            assert( false );;
            break;
    }
}

ntg_value *ntg_value_new(ntg_value_type type, const void *v, ...)
{

    ntg_value *value = NULL;
    va_list argv;
    size_t length = 0;

    va_start(argv, v);
    length = va_arg(argv, size_t);
    va_end(argv);

    value = ntg_calloc(1, sizeof(ntg_value));

    value->ctype.s = NULL;
    value->type    = type;

    ntg_value_set(value, v, length);

    return value;

}

ntg_error_code ntg_value_free(ntg_value * value)
{
    if (value == NULL) {
        return NTG_ERROR;
    }

    switch(value->type){
        case NTG_STRING:
            if (value->ctype.s != NULL) {
                ntg_free(value->ctype.s);
            }
            break;
        case NTG_INTEGER:
        case NTG_FLOAT:
            break;
        default:
            assert(0);
    }

    return NTG_NO_ERROR;

}

float ntg_value_get_float(const ntg_value * value)
{
    if (value->type != NTG_FLOAT) {
        NTG_TRACE_ERROR_WITH_STRING("invalid type", 
                ntg_type_as_string[value->type]);
        return 0.f;
    } else {
        return value->ctype.f;
    }
}

int ntg_value_get_int(const ntg_value * value)
{
    if (value->type != NTG_INTEGER) {
        NTG_TRACE_ERROR_WITH_STRING("invalid type",
                ntg_type_as_string[value->type]);
        return 0;
    } else {
        return value->ctype.i;
    }
}


char *ntg_value_get_string(const ntg_value * value)
{
    assert(value != NULL);
    assert(value->type < NTG_n_types);

    if (value->type != NTG_STRING) {
        NTG_TRACE_ERROR_WITH_STRING("invalid type",
                ntg_type_as_string[value->type]);
        return NULL;
    } else {
        return value->ctype.s;
    }
}

ntg_error_code ntg_value_compare(const ntg_value * value,
                                 const ntg_value * comparable)
{

    ntg_error_code error_code = NTG_ERROR;

    if (value->type != comparable->type) {
        return NTG_ERROR;
    }

    switch (value->type) {
        case NTG_STRING:
            if (!strcmp(value->ctype.s, comparable->ctype.s)) {
                error_code = NTG_NO_ERROR;
            }
            break;
        case NTG_FLOAT:
            if (value->ctype.f == comparable->ctype.f) {
                error_code = NTG_NO_ERROR;
            }
            break;
        case NTG_INTEGER:
            if (value->ctype.i == comparable->ctype.i) {
                error_code = NTG_NO_ERROR;
            }
            break;
        default:
            error_code = NTG_FAILED;
	        NTG_TRACE_ERROR_WITH_STRING("unsupported value type:",
		            ntg_type_as_string[value->type]);
            break;
    }

    return error_code;

}


float ntg_value_get_difference( const ntg_value *value1, const ntg_value *value2 )
{
	assert( value1 && value2 );

	if( value1->type != value2->type )
	{
		NTG_TRACE_ERROR( "value type mismatch" );
		return 0;
	}

	switch( value1->type )
	{
		case NTG_FLOAT:		
			return value1->ctype.f - value2->ctype.f;

		case NTG_INTEGER:	
			return value1->ctype.i - value2->ctype.i;

		case NTG_STRING:
			return ntg_levenshtein_distance( value1->ctype.s, value2->ctype.s );

		default:
			NTG_TRACE_ERROR( "unhandled value type" );
			return 0;
	}
}



ntg_value_type ntg_value_get_type(const ntg_value * value)
{
    return value->type;
}

ntg_value *ntg_value_from_string(ntg_value_type type, const char *string)
{
    float value_f = 0.f;
    int value_i = 0;

    assert (string != NULL);

    switch(type) 
	{
        case NTG_INTEGER:
            value_i = strtol( string, NULL, 0 );
			if( errno == ERANGE )
			{
				NTG_TRACE_ERROR_WITH_STRING( "value too large to convert to int - truncating", string );
				value_i = string[ 0 ] == '-' ? INT_MIN : INT_MAX;
			}
            return ntg_value_new(NTG_INTEGER, &value_i );

        case NTG_FLOAT:
            value_f = strtod( string, NULL );
            return ntg_value_new(NTG_FLOAT, &value_f );

        case NTG_STRING:
            return ntg_value_new(NTG_STRING, string );

        default:
            return NULL;
    }

    return NULL;
}

