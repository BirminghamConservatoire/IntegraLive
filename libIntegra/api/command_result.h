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


/** \file command_result.h
 *  \brief return values from commans
 *   
 *  Some libIntegra commands can return information to their caller.  
 *  This is done through a set of 'command result' classes.
 *  
 *  To obtain command result information, users of libIntegra api should
 *  create a local variable of the desired command result class, and pass 
 *  it's address into IServer::process_command.
 */


#ifndef COMMAND_RESULT_API_H
#define COMMAND_RESULT_API_H

#include "guid_helper.h"


namespace integra_api
{
	class INode;


	/** \class CCommandResult command_result.h "api/command_result.h"
	 *  \brief Base class for all command result classes
	 *
	 * Users of libIntegra's api do not need to use CCommandResult directly.  
	 */
	class INTEGRA_API CCommandResult
	{
		protected:
			CCommandResult() {};
		public:
			virtual ~CCommandResult() {};
	};


	/** \class CNewCommandResult command_result.h "api/command_result.h"
	 *  \brief Represents return information for INewCommand
	 * 
	 * Allows users of INewCommand to obtain pointers to newly created nodes.
	 * This could be used when constructing a hierarchy of nodes
	 */
	class INTEGRA_API CNewCommandResult : public CCommandResult
	{
		public:
			CNewCommandResult() { m_created_node = NULL; }
			~CNewCommandResult() {};

			/** \brief retrieve a pointer to the newly created node
			 * \return a pointer to the node, or NULL if the command failed (or was a different type of command)
			 */
			const INode *get_created_node() const { return m_created_node; }

			/** \brief internal use only
			 */
			void set_created_node( const INode *created_node ) { m_created_node = created_node; }

		private:
			const INode *m_created_node;
	};

	
	/** \class CLoadCommandResult command_result.h "api/command_result.h"
	 *  \brief Represents return information for ILoadCommand
	 * 
	 * Allows users of ILoadCommand to obtain guids of any newly loaded embedded modules
	 */
	class INTEGRA_API CLoadCommandResult : public CCommandResult
	{
		public:
			CLoadCommandResult() {};
			~CLoadCommandResult() {};

			/** \brief retrieve the ids of new embedded modules
			 *
			 * If the loaded file contains embedded modules that are not already present in the current IntegraSession,
			 * these modules are loaded with a module_source of MODULE_EMBEDDED (see IInterfaceDefinition).  
			 * The guids of these new modules can be obtained here.
			 * Reasons embedded modules might be loaded:
			 * Loading a project which contains older versions of shipped-with-libIntegra modules
			 * Loading a project which contains modules that were shipped with older versions of libIntegra, but no longer shipped
			 * Loading a project which contains 3rd party modules not present on this system
			 * Loading a project which contains older/newer/different versions of 3rd party modules that are present on this system
			 * 
			 * \return a reference to the set of new embedded module guids, or an empty set if the command failed (or was a different type of command)
			 */
			const guid_set &get_new_embedded_module_ids() const { return m_new_embedded_module_ids; }

			/** \brief internal use only
			 */
			void set_new_embedded_module_ids( const guid_set &ids ) { m_new_embedded_module_ids = ids; }

		private:
			guid_set m_new_embedded_module_ids;

	};
}


#endif 