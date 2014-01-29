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

/** \file node_endpoint.h
 *  \brief Defines class INodeEndpoint
 */


#ifndef INTEGRA_NODE_ENDPOINT_API_H
#define INTEGRA_NODE_ENDPOINT_API_H

#include "common_typedefs.h"



namespace integra_api
{
	class IEndpointDefinition;
	class INode;
	class CValue;
	class CPath;


	/** \class INodeEndpoint node_endpoint.h "api/node_endpoint.h"
	 *  \brief Represents a node endpoint
	 *
	 * Endpoints are the controls and stream i/o of Integra Modules.
	 *
	 * INodeEndpoint provides methods to query the endpoints of nodes (Module Instances)
	 */
	class INTEGRA_API INodeEndpoint
	{
		protected:

			INodeEndpoint() {}

		public: 
			
			virtual ~INodeEndpoint() {}

			/** \brief Get backreference to the node endpoint's owning node */
			virtual const INode &get_node() const = 0;

			/** \brief Get reference to the node endpoint's definition */
			virtual const IEndpointDefinition &get_endpoint_definition() const = 0;

			/** \brief Get pointer to the node endpoint's current value 
			 * \return If the node endpoint is a stateful control, returns current state.  Otherwise (stream or bang control) returns NULL.
			 */

			virtual const CValue *get_value() const = 0;

			/** \brief Get node endpoint's path
			 * 
			 * The node endpoint's path consists of the owning node's path, with the node endpoint's name (from the endpoint definition ) appended to it.
			 */
			virtual const CPath &get_path() const = 0;
	};


	/** Map endpoint name to node endpoint pointer */
	typedef std::unordered_map<string, INodeEndpoint *> node_endpoint_map;
}



#endif
