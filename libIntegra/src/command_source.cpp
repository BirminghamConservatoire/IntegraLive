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

#include "command_source.h"
#include "trace.h"


namespace integra_api
{
	CCommandSource::CCommandSource()
	{
		m_command_source = NONE;
	}


	CCommandSource::CCommandSource( source command_source )
	{
		m_command_source = command_source;
	}


	CCommandSource::operator source() const
	{
		return m_command_source;
	}


	string CCommandSource::get_text() const
	{
		switch( m_command_source ) 
		{
			case NONE:				return "none";
			case INITIALIZATION:	return "initialization";
			case LOAD:				return "load";
			case SYSTEM:			return "system";
			case CONNECTION:		return "connection";
			case HOST:				return "host";
			case SCRIPT:			return "script";
			case XMLRPC_API:		return "xmlrpc_api";
			case PUBLIC_API:		return "public_api";

			default:
				NTG_TRACE_ERROR << "encountered unknown command source";
				return "<unknown command source>";
		}
	}
}