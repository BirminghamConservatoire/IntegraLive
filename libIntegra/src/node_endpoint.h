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

#ifndef INTEGRA_NODE_ENDPOINT_H
#define INTEGRA_NODE_ENDPOINT_H


#include <unordered_map>

#include "api/common_typedefs.h"
#include "api/path.h"
#include "api/value.h"
#include "api/node_endpoint.h"


using namespace integra_api;

namespace integra_api
{
	class IEndpointDefinition;
}


namespace integra_internal
{
	class CNode;

	class CNodeEndpoint : public INodeEndpoint
	{
		public: 
			
			CNodeEndpoint();
			~CNodeEndpoint();

			static const CNodeEndpoint *downcast( const INodeEndpoint *node );
			static CNodeEndpoint *downcast_writable( INodeEndpoint *node );

			void initialize( const CNode &node, const IEndpointDefinition &endpoint_definition );

			const INode &get_node() const;

			const IEndpointDefinition &get_endpoint_definition() const { return *m_endpoint_definition; }

			const CValue *get_value() const { return m_value; }
			const CPath &get_path() const { return m_path; }

			CValue *get_value_writable() { return m_value; }

			void update_path();

		private:

			const CNode *m_node;
			const IEndpointDefinition *m_endpoint_definition;

			CValue *m_value;
			CPath m_path;
	};
}



#endif
