/** IntegraServer - console app to expose xmlrpc interface to libIntegra
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

#ifdef _WINDOWS
#pragma warning(disable : 4251)		//disable warnings about exported classes which use stl
#endif


#include "command_source.h"
#include "command.h"
#include "trace.h"
#include "server.h"
#include "value.h"

#include "osc_client.h"

#include <assert.h>


COscClient::COscClient( const string &url, unsigned short port )
{
	ostringstream port_stream;
	port_stream << port;

	m_address = lo_address_new( url.empty() ? NULL : url.c_str(), port_stream.str().c_str() );

	if( !m_address )
	{
		INTEGRA_TRACE_ERROR << "Failed to create OSC client!  url: " << url << ", port: " << port;
    }
}


COscClient::~COscClient()
{
	if( m_address )
	{
	    lo_address_free( m_address );
	}
}


void COscClient::on_set_command( const IServer &server, const CPath &endpoint_path, const CCommandSource &source )
{
    if( !m_address )
	{
		return;
	}

	const char *methodName = "/command.set";

    string source_string = source.get_text();

	const char *path_string = endpoint_path.get_string().c_str();

	const CValue *value = server.get_value( endpoint_path );
	if( value )
	{
		switch( value->get_type() ) 
		{
			case CValue::INTEGER:
				send_ssi( methodName, source_string.c_str(), path_string, *value );
				break;
			case CValue::FLOAT:
				send_ssf( methodName, source_string.c_str(), path_string, *value );
				break;

			case CValue::STRING:
				{
					const string &value_string = *value;
					send_sss( methodName, source_string.c_str(), path_string, value_string.c_str() );
				}
				break;

			default:
				assert( false );
				break;
		}
	}
	else
	{
		send_ssN( methodName, source_string.c_str(), path_string );
	}
}


bool COscClient::should_send_to_client( const CCommandSource &source ) const
{
	switch( source )
	{
		case CCommandSource::INITIALIZATION:
			/* don't send to client on initialization - client infers from known default values */
			return false;

		case CCommandSource::LOAD:
			/* don't send to client on load - calls nodelist and get explicitly */
			return false;

		default:
			return true;
	}
}


void COscClient::send_sss( const char *path, const char *s1, const char *s2, const char *s3 )
{
	assert( m_address );
    lo_send( m_address, path, "sss", s1, s2, s3 );
}


void COscClient::send_ssi( const char *path, const char *s1, const char *s2, int i )
{
	assert( m_address );
    lo_send( m_address, path, "ssi", s1, s2, i );
}


void COscClient::send_ssf( const char *path, const char *s1, const char *s2, float f )
{
	assert( m_address );
    lo_send( m_address, path, "ssf", s1, s2, f );
}


void COscClient::send_ssN( const char *path, const char *s1, const char *s2 )
{
	assert( m_address );
    lo_send( m_address, path, "ssN", s1, s2 );
}
