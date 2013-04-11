/* libIntegra multimedia module interface
 *  
 * Copyright (C) 2012 Birmingham City University
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

#ifndef INTEGRA_SYSTEM_CLASS_HANDLERS_H
#define INTEGRA_SYSTEM_CLASS_HANDLERS_H

#include "server.h"
#include "command.h"


#ifdef __cplusplus
extern "C" {
#endif


struct ntg_system_class_data_ 
{
	struct ntg_system_class_handler_ *new_handlers;
	struct ntg_system_class_handler_ *set_handlers;
	struct ntg_system_class_handler_ *rename_handlers;
	struct ntg_system_class_handler_ *move_handlers;
	struct ntg_system_class_handler_ *delete_handlers;

	struct ntg_player_data_ *player_data;

	struct ntg_reentrance_checker_state_ *reentrance_checker_state;

	GUID connection_interface_guid;
};


void ntg_system_class_handlers_initialize(ntg_server *server);
void ntg_system_class_handlers_shutdown(ntg_server *server);

void ntg_system_class_handle_new(ntg_server *server, const ntg_node *node, ntg_command_source cmd_source );
void ntg_system_class_handle_set(ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source );
void ntg_system_class_handle_rename(ntg_server *server, const ntg_node *node, const char *previous_name, ntg_command_source cmd_source );
void ntg_system_class_handle_move(ntg_server *server, const ntg_node *node, const ntg_path *previous_path, ntg_command_source cmd_source );
void ntg_system_class_handle_delete(ntg_server *server, const ntg_node *node, ntg_command_source cmd_source );

bool ntg_node_is_active( const ntg_node *node );
bool ntg_node_has_data_directory( const ntg_node *node );
const char *ntg_node_get_data_directory( const ntg_node *node );

bool ntg_should_copy_input_file( ntg_command_source cmd_source );


#ifdef __cplusplus
}
#endif

#endif /*INTEGRA_SYSTEM_CLASS_HANDLERS_H*/
