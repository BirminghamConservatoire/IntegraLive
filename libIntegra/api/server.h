/* libIntegra multimedia module info interface
 *
 * Copyright (C) 2007 Jamie Bullock, Henrik Frisk
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

#ifndef INTEGRA_SERVER_API_H
#define INTEGRA_SERVER_API_H

#include "common_typedefs.h"
#include "node.h"
#include "node_endpoint.h"
#include "error.h"
#include "guid_helper.h"



namespace integra_api
{
	class CServerStartupInfo;
	class CCommandResult;
	class ICommand;
	class IModuleManager;
	class IInterfaceDefinition;


	class INTEGRA_API IServer
	{
		protected:

			IServer() {}

		public:

			virtual ~IServer() {}

			virtual const guid_set &get_all_module_ids() const = 0;
			virtual const IInterfaceDefinition *find_interface( const GUID &module_id ) const = 0;

			virtual const node_map &get_nodes() const = 0;
			virtual const INode *find_node( const string &path_string, const INode *relative_to = NULL ) const = 0;
			virtual const node_map &get_siblings( const INode &node ) const = 0;

			virtual const INodeEndpoint *find_node_endpoint( const string &path_string, const INode *relative_to = NULL ) const = 0;

			virtual const CValue *get_value( const CPath &path ) const = 0;

			virtual CError process_command( ICommand *command, CCommandResult *result = NULL ) = 0;

			virtual IModuleManager &get_module_manager() const = 0;

			virtual string get_libintegra_version() const = 0;

			virtual void dump_state() = 0;
	};
}



#endif 