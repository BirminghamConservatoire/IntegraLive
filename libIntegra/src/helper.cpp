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

using namespace ntg_api;


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


/* helper to read a single hexadecimal character */
CError ntg_read_hex_char( char input, unsigned char *output )
{
	if( input >= '0' && input <= '9' )
	{
		*output = input - '0';
		return CError::SUCCESS;
	}

	if( input >= 'A' && input <= 'F' )
	{
		*output = input + 0x0A - 'A';
		return CError::SUCCESS;
	}

	if( input >= 'a' && input <= 'f' )
	{
		*output = input + 0x0A - 'a';
		return CError::SUCCESS;
	}

	return CError::INPUT_ERROR;
}


/* helper to read up to a caller-specified number of hexadecimal characters, up to an unsigned long's worth */
unsigned long ntg_read_hex_chars( const char *input, unsigned int number_of_bytes, CError *CError )
{
	unsigned long result = 0;
	unsigned char nibble;
	int i;

	assert( input && number_of_bytes <= sizeof( unsigned long ) );

	for( i = 0; i < number_of_bytes * 2; i++ )
	{
		if( ntg_read_hex_char( input[ i ], &nibble ) != CError::SUCCESS )
		{
			*CError = CError::INPUT_ERROR;
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


CError ntg_string_to_guid( const char *string, GUID *output )
{
	CError CError = CError::SUCCESS;
	int i;

	assert( string && output );

	if( strlen( string ) < 36 ) 
	{
		return CError::INPUT_ERROR;
	}
	
	if( string[ 8 ] != '-' || string[ 13 ] != '-' || string[ 18 ] != '-' || string[ 23 ] != '-' )
	{
		return CError::INPUT_ERROR;
	}

	output->Data1 = ntg_read_hex_chars( string, sizeof( uint32_t ), &CError );
	output->Data2 = ntg_read_hex_chars( string + 9, sizeof( uint16_t ), &CError );
	output->Data3 = ntg_read_hex_chars( string + 14, sizeof( uint16_t ), &CError );

	for( i = 0; i < 2; i++ )
	{
		output->Data4[ i ] = ntg_read_hex_chars( string + 19 + i * 2, sizeof( uint8_t ), &CError );
	}

	for( i = 0; i < 6; i++ )
	{
		output->Data4[ i + 2 ] = ntg_read_hex_chars( string + 24 + i * 2, sizeof( uint8_t ), &CError );
	}

	if( CError != CError::SUCCESS )
	{
		ntg_guid_set_null( output );
	}

	return CError;
}


char *ntg_date_to_string( const struct tm *date )
{
	char *output;
	assert( date );

	output = new char[ 20 ];
	sprintf( output, "%04i-%02i-%02iT%02i:%02i:%02i", date->tm_year + 1900, date->tm_mon + 1, date->tm_mday, date->tm_hour, date->tm_min, date->tm_sec );
	return output;
}


CError ntg_string_to_date( const char *input, struct tm &output )
{
	if( strlen( input ) < 16 )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Unexpected date/time format", input );
		return CError::INPUT_ERROR;
	}

	output.tm_year = atoi( input ) - 1900;
	output.tm_mon = atoi( input + 5 ) - 1;
	output.tm_mday = atoi( input + 8 );
	output.tm_hour = atoi( input + 11 );
	output.tm_min = atoi( input + 14 );
	output.tm_sec = atoi( input + 17 );
	output.tm_isdst = -1;
	if( mktime( &output ) == -1 )
	{
		return CError::INPUT_ERROR;
	}
	else
	{
		return CError::SUCCESS;
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


string ntg_version()
{
#ifdef _WINDOWS

	/*windows only - read version number from current module*/

	HMODULE module_handle = NULL;
	WCHAR file_name[_MAX_PATH];
	DWORD handle = 0;
	BYTE *version_info = NULL;
	UINT len = 0;
	VS_FIXEDFILEINFO *vsfi = NULL;
	DWORD size; 

	GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS| 
					GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
					(LPCTSTR)ntg_version, 
					&module_handle);

	size = GetModuleFileName(module_handle, file_name, _MAX_PATH);
	file_name[size] = 0;
	size = GetFileVersionInfoSize(file_name, &handle);
	version_info = new BYTE[ size ];
	if (!GetFileVersionInfo(file_name, handle, size, version_info))
	{
		NTG_TRACE_ERROR( "Failed to read version number from module" );
		delete[] version_info;

		return "<failed to read version number>";
	}

	// we have version information
	VerQueryValue(version_info, L"\\", (void**)&vsfi, &len);

	ostringstream stream;
	stream << HIWORD( vsfi->dwFileVersionMS ) << ".";
	stream << LOWORD( vsfi->dwFileVersionMS ) << ".";
	stream << HIWORD( vsfi->dwFileVersionLS ) << ".";
	stream << LOWORD( vsfi->dwFileVersionLS );

	return stream.str();

	delete[] version_info;

#else

	/*non-windows - use version number from preprocessor macro*/
	return string( TOSTRING( LIBINTEGRA_VERSION ) );

#endif
}