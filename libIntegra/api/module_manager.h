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

	class INTEGRA_API IModuleManager
	{
		protected:

			IModuleManager() {}

		public:

			virtual ~IModuleManager() {}

			virtual CError install_module( const string &module_file, CModuleInstallResult &result ) = 0;
			virtual CError install_embedded_module( const GUID &module_id ) = 0;
			virtual CError uninstall_module( const GUID &module_id, CModuleUninstallResult &result ) = 0;
			virtual CError load_module_in_development( const string &module_file, CLoadModuleInDevelopmentResult &result ) = 0;
			virtual CError unload_orphaned_embedded_modules() = 0;
	};


	class INTEGRA_API CModuleInstallResult
	{
		public:
			GUID module_id;
			bool was_previously_embedded;
	};


	class INTEGRA_API CModuleUninstallResult
	{
		public:
			bool remains_as_embedded;
	};


	class INTEGRA_API CLoadModuleInDevelopmentResult
	{
		public:
			GUID module_id;
			GUID previous_module_id;
			bool previous_remains_as_embedded;
	};
}



#endif 