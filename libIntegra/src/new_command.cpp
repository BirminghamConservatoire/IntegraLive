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

#include "new_command.h"
#include "server.h"
#include "node.h"
#include "module_manager.h"
#include "trace.h"
#include "logic.h"
#include "string_helper.h"
#include "api/command_result.h"

#include <assert.h>


namespace ntg_api
{
	CNewCommandApi *CNewCommandApi::create( const GUID &module_id, const string &node_name, const CPath &parent_path )
	{
		return new ntg_internal::CNewCommand( module_id, node_name, parent_path );
	}
}


namespace ntg_internal
{
	CNewCommand::CNewCommand( const GUID &module_id, const string &node_name, const CPath &parent_path )
	{
		m_module_id = module_id;
		m_node_name = node_name;
		m_parent_path = parent_path;
	}


	CError CNewCommand::execute( CServer &server, ntg_command_source source, CCommandResult *result )
	{
		/* get interface */
		const CInterfaceDefinition *interface_definition = server.get_module_manager().get_interface_by_module_id( m_module_id );
		if( !interface_definition ) 
		{
			NTG_TRACE_ERROR( "unable to find interface" );
			return CError::FAILED;
		}

		/* if node name is NULL, create one */
		if( m_node_name.empty() )
		{
			m_node_name = make_node_name( server, interface_definition->get_interface_info().get_name() );
		}

		/* First check if node name is already taken */
		CNode *parent = server.find_node_writable( m_parent_path );
		node_map &sibling_map = parent ? parent->get_children_writable() : server.get_nodes_writable();
		while( sibling_map.count( m_node_name ) > 0 ) 
		{
			NTG_TRACE_PROGRESS_WITH_STRING( "node name is in use; appending underscore", m_node_name.c_str() );

			m_node_name += "_";
		}

		if( !CStringHelper::validate_node_name( m_node_name ) )
		{
			NTG_TRACE_ERROR_WITH_STRING( "node name contains invalid characters", m_node_name.c_str() );
			return CError::FAILED;
		}

		CNode *node = new CNode;
		node->initialize( *interface_definition, m_node_name, server.create_internal_id(), parent );
		sibling_map[ m_node_name ] = node;
		server.get_state_table().add( *node );

		if( interface_definition->has_implementation() )
		{
			/* load implementation in module host */
			string patch_path = server.get_module_manager().get_patch_path( *interface_definition );
			if( patch_path.empty() )
			{
				NTG_TRACE_ERROR( "Failed to get implementation path - cannot load module in host" );
			}
			else
			{
				server.get_bridge()->module_load( node->get_id(), patch_path.c_str() );
			}
		}

		/* set attribute defaults */
		const endpoint_definition_list &endpoint_definitions = interface_definition->get_endpoint_definitions();
		for( endpoint_definition_list::const_iterator i = endpoint_definitions.begin(); i != endpoint_definitions.end(); i++ )
		{
			const CEndpointDefinition *endpoint_definition = *i;
			if( endpoint_definition->get_type() != CEndpointDefinition::CONTROL || endpoint_definition->get_control_info()->get_type() != CControlInfo::STATEFUL )
			{
				continue;
			}

			const CNodeEndpoint *node_endpoint = node->get_node_endpoint( endpoint_definition->get_name() );
			assert( node_endpoint );

			server.process_command( CSetCommandApi::create( node_endpoint->get_path(), &endpoint_definition->get_control_info()->get_state_info()->get_default_value() ), NTG_SOURCE_INITIALIZATION );
		}

		/* handle any system class logic */
		node->get_logic().handle_new( server, source );

		NTG_TRACE_VERBOSE_WITH_STRING( "Created node", node->get_name().c_str() );

		if( result )
		{
			CNewCommandResult *new_command_result = dynamic_cast<CNewCommandResult *> ( result );
			if( new_command_result )
			{
				new_command_result->set_created_node( node );
			}
			else
			{
				NTG_TRACE_ERROR( "incorrect command result type - can't store result" );
			}
		}

		if( ntg_should_send_to_client( source ) ) 
		{
			ntg_osc_client_send_new( server.get_osc_client(), source, &m_module_id, m_node_name.c_str(), node->get_parent_path() );
		}

		return CError::SUCCESS;
	}


	string CNewCommand::make_node_name( CServer &server, const string &module_name ) const
	{
		ostringstream stream;
		stream << module_name << server.create_internal_id();
	
		return stream.str();
	}
}