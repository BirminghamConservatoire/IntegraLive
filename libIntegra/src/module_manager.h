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


#include "Integra/integra.h"
#include "common_typedefs.h"
#include "interface.h"
#include "../externals/guiddef.h"
#include "node.h"

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
			ntg_error_code load_from_integra_file( const ntg_api::string &integra_file, ntg_api::guid_set &new_embedded_modules );

			ntg_error_code install_module( const ntg_api::string &module_file, CModuleInstallResult &result );
			ntg_error_code install_embedded_module( const GUID &module_id );
			ntg_error_code uninstall_module( const GUID &module_id, CModuleUninstallResult &result );
			ntg_error_code load_module_in_development( const ntg_api::string &module_file, CLoadModuleInDevelopmentResult &result );


			const ntg_api::guid_set &get_all_module_ids() const;

			const ntg_interface *get_interface_by_module_id( const GUID &id ) const;
			const ntg_interface *get_interface_by_origin_id( const GUID &id ) const;
			const ntg_interface *get_core_interface_by_name( const ntg_api::string &name ) const;

			ntg_api::string get_unique_interface_name( const ntg_interface &interface ) const;
			ntg_api::string get_patch_path( const ntg_interface &interface ) const;

			void get_orphaned_embedded_modules( const ntg_node &root_node, ntg_api::guid_set &results );
			void unload_modules( const ntg_api::guid_set &module_ids );

			ntg_error_code interpret_legacy_module_id( ntg_id old_id, GUID &output ) const;

		private:

			void load_modules_from_directory( const ntg_api::string &module_directory, ntg_module_source module_source );

			/* 
			 load_module only returns true if the module isn't already loaded
			 however, it stores the id of the loaded module in module_guid regardless of whether the module was already loaded
			*/
			bool load_module( const ntg_api::string &filename, ntg_module_source module_source, GUID &module_guid );

			static ntg_interface *load_interface( unzFile unzip_file );

			ntg_error_code extract_implementation( unzFile unzip_file, const ntg_interface &interface, unsigned int &checksum );

			void unload_module( ntg_interface *interface );

			ntg_api::string get_implementation_path( const ntg_interface &interface ) const;
			ntg_api::string get_implementation_directory_name( const ntg_interface &interface ) const;
			
			void delete_implementation( const ntg_interface &interface );

			ntg_error_code store_module( const GUID &module_id );

			void load_legacy_module_id_file();
			void unload_all_modules();

			ntg_api::string get_storage_path( const ntg_interface &interface ) const;
			
			ntg_error_code change_module_source( ntg_interface &interface, ntg_module_source new_source );


			ntg_api::guid_set m_module_ids;
			map_guid_to_interface m_module_id_map;
			map_guid_to_interface m_origin_id_map;
			map_string_to_interface m_core_name_map;

			GUID *m_legacy_module_id_table;
			int m_legacy_module_id_table_elems;

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



#if 0 //DEPRECATED

struct ntg_module_manager_
{
	ntg_api::guid_set module_ids;
	map_guid_to_interface module_id_map;
	map_guid_to_interface origin_id_map;
	map_string_to_interface core_name_map;

	GUID *legacy_module_id_table;
	int legacy_module_id_table_elems;

    char *implementation_directory_root;

	char *third_party_module_directory;
	char *embedded_module_directory;
};


struct ntg_module_install_result_
{
	GUID module_id;
	bool was_previously_embedded;
};


struct ntg_module_uninstall_result_
{
	bool remains_as_embedded;
};


struct ntg_load_module_in_development_result_
{
	GUID module_id;
	GUID previous_module_id;
	bool previous_remains_as_embedded;
};



ntg_module_manager *ntg_module_manager_create( const char *scratch_directory_root, const char *system_module_directory, const char *third_party_module_directory );
void ntg_module_manager_free( ntg_module_manager *module_manager );

/* returns ids of new embedded modules in new_embedded_modules */
ntg_error_code ntg_module_manager_load_from_integra_file( ntg_module_manager *module_manager, const char *integra_file, ntg_api::guid_set &new_embedded_modules );

ntg_error_code ntg_module_manager_install_module( ntg_module_manager *module_manager, const char *module_file, ntg_module_install_result *result );
ntg_error_code ntg_module_manager_install_embedded_module( ntg_module_manager *module_manager, const GUID *module_id );
ntg_error_code ntg_module_manager_uninstall_module( ntg_module_manager *module_manager, const GUID *module_id, ntg_module_uninstall_result *module_uninstall_result );
ntg_error_code ntg_module_manager_load_module_in_development( ntg_module_manager *module_manager, const char *module_file, ntg_load_module_in_development_result *result );

const ntg_api::guid_set &ntg_module_id_set( const ntg_module_manager *module_manager );

const ntg_interface *ntg_get_interface_by_module_id( const ntg_module_manager *module_manager, const GUID *id );
const ntg_interface *ntg_get_interface_by_origin_id( const ntg_module_manager *module_manager, const GUID *id );
const ntg_interface *ntg_get_core_interface_by_name( const ntg_module_manager *module_manager, const char *name );

char *ntg_module_manager_get_unique_interface_name( const ntg_interface *interface );
char *ntg_module_manager_get_patch_path( const ntg_module_manager *module_manager, const ntg_interface *interface );

void ntg_module_manager_get_orphaned_embedded_modules( const ntg_module_manager *module_manager, const ntg_node &root_node, ntg_api::guid_set &results );
void ntg_module_manager_unload_modules( ntg_module_manager *module_manager, const ntg_api::guid_set &module_ids );

ntg_error_code ntg_interpret_legacy_module_id( const ntg_module_manager *module_manager, ntg_id old_id, GUID *output );


#endif //DEPRECATED

#endif
