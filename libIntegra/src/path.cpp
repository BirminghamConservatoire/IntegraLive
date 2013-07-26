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
#include "path.h"

#include "trace.h"
#include "globals.h"


namespace ntg_api
{


	CPath::CPath()
	{
		m_string_is_valid = false;
	}


	CPath::CPath( const CPath &to_copy )
	{
		copy_from( to_copy );
	}


	CPath::CPath( const string &path_string )
	{
		m_string_is_valid = false;

		int element_start = 0;
		while( true )
		{
			int element_end = path_string.find( '.', element_start );

			if( element_end == string::npos )
			{
				append_element( path_string.substr( element_start ) );
				break;
			}

			append_element( path_string.substr( element_start, element_end - element_start ) );
			element_start = element_end + 1;
		}
	}


	CPath::~CPath()
	{
	}


	const CPath &CPath::operator=( const CPath &to_copy )
	{
		copy_from( to_copy );
		return *this;
	}


	int CPath::get_number_of_elements()	const
	{
		return m_elements.size();
	}


	const string &CPath::operator[]( int index ) const
	{
		if( index < 0 || index >= m_elements.size() )
		{
			NTG_TRACE_ERROR_WITH_INT( "Incorrect index", index );
			static string dummy;
			return dummy;
		}

		return m_elements[ index ];
	}


	CPath::operator const string &() const
	{
		return get_string();
	}


	const string &CPath::get_string() const
	{
		if( !m_string_is_valid ) 
		{
			/* casts away const in order to hide the internal cached string */
			( ( CPath * ) this )->rebuild_string();
		}

		return m_string;
	}


	string CPath::pop_element()
	{
		int number_of_elements = m_elements.size();
		if( number_of_elements == 0 )
		{
			NTG_TRACE_ERROR( "trying to pop empty path" );
			return "";
		}

		string element = m_elements[ number_of_elements - 1 ];
		m_elements.pop_back();
	
		m_string_is_valid = false;

		return element;
	}


	void CPath::append_element( const string &element )
	{
		if( element.find_first_not_of( NTG_NODE_NAME_CHARACTER_SET ) != string::npos )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Invalid element name", element.c_str() );
			return;
		}

		m_elements.push_back( element );

		m_string_is_valid = false;
	}


	void CPath::copy_from( const CPath &to_copy )
	{
		m_elements = to_copy.m_elements;
		m_string_is_valid = false;
	}


	void CPath::rebuild_string()
	{
		int number_of_elements = m_elements.size();

		m_string.clear();

		bool first( true );

		for( int i = 0; i < number_of_elements; i++ )
		{
			if( first )
			{
				first = false;
			}
			else
			{
				m_string += ".";
			}

			m_string += m_elements[ i ];

		}
	}




}	/* namespace ntg_api */

