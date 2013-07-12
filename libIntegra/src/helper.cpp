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

#ifdef __gnu_linux__
#define _GNU_SOURCE
#endif

#include "platform_specifics.h"

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <dirent.h>
#include <ctype.h>
#include <assert.h>
#include <math.h>

#include "helper.h"
#include "globals.h"
#include "Integra/integra.h"


char *ntg_strdup(const char *string)
{
    if (string != NULL) {
      size_t len = strlen(string);
      char *newstring = new char[ len + 1 ];
      strncpy(newstring, string, len + 1);
      return newstring;
    } else {
        NTG_TRACE_ERROR("string is NULL");
    }
    return NULL;
}


int ntg_count_digits(int num)
{
	const double log10 = 2.3025850929940456840179914546844;

	if( num < 0 ) return ntg_count_digits( -num ) + 1;
	if( num == 0 ) return 1;

	return int( log( (double) num ) / log10 ) + 1;
}


/* dest must have been allocated with new, or be NULL */
char *ntg_string_append( char *dest, const char *source )
{
    if (source != NULL) {

        size_t source_length = strlen(source);
        size_t dest_length   = dest!=NULL?strlen(dest):0;
        size_t final_length  = dest_length + source_length;

		dest = ntg_change_string_length( dest, final_length );

        if(dest_length) {
            strncat(dest, source, source_length);
        } else {
            strncpy(dest, source, source_length + 1);
        }
    }

    return dest;
}


char *ntg_ensure_filename_has_suffix( const char *filename, const char *suffix )
{
	int filename_length;
	int suffix_length;
	char *appended_filename;

	assert( filename && suffix );

	filename_length = strlen( filename );
	suffix_length = strlen( suffix );

	if( filename_length > suffix_length + 1 )
	{
		if( strcmp( filename + filename_length - suffix_length, suffix ) == 0 )
		{
			if( filename[ filename_length - suffix_length - 1 ] == '.' )
			{
				/* filename already has suffix */
				return strdup( filename );
			}
		}
	}

	appended_filename = new char[ filename_length + suffix_length + 2 ];
	sprintf( appended_filename, "%s.%s", filename, suffix );

	return appended_filename;
}


/* taken from libxml2 examples */
xmlChar *ConvertInput(const char *in, const char *encoding)
{
    unsigned char *out;
    int ret;
    int size;
    int out_size;
    int temp;
    xmlCharEncodingHandlerPtr handler;

    if (in == 0)
        return 0;

    handler = xmlFindCharEncodingHandler(encoding);

    if (!handler) {
        NTG_TRACE_ERROR_WITH_STRING("ConvertInput: no encoding handler found for",
               encoding ? encoding : "");
        return NULL;
    }

    size = (int)strlen(in) + 1;
    out_size = size * 2 - 1;
    out = new unsigned char[ out_size ];

    if (out != 0) {
        temp = size - 1;
        ret = handler->input(out, &out_size, (const xmlChar *)in, &temp);
        if ((ret < 0) || (temp - size + 1)) {
            if (ret < 0) {
                NTG_TRACE_ERROR("ConvertInput: conversion wasn't successful.");
            } else {
                NTG_TRACE_ERROR_WITH_INT
                    ("ConvertInput: conversion wasn't successful. converted octets",
                     temp);
            }

            free(out);
            out = NULL;
        } else {
			unsigned char *new_buffer = new unsigned char[ out_size + 1 ];
			memcpy( new_buffer, out, out_size );
			new_buffer[ out_size ] = 0;	/* null terminating out */
			delete out;
			out = new_buffer;
        }
    } else {
        NTG_TRACE_ERROR("ConvertInput: no mem");
    }

    return out;
}


char *ntg_make_node_name(const char *class_name)
{

    ntg_id fake_id;
    char *node_name;

    fake_id = ntg_id_new();

    node_name = new char[ strlen(class_name) + ntg_count_digits( fake_id ) + 1 ];

    sprintf(node_name, "%s%li", class_name, fake_id);

    return node_name;

}


bool ntg_validate_node_name( const char *name )
{
	int i, length;

	assert( name );

	length = strlen( name );

	if( length == 0 ) return false;
	
	for( i = 0; i < length; i++ )
	{
		if( !strchr( NTG_NODE_NAME_CHARACTER_SET, name[ i ] ) )
		{
			return false;
		}
	}

	return true;
}


void ntg_slash_to_dot(char *string)
{
    size_t length;

    length = strlen(string);

    while(length--) {
        if(string[length] == '/'){
            string[length] = '.';
        }
    }

}


/* helper to read a single hexadecimal character */
ntg_error_code ntg_read_hex_char( char input, unsigned char *output )
{
	if( input >= '0' && input <= '9' )
	{
		*output = input - '0';
		return NTG_NO_ERROR;
	}

	if( input >= 'A' && input <= 'F' )
	{
		*output = input + 0x0A - 'A';
		return NTG_NO_ERROR;
	}

	if( input >= 'a' && input <= 'f' )
	{
		*output = input + 0x0A - 'a';
		return NTG_NO_ERROR;
	}

	return NTG_ERROR;
}


/* helper to read up to a caller-specified number of hexadecimal characters, up to an unsigned long's worth */
unsigned long ntg_read_hex_chars( const char *input, unsigned int number_of_bytes, ntg_error_code *error_code )
{
	unsigned long result = 0;
	unsigned char nibble;
	int i;

	assert( input && number_of_bytes <= sizeof( unsigned long ) );

	for( i = 0; i < number_of_bytes * 2; i++ )
	{
		if( ntg_read_hex_char( input[ i ], &nibble ) != NTG_NO_ERROR )
		{
			*error_code = NTG_ERROR;
			return 0;
		}

		result = ( result << 4 ) + nibble;
	}

	return result;
}


bool ntg_guids_are_equal( const GUID *guid1, const GUID *guid2 )
{
	return ( memcmp( guid1, guid2, sizeof( GUID ) ) == 0 );
}


void ntg_guid_set_null( GUID *guid )
{
	memset( guid, 0, sizeof( GUID ) );
}


bool ntg_guid_is_null( const GUID *guid )
{
	GUID null_guid;
	ntg_guid_set_null( &null_guid );

	return ntg_guids_are_equal( guid, &null_guid );
}


char *ntg_guid_to_string( const GUID *guid )
{
	char *string;

	assert( guid );

	string = new char[ 37 ];

	sprintf( string, "%.8x-%.4x-%.4x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x", 
		guid->Data1, guid->Data2, guid->Data3,
		guid->Data4[ 0 ], guid->Data4[ 1 ], guid->Data4[ 2 ], guid->Data4[ 3 ], 
		guid->Data4[ 4 ], guid->Data4[ 5 ], guid->Data4[ 6 ], guid->Data4[ 7 ] );

	return string;
}


ntg_error_code ntg_string_to_guid( const char *string, GUID *output )
{
	ntg_error_code error_code = NTG_NO_ERROR;
	int i;

	assert( string && output );

	if( strlen( string ) < 36 ) 
	{
		return NTG_ERROR;
	}
	
	if( string[ 8 ] != '-' || string[ 13 ] != '-' || string[ 18 ] != '-' || string[ 23 ] != '-' )
	{
		return NTG_ERROR;
	}

	output->Data1 = ntg_read_hex_chars( string, sizeof( uint32_t ), &error_code );
	output->Data2 = ntg_read_hex_chars( string + 9, sizeof( uint16_t ), &error_code );
	output->Data3 = ntg_read_hex_chars( string + 14, sizeof( uint16_t ), &error_code );

	for( i = 0; i < 2; i++ )
	{
		output->Data4[ i ] = ntg_read_hex_chars( string + 19 + i * 2, sizeof( uint8_t ), &error_code );
	}

	for( i = 0; i < 6; i++ )
	{
		output->Data4[ i + 2 ] = ntg_read_hex_chars( string + 24 + i * 2, sizeof( uint8_t ), &error_code );
	}

	if( error_code != NTG_NO_ERROR )
	{
		ntg_guid_set_null( output );
	}

	return error_code;
}


char *ntg_date_to_string( const struct tm *date )
{
	char *output;
	assert( date );

	output = new char[ 20 ];
	sprintf( output, "%04i-%02i-%02iT%02i:%02i:%02i", date->tm_year + 1900, date->tm_mon + 1, date->tm_mday, date->tm_hour, date->tm_min, date->tm_sec );
	return output;
}


ntg_error_code ntg_string_to_date( const char *input, struct tm *output )
{
	if( strlen( input ) < 16 )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Unexpected date/time format", input );
		return NTG_ERROR;
	}

	output->tm_year = atoi( input ) - 1900;
	output->tm_mon = atoi( input + 5 ) - 1;
	output->tm_mday = atoi( input + 8 );
	output->tm_hour = atoi( input + 11 );
	output->tm_min = atoi( input + 14 );
	output->tm_sec = atoi( input + 17 );
	output->tm_isdst = -1;
	if( mktime( output ) == -1 )
	{
		return NTG_ERROR;
	}
	else
	{
		return NTG_NO_ERROR;
	}
}


int ntg_levenshtein_distance( const char *string1, const char *string2 )
{
	int length1, length2;
	int cost = 0;

	assert( string1 && string2 );

	length1 = strlen( string1 );
	length2 = strlen( string2 );

	if( length1 == 0 ) return length2;
	if( length2 == 0 ) return length1;

    if( string1[ 0 ] != string2[ 0 ] ) 
	{
		cost = 1;
	}

	return MIN( MIN(
		ntg_levenshtein_distance( string1 + 1, string2 ) + 1,
		ntg_levenshtein_distance( string1, string2 + 1 ) + 1 ), 
		ntg_levenshtein_distance( string1 + 1, string2 + 1 ) + cost );
}
