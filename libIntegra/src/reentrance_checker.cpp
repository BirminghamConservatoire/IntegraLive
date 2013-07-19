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


#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "platform_specifics.h"

#include <assert.h>

#include "reentrance_checker.h"
#include "system_class_handlers.h"

using namespace ntg_internal;


struct ntg_reentrance_checker_state_ 
{
	const CNodeEndpoint *node_endpoint;

	ntg_reentrance_checker_state *next;

};



void ntg_reentrance_checker_initialize( ntg_server *server )
{
	server->system_class_data->reentrance_checker_state = NULL;
}


void ntg_reentrance_checker_free( ntg_server *server )
{
	/* stack should be empty during shutdown! */
	assert( !server->system_class_data->reentrance_checker_state );

	/* failsafe */
	while( server->system_class_data->reentrance_checker_state )
	{
		ntg_reentrance_pop( server, NTG_SOURCE_SYSTEM );
	}
}


bool ntg_does_reentrance_check_care_about_source( ntg_command_source cmd_source )
{
	switch( cmd_source )
	{
		case NTG_SOURCE_SYSTEM:
		case NTG_SOURCE_CONNECTION:
		case NTG_SOURCE_SCRIPT:
			return true;	/* these are potential sources of recursion */

		case NTG_SOURCE_INITIALIZATION:
		case NTG_SOURCE_LOAD:
		case NTG_SOURCE_HOST:
		case NTG_SOURCE_XMLRPC_API:
		case NTG_SOURCE_OSC_API:
		case NTG_SOURCE_C_API:
			return false;	/* these cannot cause recursion */

		default:
			assert( false );
			return false;
	}
}


bool ntg_reentrance_push( ntg_server *server, const CNodeEndpoint *endpoint, ntg_command_source cmd_source )
{
	ntg_reentrance_checker_state *state;

	if( !ntg_does_reentrance_check_care_about_source( cmd_source ) )
	{
		return false;
	}

	/* first iterate through stack to see if we already have this node attribute */

	for( state = server->system_class_data->reentrance_checker_state; state; state = state->next )
	{
		if( state->node_endpoint == endpoint )
		{
			/* detected reentrance! */
			return true;
		}
	}

	/* now push the stack (no reentrance detected) */

	state = new ntg_reentrance_checker_state;
	state->node_endpoint = endpoint;
	state->next = server->system_class_data->reentrance_checker_state;

	server->system_class_data->reentrance_checker_state = state;	

	return false;
}


void ntg_reentrance_pop( ntg_server *server, ntg_command_source cmd_source )
{
	ntg_reentrance_checker_state *next = NULL;

	if( !ntg_does_reentrance_check_care_about_source( cmd_source ) )
	{
		return;
	}

	assert( server->system_class_data->reentrance_checker_state );

	next = server->system_class_data->reentrance_checker_state->next;

	delete server->system_class_data->reentrance_checker_state;

	server->system_class_data->reentrance_checker_state = next;	
}
