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


#ifndef INTEGRA_STATE_TABLE_H
#define INTEGRA_STATE_TABLE_H

#include "api/common_typedefs.h"
#include "node.h"
#include "node_endpoint.h"


namespace ntg_internal
{
	class CStateTable
	{
		public:

			CStateTable();
			~CStateTable();

			void add( CNode &node );
			void remove( const CNode &node );

			const CNode *lookup_node( const string &path ) const;
			CNode *lookup_node_writable( const string &path );
			
			const CNode *lookup_node( internal_id id ) const;

			const CNodeEndpoint *lookup_node_endpoint( const string &path ) const;
			CNodeEndpoint *lookup_node_endpoint_writable( const string &path );

		private:

			node_map m_nodes;
			map_id_to_node m_nodes_by_id;
			node_endpoint_map m_node_endpoints;
	};
}


#endif
