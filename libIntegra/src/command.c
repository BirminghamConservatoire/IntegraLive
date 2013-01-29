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

#include <assert.h>

#include "memory.h"
#include "server.h"
#include "helper.h"
#include "server_commands.h"

ntg_command *ntg_command_new(ntg_command_id command_id, unsigned int argc,
        va_list argv)
{
	ntg_value *value;
    ntg_args_set *args_set;

    ntg_command *command = ntg_malloc(sizeof(ntg_command));

    command->argc      = argc;
    command->command_id  = command_id;

	switch( command_id )
	{
		case NTG_SET:
			assert(argc == 3);
			args_set = ntg_malloc(sizeof(ntg_args_set));

			args_set->source = va_arg(argv, ntg_command_source);
			args_set->path   = ntg_path_copy(va_arg(argv, ntg_path *));

			value = va_arg(argv, ntg_value *);
			if( value )
			{
				args_set->value = ntg_value_duplicate( value );
			}
			else
			{
				args_set->value = NULL;
			}
			command->argv = args_set;
			break;

		default:
			NTG_TRACE_ERROR_WITH_INT("unrecognised server command id", command_id);
			assert(false);
			break;
	}

    return command;
}


void ntg_command_free(ntg_command *command)
{
    ntg_command_id command_id = command->command_id;

    if(command_id == NTG_SET){
        ntg_args_set *args = (ntg_args_set *)command->argv;

        ntg_path_free((ntg_path *)args->path);
        ntg_value_free((ntg_value*)args->value);

    }
    ntg_free(command);
}


