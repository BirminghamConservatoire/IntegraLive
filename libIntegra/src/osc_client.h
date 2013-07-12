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
_resolve * USA.
 */

#ifndef NTG_OSC_CLIENT_PRIVATE_H
#define NTG_OSC_CLIENT_PRIVATE_H

#define NTG_OSC_CLIENT_TIMEOUT 1

#include "lo_ansi.h"
#include "path.h"
#include "value.h"
#include "command.h"
#include "integra/integra.h"


typedef struct ntg_osc_client_ {

    lo_address address;

} ntg_osc_client;



ntg_osc_client *ntg_osc_client_new(const char *url, unsigned short port);
void ntg_osc_client_destroy(ntg_osc_client *client);

ntg_error_code ntg_osc_client_send_new(ntg_osc_client *client,
        ntg_command_source cmd_source,
        const GUID *module_id,
        const char *node_name,
        const ntg_path *path);

ntg_error_code ntg_osc_client_send_load(ntg_osc_client *client,
        ntg_command_source cmd_source,
        const char *file_path,
        const ntg_path *path);

ntg_error_code ntg_osc_client_send_delete(ntg_osc_client *client,
        ntg_command_source cmd_source,
        const ntg_path *path);

ntg_error_code ntg_osc_client_send_set(ntg_osc_client *client,
        ntg_command_source cmd_source,
        const ntg_path *path,
        const ntg_value *value);

ntg_error_code ntg_osc_client_send_move(ntg_osc_client *client,
        ntg_command_source cmd_source,
        const ntg_path *node_path,
        const ntg_path *parent_path);

ntg_error_code ntg_osc_client_send_rename(ntg_osc_client *client,
        ntg_command_source cmd_source,
        const ntg_path *path,
        const char *name);



#endif

