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
#include "Integra/integra_bridge.h"
#include "path.h"


namespace ntg_internal
{
	class CNode;
	class CEndpointDefinition;	

	class CNodeEndpoint
	{
		public: 
			
			CNodeEndpoint();
			~CNodeEndpoint();

			void initialize( const CNode &node, const CEndpointDefinition &endpoint_definition );

			const CNode &get_node() const { return *m_node; }
			const CEndpointDefinition &get_endpoint_definition() const { return *m_endpoint_definition; }

			const ntg_api::CValue *get_value() const { return m_value; }
			const ntg_api::CPath &get_path() const { return m_path; }

			ntg_api::CValue *get_value_writable() { return m_value; }

			/* todo - this method would be better in the endpoint definition class, when it has been made */
			bool test_constraint( const ntg_api::CValue &value ) const;

			void update_path();

		private:

			const CNode *m_node;
			const CEndpointDefinition *m_endpoint_definition;

			ntg_api::CValue *m_value;
			ntg_api::CPath m_path;
	};

	typedef std::unordered_map<ntg_api::string, CNodeEndpoint *> node_endpoint_map;

}



#endif
