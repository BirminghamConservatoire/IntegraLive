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

#include "delete_command.h"
#include "server.h"
#include "trace.h"
#include "interface_definition.h"
#include "logic.h"


#include <assert.h>


namespace integra_api
{
	CDeleteCommandApi *CDeleteCommandApi::create( const CPath &path )
	{
		return new integra_internal::CDeleteCommand( path );
	}
}


namespace integra_internal
{
	CDeleteCommand::CDeleteCommand( const CPath &path )
	{
		m_path = path;
	}


	CError CDeleteCommand::execute( CServer &server, CCommandSource source, CCommandResult *result )
	{
		CNode *node = server.find_node_writable( m_path );
		if( !node ) 
		{
			return CError::PATH_ERROR;
		}

		/* delete children */
		node_map copy_of_children( node->get_children() );
		for( node_map::iterator i = copy_of_children.begin(); i != copy_of_children.end(); i++ )
		{
			CNode *child = i->second;
			server.process_command( CDeleteCommandApi::create( child->get_path() ), source );
		}

		/* system class logic */
		node->get_logic().handle_delete( server, source );

		/* state tables */
		server.get_state_table().remove( *node );

		/* remove in host */
		if( node->get_interface_definition().has_implementation() )
		{
			server.get_bridge()->module_remove( node->get_id() );
		}

		/* remove from owning container */
		server.get_sibling_set_writable( *node ).erase( node->get_name() );

		/* finally delete the node */
		delete node;

		return CError::SUCCESS;
	}


}

