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

#include "osc_client.h"
#include "globals.h"
#include "server.h"
#include "string_helper.h"
#include "value.h"

#include <assert.h>

using namespace ntg_api;
using namespace ntg_internal;


static const char *ntg_command_source_text[NTG_COMMAND_SOURCE_end] =  {
    "initialization",
	"load",
	"system",
	"connection",
    "host",
    "script",
    "xmlrpc_api",
    "c_api" };



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

CError ntg_osc_client_send_set(ntg_osc_client *client,
        ntg_command_source cmd_source,
        const CPath &path,
        const CValue *value)
{
	const char *methodName = "/command.set";
	const char *cmd_source_s = NULL;

    assert(client != NULL);

    cmd_source_s = ntg_command_source_text[cmd_source];

	const char *path_s = path.get_string().c_str();

	if( value )
	{
		switch( value->get_type() ) 
		{
			case CValue::INTEGER:
				ntg_osc_send_ssi(client->address, methodName, cmd_source_s, path_s, *value );
				break;
			case CValue::FLOAT:
				ntg_osc_send_ssf(client->address, methodName, cmd_source_s, path_s, *value );
				break;
			case CValue::STRING:
				{
					const string &value_string = *value;
					ntg_osc_send_sss(client->address, methodName, cmd_source_s, path_s, value_string.c_str() );
				}
				break;

			default:
				assert( false );
				break;
		}
	}
	else
	{
		ntg_osc_send_ssN(client->address, methodName, cmd_source_s, path_s);
	}

    return CError::SUCCESS;
}


CError ntg_osc_client_send_new(ntg_osc_client *client,
        ntg_command_source cmd_source,
        const GUID *module_id,
        const char *node_name,
        const CPath &path)
{
    const char *methodName = "/command.new";
    const char *cmd_source_s = NULL;

	assert(client != NULL);
    assert(module_id != NULL);
    assert(node_name != NULL);

    cmd_source_s = ntg_command_source_text[cmd_source];

	string module_id_string = CStringHelper::guid_to_string( *module_id );

    ntg_osc_send_ssss(client->address, methodName, cmd_source_s,
			module_id_string.c_str(), node_name, path.get_string().c_str() );

    return CError::SUCCESS;
}

CError ntg_osc_client_send_load(ntg_osc_client *client,
        ntg_command_source cmd_source,
        const char *file_path,
        const CPath &path)
{
    char *const methodName = "/command.load";
    const char *cmd_source_s = ntg_command_source_text[cmd_source];

    assert(client != NULL);
    assert(file_path != NULL);

    return ntg_osc_send_sss(client->address, methodName, cmd_source_s,
            file_path, path.get_string().c_str() );
}

CError ntg_osc_client_send_delete(ntg_osc_client *client,
        ntg_command_source cmd_source,
        const CPath &path)
{
    char *const methodName = "/command.delete";
    const char *cmd_source_s = ntg_command_source_text[cmd_source];

    assert(client != NULL);

    return ntg_osc_send_ss(client->address, methodName, cmd_source_s, path.get_string().c_str() );
}
   
CError ntg_osc_client_send_move(ntg_osc_client *client,
        ntg_command_source cmd_source,
        const CPath &node_path,
        const CPath &parent_path)
{
    char *const methodName = "/command.move";
    const char *cmd_source_s = ntg_command_source_text[cmd_source];

    assert(client != NULL);

	return ntg_osc_send_sss(client->address, methodName, cmd_source_s, node_path.get_string().c_str(), parent_path.get_string().c_str() );

}

CError ntg_osc_client_send_rename(ntg_osc_client *client,
        ntg_command_source cmd_source,
        const CPath &path,
        const char *name)
{
    char *const methodName = "/command.rename";
    const char *cmd_source_s = ntg_command_source_text[cmd_source];

    assert(client != NULL);
    assert(name != NULL);

    return ntg_osc_send_sss(client->address, methodName, cmd_source_s, path.get_string().c_str(), name);

}


bool ntg_should_send_to_client( ntg_command_source cmd_source ) 
{
	switch( cmd_source )
	{
		case NTG_SOURCE_INITIALIZATION:
			/* don't send to client on initialization - client infers from known default values */
			return false;

		case NTG_SOURCE_LOAD:
			/* don't send to client on load - calls nodelist and get explicitly */
			return false;

		default:
			return true;
	}
}

