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

#include "platform_specifics.h"

#include "server.h"
#include "server_commands.h"
#include "globals.h"
#include "signals.h"
#include "module_manager.h"

using namespace ntg_api;
using namespace ntg_internal;


command_status ntg_new( const GUID *module_id, string node_name, const CPath &path )
{
    command_status status;

    server_->lock();
    status = ntg_new_( *server_, NTG_SOURCE_C_API, module_id, node_name, path );
    server_->unlock();

    return status;
}

command_status ntg_delete( const CPath &path )
{
    command_status status;

    server_->lock();
    status = ntg_delete_( *server_, NTG_SOURCE_C_API, path );
    server_->unlock();

    return status;

}


command_status ntg_unload_orphaned_embedded_modules(void)
{
    command_status status;

    server_->lock();
    status = ntg_unload_orphaned_embedded_modules_( *server_, NTG_SOURCE_C_API );
    server_->unlock();

    return status;
}


command_status ntg_install_module( const char *file_path )
{
    command_status status;

    server_->lock();
    status = ntg_install_module_( *server_, NTG_SOURCE_C_API, file_path );
    server_->unlock();

    return status;
}


command_status ntg_install_embedded_module( const GUID *module_id )
{
    command_status status;

    server_->lock();
    status = ntg_install_embedded_module_( *server_, NTG_SOURCE_C_API, module_id );
    server_->unlock();

    return status;
}


command_status ntg_uninstall_module( const GUID *module_id )
{
    command_status status;

    server_->lock();
    status = ntg_uninstall_module_( *server_, NTG_SOURCE_C_API, module_id );
    server_->unlock();

    return status;
}


command_status ntg_load_module_in_development( const char *file_path )
{
    command_status status;

    server_->lock();
    status = ntg_load_module_in_development_( *server_, NTG_SOURCE_C_API, file_path );
    server_->unlock();

    return status;
}



command_status ntg_rename( const CPath &path, const char *name)
{
    command_status status;

    server_->lock();
    status = ntg_rename_( *server_, NTG_SOURCE_C_API, path, name );
    server_->unlock();

    return status;
}


command_status ntg_save( const CPath &path, const char *file_path ) 
{
    command_status status;

    server_->lock();
    status = ntg_save_( *server_, path, file_path );
    server_->unlock();

    return status;
}


command_status ntg_load(const char *file_path, const CPath &path )
{
    command_status status;

    server_->lock();
    status = ntg_load_( *server_, NTG_SOURCE_C_API, file_path, path );
    server_->unlock();

    return status;
}

command_status ntg_move( const CPath &node_path, const CPath &parent_path )
{
    command_status status;

    server_->lock();
    status = ntg_move_( *server_, NTG_SOURCE_C_API, node_path, parent_path );
    server_->unlock();

    return status;
}

command_status ntg_set( const CPath &path, const CValue *value )
{
    command_status status;
    
    server_->lock();

    status = ntg_set_( *server_, NTG_SOURCE_C_API, path, value );

    server_->unlock();

    return status;
}


CValue *ntg_get( const CPath &path )
{
    server_->lock();

    const CValue *value = ntg_get_( *server_, path );

	CValue *copy = value ? value->clone() : NULL;

    server_->unlock();

	return copy;
}


const guid_set &ntg_interfacelist(void)
{
	/* no need to lock, as the set of interfaces does not change at runtime */
	/* NOTE - this assumption will become invalid once we load modules from .integra files! */

	return server_->get_module_manager().get_all_module_ids();
}


error_code ntg_nodelist( const ntg_api::CPath &path, ntg_api::path_list &results )
{
    server_->lock();
    error_code result = ntg_nodelist_( *server_, path, results );
    server_->unlock();

    return result;
}


void ntg_print_state(void){
    server_->lock();
	ntg_print_state_();
    server_->unlock();
}
