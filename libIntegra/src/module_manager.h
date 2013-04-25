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

#ifdef __cplusplus
extern "C" {
#endif

#include "Integra/integra.h"
#include "hashtable.h"
#include "node.h"
#include "../externals/guiddef.h"

#ifdef _WINDOWS
	#ifdef interface 
		#undef interface
	#endif
#endif

#ifndef NTG_INTERFACE_TYPEDEF
typedef struct ntg_interface_ ntg_interface;
#define NTG_INTERFACE_TYPEDEF
#endif

typedef struct ntg_module_manager_ ntg_module_manager;
typedef struct ntg_module_install_result_ ntg_module_install_result;
typedef struct ntg_bundle_install_result_ ntg_bundle_install_result;
typedef struct ntg_module_uninstall_result_ ntg_module_uninstall_result;

struct ntg_module_manager_
{
	ntg_list *module_id_list;
	NTG_HASHTABLE *module_id_map;
	NTG_HASHTABLE *origin_id_map;
	NTG_HASHTABLE *core_name_map;

	GUID *legacy_module_id_table;
	int legacy_module_id_table_elems;

    char *implementation_directory_root;
	char *loaded_module_directory_root;

	char *third_party_module_directory;
};


struct ntg_module_install_result_
{
	GUID module_id;
	bool was_previously_embedded;
};


struct ntg_bundle_install_result_
{
	ntg_list *new_module_ids;
	ntg_list *previously_embedded_module_ids;
};


struct ntg_module_uninstall_result_
{
	bool remains_as_embedded;
};






ntg_module_manager *ntg_module_manager_create( const char *scratch_directory_root, const char *system_module_directory, const char *third_party_module_directory );
void ntg_module_manager_free( ntg_module_manager *module_manager );

/* returns ids of new embedded modules */
ntg_list *ntg_module_manager_load_from_integra_file( ntg_module_manager *module_manager, const char *integra_file );

void ntg_module_manager_unload_modules( ntg_module_manager *module_manager, const ntg_list *module_ids );


const ntg_list *ntg_module_id_list( const ntg_module_manager *module_manager );

const ntg_interface *ntg_get_interface_by_module_id( const ntg_module_manager *module_manager, const GUID *id );
const ntg_interface *ntg_get_interface_by_origin_id( const ntg_module_manager *module_manager, const GUID *id );
const ntg_interface *ntg_get_core_interface_by_name( const ntg_module_manager *module_manager, const char *name );

char *ntg_module_manager_get_unique_interface_name( const ntg_interface *interface );
char *ntg_module_manager_get_module_path( const ntg_module_manager *module_manager, const ntg_interface *interface );
char *ntg_module_manager_get_patch_path( const ntg_module_manager *module_manager, const ntg_interface *interface );

ntg_list *ntg_module_manager_get_orphaned_embedded_modules( const ntg_module_manager *module_manager, const ntg_node *root_node );

ntg_error_code ntg_interpret_legacy_module_id( const ntg_module_manager *module_manager, ntg_id old_id, GUID *output );


#ifdef __cplusplus
}
#endif

#endif
