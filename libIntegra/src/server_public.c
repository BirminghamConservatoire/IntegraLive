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

#include "command.h"
#include "server.h"
#include "server_commands.h"
#include "globals.h"
#include "signals.h"
#include "module_manager.h"

ntg_command_status ntg_new(const GUID *module_id,
        const char *node_name, const ntg_path * path)
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_new_(server_, NTG_SOURCE_C_API, module_id, node_name, path);
    ntg_unlock_server();

    return status;
}

ntg_command_status ntg_delete(const ntg_path * path)
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


ntg_command_status ntg_install_bundle( const char *file_path )
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_install_bundle_( server_, NTG_SOURCE_C_API, file_path );
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


ntg_command_status ntg_rename(const ntg_path * path,
        const char *name)
{
    
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_rename_(server_, NTG_SOURCE_C_API, path, name);
    ntg_unlock_server();

    return status;
}


/* FIX: refactor to have one return path */
ntg_command_status ntg_save(const ntg_path * path, const char *file_path) 
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_save_(server_,  path, file_path);
    ntg_unlock_server();

    return status;
}


ntg_command_status ntg_load(const char *file_path,
        const ntg_path * path)
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_load_(server_, NTG_SOURCE_C_API, file_path, path);
    ntg_unlock_server();

    return status;
}

ntg_command_status ntg_move(
        const ntg_path * node_path,
        const ntg_path * parent_path)
{
    ntg_command_status status;

    ntg_lock_server();
    status = ntg_move_(server_, NTG_SOURCE_C_API, node_path, parent_path);
    ntg_unlock_server();

    return status;
}

ntg_command_status ntg_set(
        const ntg_path *path, 
        const ntg_value *value)
{
    ntg_command_status status;
    
    ntg_lock_server();

    status = ntg_set_(server_, NTG_SOURCE_C_API, path, value);

    ntg_unlock_server();

    return status;
}


const ntg_value *ntg_get(const ntg_path *path)
{
    const ntg_value *value;

    ntg_lock_server();
    value = ntg_get_(server_, path);
    ntg_unlock_server();

    return value;
}


const ntg_list *ntg_interfacelist(void)
{
	/* no need to lock, as the set of interfaces does not change at runtime */
	/* NOTE - this assumption will become invalid once we load modules from .integra files! */

	return ntg_module_id_list( server_->module_manager );
}

const ntg_list *ntg_nodelist(const ntg_path * path)
{

    ntg_list *list     = NULL;

    ntg_lock_server();
    list = ntg_nodelist_(server_, path);
    ntg_unlock_server();

    return list;
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
