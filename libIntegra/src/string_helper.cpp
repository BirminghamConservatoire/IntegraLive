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

#include "string_helper.h"
#include "trace.h"

#include <assert.h>
#ifdef _WINDOWS
#include <time.h>
#else
#include <sys/time.h>
#endif


using namespace ntg_internal;

namespace ntg_api
{
	const string CStringHelper::s_node_name_character_set = "0123456789_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";


	string CStringHelper::guid_to_string( const GUID &guid )
	{
		char string[ 37 ];

		sprintf( string, "%.8x-%.4x-%.4x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x", 
			guid.Data1, guid.Data2, guid.Data3,
			guid.Data4[ 0 ], guid.Data4[ 1 ], guid.Data4[ 2 ], guid.Data4[ 3 ], 
			guid.Data4[ 4 ], guid.Data4[ 5 ], guid.Data4[ 6 ], guid.Data4[ 7 ] );

		return string;
	}


	CError CStringHelper::string_to_guid( const string &string, GUID &output )
	{
		int i;

		if( string.length() < 36 ) 
		{
			return CError::INPUT_ERROR;
		}
	
		if( string[ 8 ] != '-' || string[ 13 ] != '-' || string[ 18 ] != '-' || string[ 23 ] != '-' )
		{
			return CError::INPUT_ERROR;
		}

		CError error = CError::SUCCESS;
		output.Data1 = read_hex_chars( string, 4, error );
		output.Data2 = read_hex_chars( string.substr( 9, 4 ), 2, error );
		output.Data3 = read_hex_chars( string.substr( 14, 4 ), 2, error );

		for( i = 0; i < 2; i++ )
		{
			output.Data4[ i ] = read_hex_chars( string.substr( 19 + i * 2, 2 ), 1, error );
		}

		for( i = 0; i < 6; i++ )
		{
			output.Data4[ i + 2 ] = read_hex_chars( string.substr( 24 + i * 2, 2 ), 1, error );
		}

		if( error != CError::SUCCESS )
		{
			output = NULL_GUID;
		}

		return error;	
	}


	string CStringHelper::date_to_string( const struct tm &date )
	{
		char string[ 20 ];
		sprintf( string, "%04i-%02i-%02iT%02i:%02i:%02i", date.tm_year + 1900, date.tm_mon + 1, date.tm_mday, date.tm_hour, date.tm_min, date.tm_sec );
		return string;
	}


	CError CStringHelper::string_to_date( const string &string, struct tm &output )
	{
		if( string.length() < 16 )
		{
			NTG_TRACE_ERROR << "Unexpected date/time format: " << string.c_str();
			return CError::INPUT_ERROR;
		}

		output.tm_year = atoi( string.c_str() ) - 1900;
		output.tm_mon = atoi( string.substr( 5 ).c_str() ) - 1;
		output.tm_mday = atoi( string.substr( 8 ).c_str() );
		output.tm_hour = atoi( string.substr( 11 ).c_str() );
		output.tm_min = atoi( string.substr( 14 ).c_str() );
		output.tm_sec = atoi( string.substr( 17 ).c_str() );
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


	bool CStringHelper::validate_node_name( const string &name )
	{
		int length = name.length();

		if( length == 0 ) return false;
	
		for( int i = 0; i < length; i++ )
		{
			if( s_node_name_character_set.find_first_of( name[ i ] ) == string::npos )
			{
				return false;
			}
		}

		return true;	
	}


	/* helper to read a single hexadecimal character */
	CError CStringHelper::read_hex_char( char input, unsigned char &output )
	{
		if( input >= '0' && input <= '9' )
		{
			output = input - '0';
			return CError::SUCCESS;
		}

		if( input >= 'A' && input <= 'F' )
		{
			output = input + 0x0A - 'A';
			return CError::SUCCESS;
		}

		if( input >= 'a' && input <= 'f' )
		{
			output = input + 0x0A - 'a';
			return CError::SUCCESS;
		}

		return CError::INPUT_ERROR;
	}


	/* helper to read up to a caller-specified number of hexadecimal characters, up to an unsigned long's worth */
	unsigned long CStringHelper::read_hex_chars( const string &input, unsigned int number_of_bytes, CError &error )
	{
		unsigned long result = 0;

		assert( number_of_bytes <= sizeof( unsigned long ) );

		for( int i = 0; i < number_of_bytes * 2; i++ )
		{
			unsigned char nibble = 0;
			if( read_hex_char( input[ i ], nibble ) != CError::SUCCESS )
			{
				error = CError::INPUT_ERROR;
				return 0;
			}

			result = ( result << 4 ) + nibble;
		}

		return result;
	}
}


