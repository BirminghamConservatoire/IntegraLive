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
#include "interface_definition.h"
#include "../externals/guiddef.h"
#include "node.h"
#include "error.h"


namespace ntg_internal
{
	class CModuleInstallResult;
	class CModuleUninstallResult;
	class CLoadModuleInDevelopmentResult;
	class CServer;


	class CModuleManager
	{
		public:

			CModuleManager( const CServer &server, const string &system_module_directory, const string &third_party_module_directory );
			~CModuleManager();

			/* returns ids of new embedded modules in new_embedded_modules */
			CError load_from_integra_file( const string &integra_file, guid_set &new_embedded_modules );

			CError install_module( const string &module_file, CModuleInstallResult &result );
			CError install_embedded_module( const GUID &module_id );
			CError uninstall_module( const GUID &module_id, CModuleUninstallResult &result );
			CError load_module_in_development( const string &module_file, CLoadModuleInDevelopmentResult &result );
			CError unload_orphaned_embedded_modules();

			void unload_modules( const guid_set &module_ids );

			const guid_set &get_all_module_ids() const;

			const CInterfaceDefinition *get_interface_by_module_id( const GUID &id ) const;
			const CInterfaceDefinition *get_interface_by_origin_id( const GUID &id ) const;
			const CInterfaceDefinition *get_core_interface_by_name( const string &name ) const;

			string get_unique_interface_name( const CInterfaceDefinition &interface_definition ) const;
			string get_patch_path( const CInterfaceDefinition &interface_definition ) const;

			CError interpret_legacy_module_id( internal_id old_id, GUID &output ) const;

			const static string s_module_suffix;

		private:

			void load_modules_from_directory( const string &module_directory, CInterfaceDefinition::module_source source );

			/* 
			 load_module only returns true if the module isn't already loaded
			 however, it stores the id of the loaded module in module_guid regardless of whether the module was already loaded
			*/
			bool load_module( const string &filename, CInterfaceDefinition::module_source source, GUID &module_guid );

			static CInterfaceDefinition *load_interface( unzFile unzip_file );

			CError extract_implementation( unzFile unzip_file, const CInterfaceDefinition &interface_definition, unsigned int &checksum );

			void unload_module( CInterfaceDefinition *interface_definition );

			string get_implementation_path( const CInterfaceDefinition &interface_definition ) const;
			string get_implementation_directory_name( const CInterfaceDefinition &interface_definition ) const;
			
			void delete_implementation( const CInterfaceDefinition &interface_definition );

			CError store_module( const GUID &module_id );

			void load_legacy_module_id_file();
			void unload_all_modules();

			string get_storage_path( const CInterfaceDefinition &interface_definition ) const;
			
			CError change_module_source( CInterfaceDefinition &interface_definition, CInterfaceDefinition::module_source new_source );

			bool is_module_in_use( const node_map &search_nodes, const GUID &module_id ) const;
			void remove_in_use_module_ids_from_set( const node_map &search_nodes, guid_set &set ) const;

			const CServer &m_server;

			guid_set m_module_ids;
			map_guid_to_interface_definition m_module_id_map;
			map_guid_to_interface_definition m_origin_id_map;
			map_string_to_interface_definition m_core_name_map;

			guid_array m_legacy_module_id_table;

			string m_implementation_directory_root;
			string m_third_party_module_directory;
			string m_embedded_module_directory;


			static const string s_module_inner_directory_name;
			static const string s_idd_file_name;
			static const string s_internal_implementation_directory_name;
			static const string s_implementation_directory_name;
			static const string s_embedded_module_directory_name;
			static const string s_legacy_class_id_filename;
			static const int s_checksum_seed;
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
