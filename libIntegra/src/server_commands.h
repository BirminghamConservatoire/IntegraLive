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

#ifndef INTEGRA_SERVER_COMMANDS_PRIVATE_H
#define INTEGRA_SERVER_COMMANDS_PRIVATE_H
#include "server.h"
#include "path.h"


/* this is also the order the arguments should be passed */
typedef struct ntg_args_set_ {
    ntg_internal::ntg_command_source source;
    ntg_api::CPath path;
    const ntg_value *value;
} ntg_args_set;


ntg_command_status ntg_set_(ntg_server *server, 
        ntg_internal::ntg_command_source cmd_source,
        const ntg_api::CPath &attribute_path,
        const ntg_value *value);

ntg_command_status ntg_new_(ntg_server *server,
        ntg_internal::ntg_command_source cmd_source,
        const GUID *module_id,
        const char *node_name,
        const ntg_api::CPath &path);

ntg_command_status  ntg_delete_(ntg_server *server,
        ntg_internal::ntg_command_source cmd_source,
        const ntg_api::CPath &path);

ntg_command_status ntg_rename_(ntg_server *server,
        ntg_internal::ntg_command_source cmd_source,
        const ntg_api::CPath &path,
        const char *name);

ntg_command_status ntg_move_(ntg_server *server,
        ntg_internal::ntg_command_source cmd_source,
        const ntg_api::CPath &node_path,
        const ntg_api::CPath &parent_path);

ntg_command_status ntg_load_(ntg_server * server,
        ntg_internal::ntg_command_source cmd_source,
        const char *file_path,
        const ntg_api::CPath &path);

ntg_command_status ntg_unload_orphaned_embedded_modules_( ntg_server *server, ntg_internal::ntg_command_source cmd_source );
ntg_command_status ntg_install_module_( ntg_server *server, ntg_internal::ntg_command_source cmd_source, const char *file_path );
ntg_command_status ntg_install_embedded_module_( ntg_server *server, ntg_internal::ntg_command_source cmd_source, const GUID *module_id );
ntg_command_status ntg_uninstall_module_( ntg_server *server, ntg_internal::ntg_command_source cmd_source, const GUID *module_id );
ntg_command_status ntg_load_module_in_development_( ntg_server *server, ntg_internal::ntg_command_source cmd_source, const char *file_path );


ntg_error_code ntg_nodelist_( ntg_server *server, const ntg_api::CPath &path, ntg_api::path_list &results );


ntg_command_status ntg_save_(ntg_server *server, const ntg_api::CPath &path, const char *file_path );

ntg_value *ntg_get_(ntg_server *server, const ntg_api::CPath &path );


void ntg_print_state_();


#endif
