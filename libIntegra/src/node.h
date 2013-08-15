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

#ifndef INTEGRA_NODE_PRIVATE_H
#define INTEGRA_NODE_PRIVATE_H

#include <unordered_map>

#include "node_endpoint.h"
#include "api/node.h"
#include "api/path.h"
#include "api/common_typedefs.h"

using namespace integra_api;

namespace integra_api
{
	class IInterfaceDefinition;
}


namespace integra_internal
{
	class CLogic;

	typedef unsigned long internal_id;

	class CNode : public INode
	{
		public:
			CNode();
			~CNode();

			static const CNode *downcast( const INode *node ) { return dynamic_cast< const CNode * > ( node ); }
			static CNode *downcast_writable( INode *node ) { return dynamic_cast< CNode * > ( node ); }

			void initialize( const IInterfaceDefinition &interface_definition, const string &name, internal_id id, CNode *parent );

			void rename( const string &new_name );
			void reparent( CNode *new_parent );

			internal_id get_id() const { return m_id; }
			const IInterfaceDefinition &get_interface_definition() const { return *m_interface_definition; }

			const string &get_name() const { return m_name; }
			const CPath &get_path() const { return m_path; }

			const INode *get_parent() const { return m_parent; }
			CNode *get_parent_writable() { return m_parent; }

			/* returns an empty CPath when node has no parent */
			const CPath &get_parent_path() const;

			const node_map &get_children() const { return m_children; }
			node_map &get_children_writable() { return m_children; }

			const INode *get_child( const string &child_name ) const;

			const node_endpoint_map &get_node_endpoints() const { return m_node_endpoints; }
			node_endpoint_map &get_node_endpoints_writable() { return m_node_endpoints; }

			const INodeEndpoint *get_node_endpoint( const string &endpoint_name ) const;

			void get_all_node_paths( path_list &results ) const;

			CLogic &get_logic() const;

		private:

			void update_path();
			void update_all_paths();

			internal_id m_id;
			const IInterfaceDefinition *m_interface_definition;

			string m_name;
			CPath m_path;

			CNode *m_parent;
			node_map m_children;

			node_endpoint_map m_node_endpoints;

			CLogic *m_logic;
	};

	typedef std::list<const CNode *> node_list;
	typedef std::unordered_map<internal_id, const CNode *> map_id_to_node;

}


#endif
