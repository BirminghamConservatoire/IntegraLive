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

#include "lo/lo.h"

#include "api/error.h"
#include "api/command_source.h"
#include "api/common_typedefs.h"


namespace integra_api
{
	class CPath;
	class CValue;
}



typedef struct ntg_osc_client_ {

    lo_address address;

} ntg_osc_client;

using namespace integra_api;


ntg_osc_client *ntg_osc_client_new( const integra_api::string &url, unsigned short port );
void ntg_osc_client_destroy(ntg_osc_client *client);

integra_api::CError ntg_osc_client_send_new(ntg_osc_client *client,
        CCommandSource cmd_source,
        const GUID *module_id,
        const char *node_name,
        const integra_api::CPath &path);

integra_api::CError ntg_osc_client_send_load(ntg_osc_client *client,
        CCommandSource cmd_source,
        const char *file_path,
        const integra_api::CPath &path);

integra_api::CError ntg_osc_client_send_delete(ntg_osc_client *client,
        CCommandSource cmd_source,
        const integra_api::CPath &path);

integra_api::CError ntg_osc_client_send_set(ntg_osc_client *client,
        CCommandSource cmd_source,
        const integra_api::CPath &path,
        const integra_api::CValue *value);

integra_api::CError ntg_osc_client_send_move(ntg_osc_client *client,
        CCommandSource cmd_source,
        const integra_api::CPath &node_path,
        const integra_api::CPath &parent_path);

integra_api::CError ntg_osc_client_send_rename(ntg_osc_client *client,
        CCommandSource cmd_source,
        const integra_api::CPath &path,
        const char *name);


bool ntg_should_send_to_client( CCommandSource cmd_source );



#endif

