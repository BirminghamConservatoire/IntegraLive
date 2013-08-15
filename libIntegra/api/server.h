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
#include "command_source.h"
#include "error.h"



namespace integra_api
{
	class CServerStartupInfo;
	class ICommand;
	class CCommandResult;

	class INTEGRA_API IServer
	{
		public:

			//todo - move out of libintegra
			virtual void block_until_shutdown_signal() = 0;

			virtual const node_map &get_nodes() const = 0;
			virtual const INode *find_node( const string &path_string, const INode *relative_to = NULL ) const = 0;
			virtual const node_map &get_siblings( const INode &node ) const = 0;

			virtual const INodeEndpoint *find_node_endpoint( const string &path_string, const INode *relative_to = NULL ) const = 0;

			virtual const CValue *get_value( const CPath &path ) const = 0;

			virtual CError process_command( ICommand *command, CCommandSource source, CCommandResult *result = NULL ) = 0;

	};
}



#endif 