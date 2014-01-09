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

#include "api/guid_helper.h"
#include "api/trace.h"
#include "MurmurHash2.h"

#include <assert.h>
#ifdef _WINDOWS
#include <time.h>
#else
#include <sys/time.h>
#endif


using namespace integra_internal;

namespace integra_api
{
	const GUID CGuidHelper::null_guid = { 0, 0, 0, { 0, 0, 0, 0, 0, 0, 0, 0 } };


	size_t CGuidHelper::guid_to_hash( const GUID &guid )
	{
		return MurmurHash2( &guid, sizeof( GUID ), 53 );
	}


	string CGuidHelper::guid_to_string( const GUID &guid )
	{
		char buffer[ 37 ];

		sprintf( buffer, "%.8x-%.4x-%.4x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x", 
			guid.Data1, guid.Data2, guid.Data3,
			guid.Data4[ 0 ], guid.Data4[ 1 ], guid.Data4[ 2 ], guid.Data4[ 3 ], 
			guid.Data4[ 4 ], guid.Data4[ 5 ], guid.Data4[ 6 ], guid.Data4[ 7 ] );

		return string( buffer );
	}


	CError CGuidHelper::string_to_guid( const string &string, GUID &output )
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
			output = null_guid;
		}

		return error;	
	}


	/* helper to read a single hexadecimal character */
	CError CGuidHelper::read_hex_char( char input, unsigned char &output )
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
	unsigned long CGuidHelper::read_hex_chars( const string &input, unsigned int number_of_bytes, CError &error )
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
    
    /* compares two guids. return true if they are equal, false if they are not equal */
    static bool guids_are_equal( const GUID &guid1, const GUID &guid2 )
    {
        if (
            ( guid1.Data1 == guid2.Data1 ) &&
            ( guid1.Data2 == guid2.Data2 ) &&
            ( guid1.Data3 == guid2.Data3 ) &&
            ( guid1.Data4 == guid2.Data4 )
            )
        {
            return true;
        }
        return false;
    }
    
    /* compares a guid to CGuidHelper::null_guid. return true if the guid is "null" */
    static bool guid_is_null( const GUID &guid )
    {
        return guids_are_equal(guid, CGuidHelper::null_guid);
    }

}


