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
			 * available by iterating the returned map 
			 */
			virtual const node_map &get_nodes() const = 0;

			/** \brief Lookup a node by its path
			 *
			 * \param path absolute or relative path
			 * \param relative_to if provided, path is interpreted as being relative to this node.
			 * If NULL, path is interpreted to be absolute
			 * \return the looked-up node, or NULL if not found
			 */
			virtual const INode *find_node( const CPath &path, const INode *relative_to = NULL ) const = 0;

			/** \brief Get a node's sibling set
			 *
			 * This helper is more convenient than using INode's tree traversal functions, because it can also get
			 * siblings of top-level nodes.
			 * \param node The node who's sibling set we're interested in
			 * \return All of the node's siblings, including itself
			 */
			virtual const node_map &get_siblings( const INode &node ) const = 0;

			/** \brief Lookup a node endpoint by its path
			 *
			 * \param path absolute or relative path
			 * \param relative_to if provided, path is interpreted as being relative to this node.
			 * If NULL, path is interpreted to be absolute
			 * \return the looked-up node endpoint, or NULL if not found
			 */
			virtual const INodeEndpoint *find_node_endpoint( const CPath &path, const INode *relative_to = NULL ) const = 0;

			/** \brief Lookup the value of a stateful control node endpoint
			 *
			 * \param path path of the node endpoint
			 * \return the node endpoint's value, or NULL if node endpoint not found, not a control or not stateful
			 */
			virtual const CValue *get_value( const CPath &path ) const = 0;

			/** \brief Alter libIntegra's state by passing in a subclass of CCommand 
			 *
			 * \param command The command should be created using one of the IXXXCommand::create methods (see ICommand)
			 * \param result If the caller needs feedback about what the command did, pass a pointer to the relevent
			 * subclass of CCommandResult here.  It is the caller's responsibility to ensure that this object is of
			 * the correct type to match command (see CCommandResult).
			 * \note Unusually, this method expects to be passed commands which have been created on the heap, and assumes
			 * responsibility for deleting them itself.  The reason for this is a) to maximise cleanliness of calling code - 
			 * commands can be created and processed inline and b) for maximum efficiency if we wanted to add an undo/redo stack
			 * to libIntegra at some future time.
			 * \return an error code, or CError::SUCCESS if no error.  See CError for all the codes.
			 */
			virtual CError process_command( ICommand *command, CCommandResult *result = NULL ) = 0;

			/** \brief Get the Module Manager.  See IModuleManager
			 */			
			virtual IModuleManager &get_module_manager() const = 0;

			/** \brief Get version number
			 *
			 * Version number are provided as a dot-separated string containing four numbers: major version, minor version, patch number, build number
			 * Build numbers should always go up, that is they are not reset to 0 when we change any other part of the version number.
			 * So comparing build numbers should be sufficient to test whether one version is more recent that another.
			 */			
			virtual string get_libintegra_version() const = 0;

			/** \brief Testing function
			 *
			 * Dumps state of all existing nodes and their stateful endpoints to output console
			 */			
			virtual void dump_libintegra_state() = 0;

			/** \brief Testing function
			 *
			 * Uses undocumented libPD function to write libPD's internal state to the specified file as a pd patch
			 */			
			virtual void dump_dsp_state( const string &file ) = 0;

			/** \brief Testing function
			 *
			 * Sends a ping command to all dsp modules, and dumps to output console info about which responded ok
			 */			
			virtual void ping_all_dsp_modules() = 0;

	};
}



#endif 