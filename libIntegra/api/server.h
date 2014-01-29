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

/** \file server.h
 *  \brief Defines class IServer
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


	/** \class IServer server.h "api/server.h"
	 *  \brief Provides methods to query libIntegra and process commands
	 *
	 * \note All the methods of IServer assumes that the server is locked, ie that exactly one instance of CServerLock exists
	 * See documentation for CServerLock for a discussion of how to do this
	 */
	class INTEGRA_API IServer
	{
		protected:

			IServer() {}

		public:

			virtual ~IServer() {}

			/** \brief Get the ids of all the modules that are currently loaded */
			virtual const guid_set &get_all_module_ids() const = 0;

			/** \brief Lookup a module interface by its id 
			 * \return an IInterfaceDefinition, or NULL if not found 
			 */
			virtual const IInterfaceDefinition *find_interface( const GUID &module_id ) const = 0;

			/** \brief Get the set of top-level nodes
			 * \return a map of node name -> INode * containing all top-level nodes
			 * \note Actually, this function gets all the nodes in the system, since the top-level nodes
			 * can be interrogated for their children, and so on.  But only the top-level ones are directly 
			 * available by iterating the returned map */
			virtual const node_map &get_nodes() const = 0;

			/** \brief Lookup a node by it's path
			 *
			 * \param path absolute or relative path
			 * \param relative_to if provided, path is interpreted as being relative to this node.
			 * If NULL, path is interpreted to be absolute
			 * \return the looked-up node, or NULL if not found
			 */
			virtual const INode *find_node( const CPath &path, const INode *relative_to = NULL ) const = 0;
			virtual const node_map &get_siblings( const INode &node ) const = 0;

			virtual const INodeEndpoint *find_node_endpoint( const CPath &path, const INode *relative_to = NULL ) const = 0;

			virtual const CValue *get_value( const CPath &path ) const = 0;

			virtual CError process_command( ICommand *command, CCommandResult *result = NULL ) = 0;

			virtual IModuleManager &get_module_manager() const = 0;

			virtual string get_libintegra_version() const = 0;

			virtual void dump_libintegra_state() = 0;
			virtual void dump_dsp_state( const string &file ) = 0;
			virtual void ping_all_dsp_modules() = 0;

	};
}



#endif 