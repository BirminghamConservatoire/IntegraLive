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

#ifndef INTEGRA_INSTANCE_PRIVATE_H
#define INTEGRA_INSTANCE_PRIVATE_H

#include <unordered_map>

#include "node_endpoint.h"
#include "path.h"
#include "api/common_typedefs.h"

#ifndef __XML_XMLREADER_H__
#ifndef NTG_TEXTREADER_TYPEDEF
typedef struct _xmlTextReader xmlTextReader;
typedef xmlTextReader *xmlTextReaderPtr;
#define NTG_TEXTREADER_TYPEDEF
#endif 
#endif


namespace ntg_internal
{
	class CNode;
	class CInterfaceDefinition;

	typedef std::list<const CNode *> node_list;
	typedef std::unordered_map<ntg_api::string, CNode *> node_map;
	typedef std::unordered_map<internal_id, const CNode *> map_id_to_node;


	class CNode
	{
		public:
			CNode();
			~CNode();

			void initialize( const CInterfaceDefinition &interface_definition, const ntg_api::string &name, internal_id id, CNode *parent );

			void rename( const ntg_api::string &new_name );
			void reparent( CNode *new_parent );

			internal_id get_id() const { return m_id; }
			const CInterfaceDefinition &get_interface_definition() const { return *m_interface_definition; }

			const ntg_api::string &get_name() const { return m_name; }
			const ntg_api::CPath &get_path() const { return m_path; }

			const CNode *get_parent() const { return m_parent; }
			CNode *get_parent_writable() { return m_parent; }

			/* returns an empty CPath when node has no parent */
			const ntg_api::CPath &get_parent_path() const;

			const node_map &get_children() const { return m_children; }
			node_map &get_children_writable() { return m_children; }

			const CNode *get_child( const ntg_api::string &child_name ) const;

			const node_endpoint_map &get_node_endpoints() const { return m_node_endpoints; }
			node_endpoint_map &get_node_endpoints_writable() { return m_node_endpoints; }

			const CNodeEndpoint *get_node_endpoint( const ntg_api::string &endpoint_name ) const;

			void get_all_node_paths( ntg_api::path_list &results ) const;


		private:

			void update_path();
			void update_all_paths();

			internal_id m_id;
			const CInterfaceDefinition *m_interface_definition;

			ntg_api::string m_name;
			ntg_api::CPath m_path;

			CNode *m_parent;
			node_map m_children;

			node_endpoint_map m_node_endpoints;
	};
}


#endif
