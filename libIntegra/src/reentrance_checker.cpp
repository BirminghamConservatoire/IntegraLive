/** libIntegra multimedia module interface
 *
 * Copyright (C) 2012 Birmingham City University
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

#include <assert.h>

#include "reentrance_checker.h"
#include "api/trace.h"


namespace integra_internal
{
	CReentranceChecker::CReentranceChecker()
	{
	}


	CReentranceChecker::~CReentranceChecker()
	{
	}


	bool CReentranceChecker::push( const CNodeEndpoint *node_endpoint, CCommandSource source )
	{
		if( cares_about_source( source ) )
		{
			map_node_endpoint_to_source::const_iterator lookup = m_map_endpoint_to_source.find( node_endpoint );
			if( lookup != m_map_endpoint_to_source.end() )
			{
				if( cares_about_source( lookup->second ) )
				{
					return true;
				}
			}
		}

		m_map_endpoint_to_source[ node_endpoint ] = source;
		m_stack.push_back( node_endpoint );

		return false;
	}


	void CReentranceChecker::pop()
	{
		if( m_stack.empty() )
		{
			INTEGRA_TRACE_ERROR << "attempt to pop empty queue";
			return;
		}

		m_map_endpoint_to_source.erase( m_stack.back() );
		m_stack.pop_back();
	}


	bool CReentranceChecker::cares_about_source( CCommandSource source )
	{
		switch( source )
		{
			case CCommandSource::SYSTEM:
			case CCommandSource::CONNECTION:
			case CCommandSource::SCRIPT:
				return true;	/* these are potential sources of recursion */

			case CCommandSource::INITIALIZATION:
			case CCommandSource::LOAD:
			case CCommandSource::PUBLIC_API:
			case CCommandSource::MODULE_IMPLEMENTATION:
				return false;	/* these cannot cause recursion */

			default:
				assert( false );
				return false;
		}
	}
}

