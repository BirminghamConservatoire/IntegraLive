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

/** \file module_manager.h
 *  \brief Defines class IModuleManager
 */

#ifndef INTEGRA_MODULE_MANAGER_API_H
#define INTEGRA_MODULE_MANAGER_API_H

#include "common_typedefs.h"
#include "error.h"
#include "guid_helper.h"


namespace integra_api
{
	class CModuleInstallResult;
	class CModuleUninstallResult;
	class CLoadModuleInDevelopmentResult;

	/** \class IModuleManager module_manager.h "api/module_manager.h"
	 *  \brief Provides functionality to interact with 3rd party, embedded and in-development modules
	 *
	 *  see http://www.integralive.org/tutorials/module-development-guide/#what-is-a-module
	 */
	class INTEGRA_API IModuleManager
	{
		protected:

			IModuleManager() {}

		public:

			virtual ~IModuleManager() {}

			/** \brief install 3rd party module from a file
			 * 
			 * If the module is not already installed (as system or 3rd party), installs it (as a 3rd party module)
			 * \param module_file Path to the .module file to install
			 * \param[out] result CModuleInstallResult to receive information about the result of the operation
			 * \return an error code.  Can be CError::SUCCESS, CError::FILE_VALIDATION_ERROR, CError::FAILED, CError::INPUT_ERROR or CError::MODULE_ALREADY_INSTALLED 
			 */
			virtual CError install_module( const string &module_file, CModuleInstallResult &result ) = 0;

			/** \brief install a module which is embedded in a .integra file
			 * 
			 * When a .integra file is loaded which contains modules which are not currently loaded, they are loaded into
			 * memory as 'embedded' modules.  
			 * This command allows such embedded modules to be copied into the 3rd party modules directory ie installed as 3rd party modules
			 * \param module_id id of the embedded module to install
			 * \return an error code.  Can be CError::SUCCESS, CError::FAILED or CError::INPUT_ERROR 
			 */
			virtual CError install_embedded_module( const GUID &module_id ) = 0;

			/** \brief uninstall a 3rd party module
			 * 
			 * If there are existing instances of the 3rd party module to uninstall, the uninstallation goes ahead,
			 * but the module remains in memory as an 'embedded' module, and the existing instance remain.
			 * \param module_id id of the 3rd party module to uninstall
			 * \param[out] result CModuleUninstallResult to receive information about the result of the operation
			 * \return an error code.  Can be CError::SUCCESS, CError::FAILED or CError::INPUT_ERROR 
			 */
			virtual CError uninstall_module( const GUID &module_id, CModuleUninstallResult &result ) = 0;

			/** \brief load a module into memory without installing it
			 * 
			 * This function exists to enable a smooth workflow during module development.  A single module can be 
			 * loaded as IInterfaceDefinition::MODULE_IN_DEVELOPMENT, allowing seemless testing from Integra Module Creator
			 * There can only ever be one in-development module loaded at a time.
			 * If another in-development module is already loaded, it is unloaded, unless instances of the previous
			 * in-development module exist (in which case, the previous in-develepment module changes to IInterfaceDefinition::MODULE_EMBEDDED
			 * and remains in memory.  
			 * \param module_file Path to the .module file to install
			 * \param[out] result CLoadModuleInDevelopmentResult to receive information about the result of the operation
			 * \return an error code.  Can be CError::SUCCESS, CError::FAILED or CError::INPUT_ERROR 
			 */
			virtual CError load_module_in_development( const string &module_file, CLoadModuleInDevelopmentResult &result ) = 0;

			/** \brief unloads all embedded modules for which no instances exist
			 *
			 * When the last instance of an embedded module is deleted, the module is not automatically unloaded.
			 * This enables users of the libIntegra api to implement undo functionality - deleted modules can be re-added
			 * and will still exist.  unload_unused_embedded_modules allows for a tidy up of unused embedded modules
			 * \return and error code.  Can be xxx
			 */
			virtual CError unload_unused_embedded_modules() = 0;
	};


	/** \class CModuleInstallResult module_manager.h "api/module_manager.h"
	 *  \brief return structure for IModuleManager::install_module
	 */
	class INTEGRA_API CModuleInstallResult
	{
		public:
			/** id of the newly installed module.  Null if any error occurred */
			GUID module_id;

			/** true if the .module file had already been loaded as an embedded module */
			bool was_previously_embedded;
	};


	/** \class CModuleUninstallResult module_manager.h "api/module_manager.h"
	 *  \brief return structure for IModuleManager::uninstall_module
	 */
	class INTEGRA_API CModuleUninstallResult
	{
		public:
			/** true if there are existing instances of the 3rd party module to uninstall, in which case the module is 
			 * uninstalled, but remains in memory as an 'embedded' module, and the existing instances remain.
			 * false if there are no existing instances of the module 
			 */
			bool remains_as_embedded;
	};


	/** \class CLoadModuleInDevelopmentResult module_manager.h "api/module_manager.h"
	 *  \brief return structure for IModuleManager::load_module_in_development
	 */
	class INTEGRA_API CLoadModuleInDevelopmentResult
	{
		public:
			/** id of the newly loaded module, or null if any error occurred */
			GUID module_id;

			/** id of the previously loaded in-development module, or null no in development module was previously loaded */
			GUID previous_module_id;

			/** true if there are existing instances of the previously loaded in-development module, in which case 
			 * the previous module remains in memory as an 'embedded' module, and the existing instances remain.
			 * false if there was no previously loaded in-development module, or no existing instances of it */
			bool previous_remains_as_embedded;
	};
}



#endif 