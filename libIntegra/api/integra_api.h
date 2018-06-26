/* libIntegra modular audio framework
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

/** \file integra_api.h
 *  \brief Master include file for entire libIntegra API
 */


#ifndef INTEGRA_API_PRIVATE_H
#define INTEGRA_API_PRIVATE_H

#include "common_typedefs.h"

#include "command_result.h"
#include "command_source.h"
#include "command.h"

#include "error.h"
#include "trace.h"
#include "value.h"

#include "guid_helper.h"
#include "string_helper.h"

#include "interface_definition.h"
#include "module_manager.h"
#include "node_endpoint.h"
#include "node.h"

#include "server_startup_info.h"
#include "server.h"
#include "server_lock.h"
#include "integra_session.h"
#include "notification_sink.h"
#include "polling_notification_sink.h"

using namespace integra_api;

#endif
