/** libIntegra multimedia module interface
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

#ifdef HAVE_CONFIG_H
#    include <config.h>
#endif

#include "platform_specifics.h"

#include "server.h"
#include "server_commands.h"
#include "globals.h"
#include "signals.h"
#include "module_manager.h"

using namespace ntg_api;
using namespace ntg_internal;


ntg_command_status ntg_new( const GUID *module_id, const char *node_name, const CPath &path )
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_new_(server_, NTG_SOURCE_C_API, module_id, node_name, path );
    ntg_unlock_server();

    return status;
}

ntg_command_status ntg_delete( const CPath &path )
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_delete_(server_, NTG_SOURCE_C_API, path);
    ntg_unlock_server();

    return status;

}


ntg_command_status ntg_unload_orphaned_embedded_modules(void)
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_unload_orphaned_embedded_modules_(server_, NTG_SOURCE_C_API);
    ntg_unlock_server();

    return status;
}


ntg_command_status ntg_install_module( const char *file_path )
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_install_module_( server_, NTG_SOURCE_C_API, file_path );
    ntg_unlock_server();

    return status;
}


ntg_command_status ntg_install_embedded_module( const GUID *module_id )
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_install_embedded_module_( server_, NTG_SOURCE_C_API, module_id );
    ntg_unlock_server();

    return status;
}


ntg_command_status ntg_uninstall_module( const GUID *module_id )
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_uninstall_module_( server_, NTG_SOURCE_C_API, module_id );
    ntg_unlock_server();

    return status;
}


ntg_command_status ntg_load_module_in_development( const char *file_path )
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_load_module_in_development_( server_, NTG_SOURCE_C_API, file_path );
    ntg_unlock_server();

    return status;
}



ntg_command_status ntg_rename( const CPath &path, const char *name)
{
    
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_rename_(server_, NTG_SOURCE_C_API, path, name);
    ntg_unlock_server();

    return status;
}


ntg_command_status ntg_save( const CPath &path, const char *file_path ) 
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_save_(server_,  path, file_path);
    ntg_unlock_server();

    return status;
}


ntg_command_status ntg_load(const char *file_path, const CPath &path )
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_load_(server_, NTG_SOURCE_C_API, file_path, path);
    ntg_unlock_server();

    return status;
}

ntg_command_status ntg_move( const CPath &node_path, const CPath &parent_path )
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_move_(server_, NTG_SOURCE_C_API, node_path, parent_path );
    ntg_unlock_server();

    return status;
}

ntg_command_status ntg_set( const CPath &path, const ntg_value *value )
{
    ntg_command_status status;
    
    ntg_lock_server();

    status = ntg_set_(server_, NTG_SOURCE_C_API, path, value);

    ntg_unlock_server();

    return status;
}


const ntg_value *ntg_get( const CPath &path )
{
    const ntg_value *value;

    ntg_lock_server();
    value = ntg_get_( server_, path );
    ntg_unlock_server();

    return value;
}


const guid_set &ntg_interfacelist(void)
{
	/* no need to lock, as the set of interfaces does not change at runtime */
	/* NOTE - this assumption will become invalid once we load modules from .integra files! */

	return ntg_module_id_set( server_->module_manager );
}


ntg_error_code ntg_nodelist( const ntg_api::CPath &path, ntg_api::path_list &results )
{
    ntg_lock_server();
    ntg_error_code result = ntg_nodelist_( server_, path, results );
    ntg_unlock_server();

    return result;
}

void ntg_terminate(void)
{
    /* 
     * we don't lock the server here because ntg_server_halt() handles locking
     */
    ntg_server_halt(server_);
}

void ntg_print_state(void){
    ntg_lock_server();
	ntg_print_state_();
    ntg_unlock_server();
}
