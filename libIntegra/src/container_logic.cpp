 /* libIntegra multimedia module interface
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

#include "container_logic.h"
#include "node.h"
#include "node_endpoint.h"
#include "server.h"
#include "interface_definition.h"
#include "api/command_api.h"

#include <assert.h>


namespace ntg_internal
{
	CContainerLogic::CContainerLogic( const CNode &node )
		:	CLogic( node )
	{
	}


	CContainerLogic::~CContainerLogic()
	{
	}

	
	void CContainerLogic::handle_new( CServer &server, ntg_command_source source )
	{
		CLogic::handle_new( server, source );

		//todo - implement
	}


	void CContainerLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, ntg_command_source source )
	{
		CLogic::handle_set( server, node_endpoint, previous_value, source );

		const string &endpoint_name = node_endpoint.get_endpoint_definition().get_name();
		if( endpoint_name == s_endpoint_active )
		{
			active_handler( server, ( int ) *node_endpoint.get_value() != 0 );
		}


		//todo - implement
	}


	void CContainerLogic::handle_rename( CServer &server, const string &previous_name, ntg_command_source source )
	{
		CLogic::handle_rename( server, previous_name, source );

		//todo - implement
	}


	void CContainerLogic::handle_move( CServer &server, const CPath &previous_path, ntg_command_source source )
	{
		CLogic::handle_move( server, previous_path, source );

		//todo - implement
	}


	void CContainerLogic::handle_delete( CServer &server, ntg_command_source source )
	{
		CLogic::handle_delete( server, source );

		//todo - implement
	}


	void CContainerLogic::active_handler( CServer &server, bool active )
	{
		path_list activated_nodes;

		const node_map &children = get_node().get_children();
		for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
		{
			activate_tree( server, *i->second, active && are_all_ancestors_active(), activated_nodes );
		}

		/* 
		Now we explicitly update some system classes which were activated by this operation.
		This needs to be done here, instead of via a normal set handler, in order to ensure that subsequent
		business logic happens after everything else has become active
		*/

		for( path_list::const_iterator i = activated_nodes.begin(); i != activated_nodes.end(); i++ )
		{
			const CPath &path = *i;
			const CNode *activated_node = server.find_node( path );
			assert( activated_node );

			activated_node->get_logic().update_on_activation( server );
		}
	}


	void CContainerLogic::activate_tree( CServer &server, const CNode &node, bool activate, path_list &activated_nodes )
	{
		/*
		sets 'active' endpoint on any descendants that are not containers
		If any node in ancestor chain are not active, sets descendants to not active
		If all node in ancestor chain are active, sets descendants to active

		Additionally, the function pushes 'activated_nodes' - a list of pointers to 
		nodes which were activated by the function.
		The caller can use this list to perform additional logic
		*/

		int value_i = 0;

		const CNodeEndpoint *active_endpoint = node.get_node_endpoint( s_endpoint_active );

		if( dynamic_cast< CContainerLogic * > ( &node.get_logic() ) )
		{
			/* if node is a container, update 'activate' according to it's active flag */
			assert( active_endpoint );
			activate &= ( ( int ) *active_endpoint->get_value() != 0 );
		}
		else
		{
			/* if node is not a container, update it's active flag (if it has one) according to 'activate' */
			if( active_endpoint )
			{
				CIntegerValue value( activate ? 1 : 0 );

				if( !active_endpoint->get_value()->is_equal( value ) )
				{
					server.process_command( CSetCommandApi::create( active_endpoint->get_path(), &value ), NTG_SOURCE_SYSTEM );

					if( activate )
					{
						activated_nodes.push_back( node.get_path() );
					}
				}
			}
		}

		const node_map &children = node.get_children();
		for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
		{
			activate_tree( server, *i->second, activate, activated_nodes );
		}
	}



}
