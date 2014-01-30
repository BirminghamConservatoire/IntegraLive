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

#include "move_command.h"
#include "server.h"
#include "api/trace.h"
#include "logic.h"
#include "api/interface_definition.h"


#include <assert.h>


namespace integra_api
{
	IMoveCommand *IMoveCommand::create( const CPath &node_path, const CPath &new_parent_path )
	{
		return new integra_internal::CMoveCommand( node_path, new_parent_path	 );
	}
}


namespace integra_internal
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
			INTEGRA_TRACE_ERROR << "unable to find node given by path" << m_node_path.get_string();
			return CError::PATH_ERROR;
		}

		CNode *new_parent = server.find_node_writable( m_new_parent_path );

		if( !node->get_logic().can_be_child_of( new_parent ) )
		{
			INTEGRA_TRACE_ERROR << node->get_interface_definition().get_interface_info().get_name() << " cannot be moved into " << new_parent ? new_parent->get_interface_definition().get_interface_info().get_name() : "top level";
			delete node;
			return CError::TYPE_ERROR;
		}

		/* remove old state table entries for node and children */
		server.get_state_table().remove( *node );

		node_map &old_sibling_set = server.get_sibling_set_writable( *node );
		old_sibling_set.erase( node->get_name() );

		node_map &new_sibling_set = new_parent ? new_parent->get_children_writable() : server.get_nodes_writable();
		new_sibling_set[ node->get_name() ] = node;

		node->reparent( new_parent );

		/* add new state table entries for node and children */
		server.get_state_table().add( *node );

		node->get_logic().handle_move( server, m_node_path, source );

		return CError::SUCCESS;
	}
}

