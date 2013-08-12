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

#include "state_table.h"
#include "trace.h"


namespace integra_internal
{
	CStateTable::CStateTable()
	{
	}


	CStateTable::~CStateTable()
	{
	}


	void CStateTable::add( CNode &node )
	{
		/* add self to path map */
		const string &path = node.get_path();
		if( m_nodes.count( path ) > 0 )
		{
			NTG_TRACE_ERROR << "duplicate key in state table: " << path;
		}
		else
		{
			m_nodes[ path ] = &node;
		}

		/* add self to id map */
		internal_id id = node.get_id();
		if( m_nodes_by_id.count( id ) > 0 )
		{
			NTG_TRACE_ERROR << "duplicate key in state table: " << id;
		}
		else
		{
			m_nodes_by_id[ id ] = &node;
		}

		/* add node endpoints */
		node_endpoint_map node_endpoints = node.get_node_endpoints_writable();
		for( node_endpoint_map::const_iterator i = node_endpoints.begin(); i != node_endpoints.end(); i++ )
		{
			CNodeEndpoint *node_endpoint = i->second;
			const string &path = node_endpoint->get_path();
			if( m_node_endpoints.count( path ) > 0 )
			{
				NTG_TRACE_ERROR << "duplicate key in state table: " << path;
			}
			else
			{
				m_node_endpoints[ path ] = node_endpoint;
			}
		}

		/* add child nodes */
		node_map &children = node.get_children_writable();
		for( node_map::iterator i = children.begin(); i != children.end(); i++ )
		{
			CNode *child = i->second;
			add( *child );
		}
	}


	void CStateTable::remove( const CNode &node )
	{
		/* remove self from path map */
		const string &path = node.get_path();
		if( m_nodes.count( path ) != 1 )
		{
			NTG_TRACE_ERROR << "missing key in state table: " << path;
		}
		else
		{
			m_nodes.erase( path );
		}

		/* remove self from id map */
		internal_id id = node.get_id();
		if( m_nodes_by_id.count( id ) != 1 )
		{
			NTG_TRACE_ERROR << "missing key in state table: " << id;
		}
		else
		{
			m_nodes_by_id.erase( id );
		}

		/* remove node endpoints */
		const node_endpoint_map node_endpoints = node.get_node_endpoints();
		for( node_endpoint_map::const_iterator i = node_endpoints.begin(); i != node_endpoints.end(); i++ )
		{
			const CNodeEndpoint *node_endpoint = i->second;
			const string &path = node_endpoint->get_path();
			if( m_node_endpoints.count( path ) != 1 )
			{
				NTG_TRACE_ERROR << "missing key in state table: " << path;
			}
			else
			{
				m_node_endpoints.erase( path );
			}
		}

		/* remove child nodes */
		const node_map &children = node.get_children();
		for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
		{
			const CNode *child = i->second;
			remove( *child );
		}
	}


	const CNode *CStateTable::lookup_node( const string &path ) const
	{
		node_map::const_iterator lookup = m_nodes.find( path );
		if( lookup == m_nodes.end() )
		{
			/* not found */
			return NULL;
		}

		return lookup->second;
	}


	CNode *CStateTable::lookup_node_writable( const string &path )
	{
		node_map::iterator lookup = m_nodes.find( path );
		if( lookup == m_nodes.end() )
		{
			/* not found */
			return NULL;
		}

		return lookup->second;
	}
			

	const CNode *CStateTable::lookup_node( internal_id id ) const
	{
		map_id_to_node::const_iterator lookup = m_nodes_by_id.find( id );
		if( lookup == m_nodes_by_id.end() )
		{
			/* not found */
			return NULL;
		}

		return lookup->second;
	}


	const CNodeEndpoint *CStateTable::lookup_node_endpoint( const string &path ) const
	{
		node_endpoint_map::const_iterator lookup = m_node_endpoints.find( path );
		if( lookup == m_node_endpoints.end() )
		{
			/* not found */
			return NULL;
		}

		return lookup->second;
	}


	CNodeEndpoint *CStateTable::lookup_node_endpoint_writable( const string &path )
	{
		node_endpoint_map::iterator lookup = m_node_endpoints.find( path );
		if( lookup == m_node_endpoints.end() )
		{
			/* not found */
			return NULL;
		}

		return lookup->second;
	}




}	

