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


#ifndef NTG_COMMAND_PRIVATE_H
#define NTG_COMMAND_PRIVATE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdarg.h>

typedef enum ntg_command_source_ {
    NTG_SOURCE_NONE = -1,
    NTG_SOURCE_INITIALIZATION,
    NTG_SOURCE_LOAD,
    NTG_SOURCE_SYSTEM,
    NTG_SOURCE_CONNECTION,
    NTG_SOURCE_HOST,
    NTG_SOURCE_SCRIPT,
    NTG_SOURCE_XMLRPC_API,
    NTG_SOURCE_OSC_API,
    NTG_SOURCE_C_API,
    NTG_COMMAND_SOURCE_end
} ntg_command_source;

typedef enum ntg_command_id_ {
    NTG_COMMAND_ID_begin = -1,
    NTG_SET,
    NTG_COMMAND_ID_end
} ntg_command_id;

typedef struct ntg_command_ {
    ntg_command_id command_id;
    unsigned int argc;
    void *argv;
} ntg_command;

ntg_command *ntg_command_new(ntg_command_id command_id, unsigned int argc,
        va_list argv);
void ntg_command_free(ntg_command *command);

#ifdef __cplusplus
}
#endif

#endif

