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

#include "src/platform_specifics.h"

#include "api/command_source.h"
#include "api/command.h"
#include "api/trace.h"
#include "api/server.h"
#include "api/value.h"

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


#if 0 //DEPRECATED`


/* sure there must be a more elegant way to do this, but lo_message_add_varargs
 * doesn't seem to work, and this does */
CError ntg_osc_send_ssss(lo_address targ, const char *path, 
        const char *s1, const char *s2, const char *s3, const char *s4)
{
    lo_send(targ, path, "ssss", s1, s2, s3, s4);

	return CError::SUCCESS;
}

CError ntg_osc_send_sss(lo_address targ, const char *path, 
        const char *s1, const char *s2, const char *s3)
{
    lo_send(targ, path, "sss", s1, s2, s3);

	return CError::SUCCESS;
}

CError ntg_osc_send_ssi(lo_address targ, const char *path, 
        const char *s1, const char *s2, int i)
{
    lo_send(targ, path, "ssi", s1, s2, i);

	return CError::SUCCESS;
}

CError ntg_osc_send_ssf(lo_address targ, const char *path, 
        const char *s1, const char *s2, float f)
{
    lo_send(targ, path, "ssf", s1, s2, f);

	return CError::SUCCESS;
}

CError ntg_osc_send_ssN(lo_address targ, const char *path, 
        const char *s1, const char *s2)
{
    lo_send(targ, path, "ssN", s1, s2);

	return CError::SUCCESS;
}

CError ntg_osc_send_ss(lo_address targ, const char *path, 
        const char *s1, const char *s2)
{
    lo_send(targ, path, "ss", s1, s2);

	return CError::SUCCESS;
}


ntg_osc_client *ntg_osc_client_new( const string &url, unsigned short port)
{
    char port_string[6];
	ntg_osc_client *client = NULL;

    port_string[5]=0;
    snprintf(port_string, 5, "%d", port);

    client = new ntg_osc_client;
    client->address = lo_address_new( url.empty() ? NULL : url.c_str(), port_string);

    if(client->address == NULL) {
        assert (false);
    }

    return client;
}

void ntg_osc_client_destroy(ntg_osc_client *client) 
{
	assert( client );
	assert( client->address );

    lo_address_free(client->address);
    delete client;
}


CError ntg_osc_client_send_set(ntg_osc_client *client, CCommandSource source, const CPath &path, const CValue *value )
{
	const char *methodName = "/command.set";

    assert(client != NULL);

    string source_string = source.get_text();

	const char *path_s = path.get_string().c_str();

	if( value )
	{
		switch( value->get_type() ) 
		{
			case CValue::INTEGER:
				ntg_osc_send_ssi(client->address, methodName, source_string.c_str(), path_s, *value );
				break;
			case CValue::FLOAT:
				ntg_osc_send_ssf(client->address, methodName, source_string.c_str(), path_s, *value );
				break;
			case CValue::STRING:
				{
					const string &value_string = *value;
					ntg_osc_send_sss(client->address, methodName, source_string.c_str(), path_s, value_string.c_str() );
				}
				break;

			default:
				assert( false );
				break;
		}
	}
	else
	{
		ntg_osc_send_ssN(client->address, methodName, source_string.c_str(), path_s);
	}

    return CError::SUCCESS;
}


CError ntg_osc_client_send_new(ntg_osc_client *client,
        CCommandSource source,
        const GUID *module_id,
        const char *node_name,
        const CPath &path)
{
    const char *methodName = "/command.new";

	assert(client != NULL);
    assert(module_id != NULL);
    assert(node_name != NULL);

    string source_string = source.get_text();

	string module_id_string = CGuidHelper::guid_to_string( *module_id );

    ntg_osc_send_ssss(client->address, methodName, source_string.c_str(), module_id_string.c_str(), node_name, path.get_string().c_str() );

    return CError::SUCCESS;
}

CError ntg_osc_client_send_load(ntg_osc_client *client,
        CCommandSource source,
        const char *file_path,
        const CPath &path)
{
    char *const methodName = "/command.load";
    string source_string = source.get_text();

    assert(client != NULL);
    assert(file_path != NULL);

    return ntg_osc_send_sss(client->address, methodName, source_string.c_str(), file_path, path.get_string().c_str() );
}

CError ntg_osc_client_send_delete(ntg_osc_client *client,
        CCommandSource source,
        const CPath &path)
{
    char *const methodName = "/command.delete";
    string source_string = source.get_text();

    assert(client != NULL);

    return ntg_osc_send_ss(client->address, methodName, source_string.c_str(), path.get_string().c_str() );
}
   
CError ntg_osc_client_send_move(ntg_osc_client *client,
        CCommandSource source,
        const CPath &node_path,
        const CPath &parent_path)
{
    char *const methodName = "/command.move";
    string source_string = source.get_text();

    assert(client != NULL);

	return ntg_osc_send_sss(client->address, methodName, source_string.c_str(), node_path.get_string().c_str(), parent_path.get_string().c_str() );

}

CError ntg_osc_client_send_rename(ntg_osc_client *client,
        CCommandSource source,
        const CPath &path,
        const char *name)
{
    char *const methodName = "/command.rename";
    string source_string = source.get_text();

    assert(client != NULL);
    assert(name != NULL);

    return ntg_osc_send_sss(client->address, methodName, source_string.c_str(), path.get_string().c_str(), name);

}


bool ntg_should_send_to_client( CCommandSource source ) 
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

#endif //DEPRECATED