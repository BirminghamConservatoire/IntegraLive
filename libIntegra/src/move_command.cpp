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

#include "move_command.h"
#include "server.h"
#include "trace.h"
#include "logic.h"


#include <assert.h>


namespace ntg_api
{
	CMoveCommandApi *CMoveCommandApi::create( const CPath &node_path, const CPath &new_parent_path )
	{
		return new ntg_internal::CMoveCommand( node_path, new_parent_path	 );
	}
}


namespace ntg_internal
{
	CMoveCommand::CMoveCommand( const CPath &node_path, const CPath &new_parent_path )
	{
		m_node_path = node_path;
		m_new_parent_path = new_parent_path;
	}


	CError CMoveCommand::execute( CServer &server, CCommandSource source, CCommandResult *result )
	{
		CNode *node = server.find_node_writable( m_node_path );
		if( !node ) 
		{
			NTG_TRACE_ERROR << "unable to find node given by path" << m_node_path.get_string();
			return CError::PATH_ERROR;
		}

		/* remove old state table entries for node and children */
		server.get_state_table().remove( *node );

		node_map &old_sibling_set = server.get_sibling_set_writable( *node );
		old_sibling_set.erase( node->get_name() );

		CNode *new_parent = server.find_node_writable( m_new_parent_path );
		node_map &new_sibling_set = new_parent ? new_parent->get_children_writable() : server.get_nodes_writable();
		new_sibling_set[ node->get_name() ] = node;

		node->reparent( new_parent );

		/* add new state table entries for node and children */
		server.get_state_table().add( *node );

		node->get_logic().handle_move( server, m_node_path, source );

		if( ntg_should_send_to_client( source ) ) 
		{
			ntg_osc_client_send_move( server.get_osc_client(), source, m_node_path, m_new_parent_path );
		}

		return CError::SUCCESS;
	}


}

