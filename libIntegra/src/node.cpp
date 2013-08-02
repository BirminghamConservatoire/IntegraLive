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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <assert.h>

#include "helper.h"
#include "value.h"
#include "path.h"
#include "globals.h"
#include "node.h"
#include "server.h"
#include "module_manager.h"
#include "interface_definition.h"


using namespace ntg_api;
using namespace ntg_internal;



namespace ntg_internal
{
	CNode::CNode()
	{
		m_interface_definition = NULL;
		m_id = 0;
		m_parent = NULL;
	}
	
	
	CNode::~CNode()
	{
		/* delete children */
		for( node_map::iterator i = m_children.begin(); i != m_children.end(); i++ )
		{
			delete i->second;
		}

		/* delete node endpoints */
		for( node_endpoint_map::iterator i = m_node_endpoints.begin(); i != m_node_endpoints.end(); i++ )
		{
			delete i->second;
		}
	}


	void CNode::initialize( const CInterfaceDefinition &interface_definition, const ntg_api::string &name, CNode *parent )
	{
		m_id = ntg_id_new();
		m_interface_definition = &interface_definition;
		m_name = name;
		m_parent = parent;

		update_path();

		const endpoint_definition_list &endpoint_definitions = interface_definition.get_endpoint_definitions();
		for( endpoint_definition_list::const_iterator i = endpoint_definitions.begin(); i != endpoint_definitions.end(); i++ )
		{
			const CEndpointDefinition &endpoint_definition = **i;

			CNodeEndpoint *node_endpoint = new CNodeEndpoint;
			node_endpoint->initialize( *this, endpoint_definition );

			m_node_endpoints[ endpoint_definition.get_name() ] = node_endpoint;
		}
	}


	void CNode::rename( const ntg_api::string &new_name )
	{
		m_name = new_name;

		update_all_paths();
	}


	void CNode::reparent( CNode *new_parent )
	{
		m_parent = new_parent;

		update_all_paths();
	}


	const CPath &CNode::get_parent_path() const
	{
		if( m_parent )
		{
			return m_parent->get_path();
		}

		static CPath empty_path;
		return empty_path;
	}


	const CNode *CNode::get_child( const ntg_api::string &child_name ) const
	{
		node_map::const_iterator lookup = m_children.find( child_name );
		if( lookup == m_children.end() )
		{
			/* not found */
			return NULL;
		}

		return lookup->second;
	}


	const CNodeEndpoint *CNode::get_node_endpoint( const ntg_api::string &endpoint_name ) const
	{
		node_endpoint_map::const_iterator lookup = m_node_endpoints.find( endpoint_name );
		if( lookup == m_node_endpoints.end() )
		{
			/* not found */
			return NULL;
		}

		return lookup->second;
	}


	void CNode::update_path()
	{
		m_path = get_parent_path();
		m_path.append_element( m_name );
	}


	void CNode::update_all_paths()
	{
		update_path();

		node_endpoint_map &node_endpoints = m_node_endpoints;
		for( node_endpoint_map::iterator i = node_endpoints.begin(); i != node_endpoints.end(); i++ )
		{
			i->second->update_path();
		}

		for( node_map::iterator i = m_children.begin(); i != m_children.end(); i++ )
		{
			i->second->update_all_paths();
		}
	}


	void CNode::get_all_node_paths( path_list &results ) const
	{
		results.push_back( m_path );

		for( node_map::const_iterator i = m_children.begin(); i != m_children.end(); i++ )
		{
			i->second->get_all_node_paths( results );
		}
	}
}


