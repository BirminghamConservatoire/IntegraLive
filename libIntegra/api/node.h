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

/** \file node.h
 *  \brief defines class INode
 */


#ifndef INTEGRA_NODE_API_H
#define INTEGRA_NODE_API_H

#include "common_typedefs.h"
#include "node_endpoint.h"
#include "path.h"


namespace integra_api
{
	class INode;
	class IInterfaceDefinition;
	typedef std::unordered_map<string, INode *> node_map;


	/** \class INode node.h "api/node.h"
	 *  \brief represents a node
	 *
	 * Nodes are instances of Integra Modules.  Each node has a set of endpoints and 
	 * can also have child nodes (allowing nodes to form a hierarchy).
	 */
	class INTEGRA_API INode
	{
		protected:

			INode() {}

		public:

			virtual ~INode() {}

			virtual const IInterfaceDefinition &get_interface_definition() const = 0;

			virtual const string &get_name() const = 0;
			virtual const CPath &get_path() const = 0;

			virtual const INode *get_parent() const = 0;

			/* returns an empty CPath when node has no parent */
			virtual const CPath &get_parent_path() const = 0;

			virtual const node_map &get_children() const = 0;

			virtual const INode *get_child( const string &child_name ) const = 0;

			virtual const node_endpoint_map &get_node_endpoints() const = 0;

			virtual const INodeEndpoint *get_node_endpoint( const string &endpoint_name ) const = 0;

			virtual void get_all_node_paths( path_list &results ) const = 0;
	};
}


#endif
