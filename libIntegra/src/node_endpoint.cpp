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

#include <assert.h>

#include "node_endpoint.h"
#include "node.h"
#include "api/value.h"
#include "interface_definition.h"
#include "api/trace.h"


namespace integra_internal
{
	CNodeEndpoint::CNodeEndpoint()
	{
		m_node = NULL;
		m_endpoint_definition = NULL;
		m_value = NULL;
	}


	CNodeEndpoint::~CNodeEndpoint()
	{
		if( m_value ) 
		{
			delete m_value;
		}
	}


	const CNodeEndpoint &CNodeEndpoint::downcast( const INodeEndpoint &node )
	{
		return dynamic_cast< const CNodeEndpoint & > ( node );
	}


	const CNodeEndpoint *CNodeEndpoint::downcast( const INodeEndpoint *node )
	{
		return dynamic_cast< const CNodeEndpoint * > ( node );
	}


	CNodeEndpoint *CNodeEndpoint::downcast_writable( INodeEndpoint *node )
	{
		return dynamic_cast< CNodeEndpoint * > ( node );
	}
	

	void CNodeEndpoint::initialize( const CNode &node, const IEndpointDefinition &endpoint_definition )
	{
		m_node = &node;
		m_endpoint_definition = &endpoint_definition;

		if( m_value ) 
		{
			delete m_value;
			m_value = NULL;
		}

		if( endpoint_definition.get_type() == CEndpointDefinition::CONTROL && endpoint_definition.get_control_info()->get_type() == CControlInfo::STATEFUL )
		{
			const IStateInfo *state_info = endpoint_definition.get_control_info()->get_state_info();
			assert( state_info );

			m_value = CValue::factory( state_info->get_type() );
		}

		update_path();
	}


	const INode &CNodeEndpoint::get_node() const
	{
		assert( m_node );
		return *m_node;
	}


	void CNodeEndpoint::update_path()
	{
		assert( m_node && m_endpoint_definition );

		m_path = m_node->get_path();
		m_path.append_element( m_endpoint_definition->get_name() );
	}



}


