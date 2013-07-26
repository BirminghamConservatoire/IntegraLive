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

#ifndef INTEGRA_MODULE_MANAGER_PRIVATE_H
#define INTEGRA_MODULE_MANAGER_PRIVATE_H

#include "../externals/minizip/zip.h"
#include "../externals/minizip/unzip.h"

#include "api/common_typedefs.h"
#include "interface.h"
#include "../externals/guiddef.h"
#include "node.h"
#include "error.h"

#ifdef _WINDOWS
	#ifdef interface 
		#undef interface
	#endif
#endif


namespace ntg_internal
{
	class CModuleInstallResult;
	class CModuleUninstallResult;
	class CLoadModuleInDevelopmentResult;


	class CModuleManager
	{
		public:

			CModuleManager( const ntg_api::string &scratch_directory_root, const ntg_api::string &system_module_directory, const ntg_api::string &third_party_module_directory );
			~CModuleManager();

			/* returns ids of new embedded modules in new_embedded_modules */
			ntg_api::error_code load_from_integra_file( const ntg_api::string &integra_file, ntg_api::guid_set &new_embedded_modules );

			ntg_api::error_code install_module( const ntg_api::string &module_file, CModuleInstallResult &result );
			ntg_api::error_code install_embedded_module( const GUID &module_id );
			ntg_api::error_code uninstall_module( const GUID &module_id, CModuleUninstallResult &result );
			ntg_api::error_code load_module_in_development( const ntg_api::string &module_file, CLoadModuleInDevelopmentResult &result );


			const ntg_api::guid_set &get_all_module_ids() const;

			const ntg_interface *get_interface_by_module_id( const GUID &id ) const;
			const ntg_interface *get_interface_by_origin_id( const GUID &id ) const;
			const ntg_interface *get_core_interface_by_name( const ntg_api::string &name ) const;

			ntg_api::string get_unique_interface_name( const ntg_interface &interface ) const;
			ntg_api::string get_patch_path( const ntg_interface &interface ) const;

			void get_orphaned_embedded_modules( const node_map &search_nodes, ntg_api::guid_set &results ) const;
			void unload_modules( const ntg_api::guid_set &module_ids );

			ntg_api::error_code interpret_legacy_module_id( internal_id old_id, GUID &output ) const;

		private:

			void load_modules_from_directory( const ntg_api::string &module_directory, ntg_module_source module_source );

			/* 
			 load_module only returns true if the module isn't already loaded
			 however, it stores the id of the loaded module in module_guid regardless of whether the module was already loaded
			*/
			bool load_module( const ntg_api::string &filename, ntg_module_source module_source, GUID &module_guid );

			static ntg_interface *load_interface( unzFile unzip_file );

			ntg_api::error_code extract_implementation( unzFile unzip_file, const ntg_interface &interface, unsigned int &checksum );

			void unload_module( ntg_interface *interface );

			ntg_api::string get_implementation_path( const ntg_interface &interface ) const;
			ntg_api::string get_implementation_directory_name( const ntg_interface &interface ) const;
			
			void delete_implementation( const ntg_interface &interface );

			ntg_api::error_code store_module( const GUID &module_id );

			void load_legacy_module_id_file();
			void unload_all_modules();

			ntg_api::string get_storage_path( const ntg_interface &interface ) const;
			
			ntg_api::error_code change_module_source( ntg_interface &interface, ntg_module_source new_source );

			bool is_module_in_use( const node_map &search_nodes, const GUID &module_id ) const;
			void remove_in_use_module_ids_from_set( const node_map &search_nodes, ntg_api::guid_set &set ) const;


			ntg_api::guid_set m_module_ids;
			map_guid_to_interface m_module_id_map;
			map_guid_to_interface m_origin_id_map;
			map_string_to_interface m_core_name_map;

			ntg_api::guid_array m_legacy_module_id_table;

			ntg_api::string m_implementation_directory_root;

			ntg_api::string m_third_party_module_directory;
			ntg_api::string m_embedded_module_directory;
	};



	class CModuleInstallResult
	{
		public:
			GUID module_id;
			bool was_previously_embedded;
	};


	class CModuleUninstallResult
	{
		public:
			bool remains_as_embedded;
	};


	class CLoadModuleInDevelopmentResult
	{
		public:
			GUID module_id;
			GUID previous_module_id;
			bool previous_remains_as_embedded;
	};
}


#endif
