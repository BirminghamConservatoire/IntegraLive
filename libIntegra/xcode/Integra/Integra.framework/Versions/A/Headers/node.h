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
 *  \brief Defines class INode
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

	/** Map node name to node pointer */
	typedef std::unordered_map<string, INode *> node_map;


	/** \class INode node.h "api/node.h"
	 *  \brief Represents a node
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

			/** \brief Get the node's interface definition */
			virtual const IInterfaceDefinition &get_interface_definition() const = 0;

			/** \brief Get the node's name */
			virtual const string &get_name() const = 0;

			/** \brief Get the node's path */
			virtual const CPath &get_path() const = 0;

			/** \brief Get the node's parent 
			 * \return parent node, or NULL if node resides at top level of node hierarchy
			 */
			virtual const INode *get_parent() const = 0;

			/** \brief Get node's parent's path
			 *
			 * Allows relative paths to be resolved without tedious NULL-checking
			 * \return parent node's path, or an empty CPath when node has no parent
			 */
			virtual const CPath &get_parent_path() const = 0;

			/** \brief Get all of a node's child nodes
			 *
			 * \note libIntegra has no concept of order within sibling nodes.  
			 * Child nodes can be iterated over, but the order is arbitrary.
			 * \return map of child name -> INode *
			 */
			virtual const node_map &get_children() const = 0;

			/** \brief Lookup a specific child node
			 *
			 * \param child_name The name of the child node to lookup
			 * \return The child node, or NULL if not found
			 */
			virtual const INode *get_child( const string &child_name ) const = 0;

			/** \brief Get all of a node's endpoints
			 * \return map of endpoint name -> INodeEndpoint *
			 */
			virtual const node_endpoint_map &get_node_endpoints() const = 0;

			/** \brief Lookup a specific node endpoint
			 *
			 * \param endpoint_name The name of the node endpoint to lookup
			 * \return The node endpoint, or NULL if not found
			 */
			virtual const INodeEndpoint *get_node_endpoint( const string &endpoint_name ) const = 0;

			/** \brief Recursively walk node tree building depth-first pre-order list of all node paths
			 *
			 * \param[out] results The paths of all the nodes are stored in this list
			 */
			virtual void get_all_node_paths( path_list &results ) const = 0;
	};
}


#endif
