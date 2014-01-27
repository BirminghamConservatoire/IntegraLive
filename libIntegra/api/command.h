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

/** \file command.h
 *  \brief defines command interfaces
 *   
 *  libIntegra provides a set of command classes, which are exposed to users of the api 
 *  through the interfaces defined in this file.  All actions which modify the state of 
 *  an Integra Session are represented by these commands.
 *  
 *  Clients of libIntegra api should execute commands by creating instances of the
 *  command classes (using their static create methods), and passing the created commands into
 *  IServer::process_command
 */



#ifndef COMMAND_API_H
#define COMMAND_API_H

#include "common_typedefs.h"
#include "error.h"


namespace integra_internal
{
	class CServer;
}


namespace integra_api
{
	class CPath;
	class CValue;
	class CCommandResult;
	class CCommandSource;
	
	/** \class ICommand command.h "api/command.h"
	 *  \brief Base class for all libIntegra commands
	 *
	 * Users of libIntegra's api do not need to use ICommand directly.  
	 */

	class INTEGRA_API ICommand
	{
		protected:
			ICommand() {}
		public:

			virtual ~ICommand() {}

			virtual CError execute( integra_internal::CServer &server, CCommandSource source, CCommandResult *result ) = 0;
	};


	/** \class INewCommand command.h "api/command.h"
	 *  \brief Command to add new nodes to the node hierarchy
	 */
	class INTEGRA_API INewCommand : public ICommand
	{
		protected:
			INewCommand() {}
		public:
			virtual ~INewCommand() {}

			static INewCommand *create( const GUID &module_id, const string &node_name, const CPath &parent_path );
	};


	/** \class IDeleteCommand command.h "api/command.h"
	 *  \brief Command to delete nodes from the node hierarchy
	 */
	class INTEGRA_API IDeleteCommand : public ICommand
	{
		protected:
			IDeleteCommand() {}
		public:
			virtual ~IDeleteCommand() {}

			static IDeleteCommand *create( const CPath &path );
	};


	/** \class ISetCommand command.h "api/command.h"
	 *  \brief Command to set 'control' type node endpoints
	 */
	class INTEGRA_API ISetCommand : public ICommand
	{
		protected:
			ISetCommand() {}
		public:
			virtual ~ISetCommand() {}

			static ISetCommand *create( const CPath &endpoint_path, const CValue &value );
			static ISetCommand *create( const CPath &endpoint_path );

			virtual const CPath &get_endpoint_path() const = 0;

	};


	/** \class IRenameCommand command.h "api/command.h"
	 *  \brief Command to rename nodes
	 */
	class INTEGRA_API IRenameCommand : public ICommand
	{
		protected:
			IRenameCommand() {}
		public:
			virtual ~IRenameCommand() {}

			static IRenameCommand *create( const CPath &path, const string &new_name );
	};


	/** \class IMoveCommand command.h "api/command.h"
	 *  \brief Command to move nodes to different branches of the node hierarchy
	 */
	class INTEGRA_API IMoveCommand : public ICommand
	{
		protected:
			IMoveCommand() {}
		public:
			virtual ~IMoveCommand() {}

			static IMoveCommand *create( const CPath &node_path, const CPath &new_parent_path );
	};


	/** \class ILoadCommand command.h "api/command.h"
	 *  \brief Command to load node hierarchies, associated data files and embedded modules from .integra files
	 */
	class INTEGRA_API ILoadCommand : public ICommand
	{
		protected:
			ILoadCommand() {}
		public:
			virtual ~ILoadCommand() {}

			static ILoadCommand *create( const string &file_path, const CPath &parent_path );
	};


	/** \class ILoadCommand command.h "api/command.h"
	 *  \brief Command to save node hierarchies, associated data files and embedded modules to .integra files
	 */
	class INTEGRA_API ISaveCommand : public ICommand
	{
		protected:
			ISaveCommand() {}
		public:
			virtual ~ISaveCommand() {}

			static ISaveCommand *create( const string &file_path, const CPath &node_path );
	};
}


#endif 