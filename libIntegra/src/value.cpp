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


#include "platform_specifics.h"


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>
#include <limits.h>

#include <libxml/xmlmemory.h>

#include "api/value.h"
#include "api/trace.h"



namespace integra_api
{
	CValue::CValue()
	{
	}


	CValue::~CValue()
	{
	}


	CValue::operator int() const
	{
		handle_incorrect_cast( INTEGER );
		return 0;
	}


	CValue::operator float() const
	{
		handle_incorrect_cast( FLOAT );
		return 0;
	}
	
	
	CValue::operator const string &() const
	{
		handle_incorrect_cast( STRING );
		static string dummy;
		return dummy;
	}


	void CValue::handle_incorrect_cast( type cast_target ) const
	{
		INTEGRA_TRACE_ERROR << "Attempt to cast " << get_type_name( type() ) << " to " << get_type_name( cast_target );

		assert( false );
	}


	const char *CValue::get_type_name( type value_type )
	{
		switch( value_type )
		{
			case INTEGER:	return "integer";
			case FLOAT:		return "float";
			case STRING:	return "string";
			default:		return "error - unknown type";
		}
	}


	CValue *CValue::transmogrify( type new_type ) const
	{
		CValue *new_value = factory( new_type );
		convert( *new_value );

		return new_value;
	}


	CValue *CValue::factory( type new_type )
	{
		switch( new_type )
		{
			case INTEGER:	return new CIntegerValue();
			case FLOAT:		return new CFloatValue();
			case STRING:	return new CStringValue();

			default:		
				assert( false );
				return NULL;
		}
	}


	int CValue::type_to_ixd_code( type value_type )
	{
		switch( value_type )
		{
			case INTEGER:	return 1;
			case FLOAT:		return 2;
			case STRING:	return 3;

			default:		
				assert( false );
				return 0;
		}
	}


	CValue::type CValue::ixd_code_to_type( int ixd_code )
	{
		switch( ixd_code )
		{
			case 1:		return INTEGER;
			case 2:		return FLOAT;
			case 3:		return STRING;

			default:		
				assert( false );
				return INTEGER;
		}
	}


	/* INTEGER VALUES */ 

	CIntegerValue::CIntegerValue()
	{
		m_value = 0;
	}


	CIntegerValue::CIntegerValue( int value )
	{
		m_value = value;
	}


	CIntegerValue::~CIntegerValue()
	{
	}

	
	CValue::type CIntegerValue::get_type() const
	{
		return INTEGER;
	}

	CIntegerValue::operator int() const
	{
		return m_value;
	}


	const CIntegerValue &CIntegerValue::operator= ( const CIntegerValue &to_copy )
	{
		m_value = to_copy.m_value;
		return *this;
	}


	CValue *CIntegerValue::clone() const
	{
		return new CIntegerValue( m_value );
	}


	void CIntegerValue::convert( CValue &conversion_target ) const
	{
		switch( conversion_target.get_type() )
		{
			case INTEGER:		
				dynamic_cast<CIntegerValue &>( conversion_target ) = m_value;
				break;

			case FLOAT:			
				dynamic_cast<CFloatValue &>( conversion_target ) = m_value;
				break;

			case STRING:		
				dynamic_cast<CStringValue &>( conversion_target ) = get_as_string();
				break;

			default:
				INTEGRA_TRACE_ERROR << "unhandled value type";
				break;
		}
	}


	bool CIntegerValue::is_equal( const CValue &other ) const
	{
		const CIntegerValue *other_int = dynamic_cast<const CIntegerValue *>( &other );
		if( !other_int ) return false;

		return ( m_value == other_int->m_value );
	}


	float CIntegerValue::get_distance( const CValue &other ) const
	{
		const CIntegerValue *other_int = dynamic_cast<const CIntegerValue *>( &other );
		if( !other_int ) 
		{
			INTEGRA_TRACE_ERROR << "type mismatch";
			return -1;
		}

		return abs( m_value - other_int->m_value );
	}


	string CIntegerValue::get_as_string() const
	{
		ostringstream stream;
		stream << m_value;
		return stream.str();
	}


	void CIntegerValue::set_from_string( const string &source )
	{
        m_value = strtol( source.c_str(), NULL, 0 );
		if( errno == ERANGE )
		{
			INTEGRA_TRACE_ERROR << "value too large to convert to int - truncating" << source;
			m_value = source[ 0 ] == '-' ? INT_MIN : INT_MAX;
		}
	}


	/* FLOAT VALUES */ 

	CFloatValue::CFloatValue()
	{
		m_value = 0;
	}


	CFloatValue::CFloatValue( float value )
	{
		m_value = value;
	}


	CFloatValue::~CFloatValue()
	{
	}

	
	CValue::type CFloatValue::get_type() const
	{
		return FLOAT;
	}

	CFloatValue::operator float() const
	{
		return m_value;
	}


	const CFloatValue &CFloatValue::operator= ( const CFloatValue &to_copy )
	{
		m_value = to_copy.m_value;
		return *this;
	}


	CValue *CFloatValue::clone() const
	{
		return new CFloatValue( m_value );
	}


	void CFloatValue::convert( CValue &conversion_target ) const
	{
		switch( conversion_target.get_type() )
		{
			case INTEGER:		
				dynamic_cast<CIntegerValue &>( conversion_target ) = ( int ) m_value;
				break;

			case FLOAT:			
				dynamic_cast<CFloatValue &>( conversion_target ) = m_value;
				break;

			case STRING:		
				dynamic_cast<CStringValue &>( conversion_target ) = get_as_string();
				break;

			default:
				INTEGRA_TRACE_ERROR << "unhandled value type";
				break;
		}
	}


	bool CFloatValue::is_equal( const CValue &other ) const
	{
		const CFloatValue *other_float = dynamic_cast<const CFloatValue *>( &other );
		if( !other_float ) return false;

		return ( m_value == other_float->m_value );
	}


	float CFloatValue::get_distance( const CValue &other ) const
	{
		const CFloatValue *other_float = dynamic_cast<const CFloatValue *>( &other );
		if( !other_float ) 
		{
			INTEGRA_TRACE_ERROR << "type mismatch";
			return -1;
		}

		return abs( m_value - other_float->m_value );
	}


	string CFloatValue::get_as_string() const
	{
		ostringstream stream;
		stream.precision( 6 );
		stream << std::fixed << m_value;
		string value = stream.str();

		//remove trailing zeros
		if( value.find( "." ) != string::npos )
		{
			int new_length = value.find_last_not_of( '0' );
			value = value.substr( 0, new_length + 1 );
		}

		return value;
	}


	void CFloatValue::set_from_string( const string &source )
	{
        m_value = strtod( source.c_str(), NULL );
	}


	/* STRING VALUES */ 

	CStringValue::CStringValue()
	{
		m_value = "";
	}


	CStringValue::CStringValue( const string &value )
	{
		m_value = value;
	}


	CStringValue::~CStringValue()
	{
	}

	
	CValue::type CStringValue::get_type() const
	{
		return STRING;
	}


	CStringValue::operator const string &() const
	{
		return m_value;
	}


	CValue *CStringValue::clone() const
	{
		return new CStringValue( m_value );
	}


	const CStringValue &CStringValue::operator= ( const CStringValue &to_copy )
	{
		m_value = to_copy.m_value;
		return *this;
	}


	void CStringValue::convert( CValue &conversion_target ) const
	{
		switch( conversion_target.get_type() )
		{
			case INTEGER:		
				dynamic_cast<CIntegerValue &>( conversion_target ).set_from_string( m_value );
				break;

			case FLOAT:			
				dynamic_cast<CFloatValue &>( conversion_target ).set_from_string( m_value );
				break;

			case STRING:		
				dynamic_cast<CStringValue &>( conversion_target ).m_value = m_value;
				break;

			default:
				INTEGRA_TRACE_ERROR << "unhandled value type";
				break;
		}
	}


	bool CStringValue::is_equal( const CValue &other ) const
	{
		const CStringValue *other_string = dynamic_cast<const CStringValue *>( &other );
		if( !other_string ) return false;

		return ( m_value == other_string->m_value );
	}


	float CStringValue::get_distance( const CValue &other ) const
	{
		const CStringValue *other_string = dynamic_cast<const CStringValue *>( &other );
		if( !other_string ) 
		{
			INTEGRA_TRACE_ERROR << "type mismatch";
			return -1;
		}

		return levenshtein_distance( m_value.c_str(), other_string->m_value.c_str() );
	}


	string CStringValue::get_as_string() const
	{
		return m_value;
	}


	void CStringValue::set_from_string( const string &source )
	{
        m_value = source;
	}


	int CStringValue::levenshtein_distance( const char *string1, const char *string2 )
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
			levenshtein_distance( string1 + 1, string2 ) + 1,
			levenshtein_distance( string1, string2 + 1 ) + 1 ), 
			levenshtein_distance( string1 + 1, string2 + 1 ) + cost );
	}

}



