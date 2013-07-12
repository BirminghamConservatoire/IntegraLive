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

#include <string.h>
#include "platform_specifics.h"

#ifdef HAVE_CONFIG_H
#    include <config.h>
#endif

#include "lo_ansi.h"

#include "helper.h"
#include "globals.h"
#include "memory.h"
#include "attribute.h"
#include "server.h"
#include "value.h"

#include <algorithm>


ntg_value *get_value_from_osc(char osc_type, lo_arg *arg);

void osc_receive(const char *address, const ntg_value *value)
{
	/* 
	TODO - this is not thread-safe!  
	We should not lock the server at all here, we should feed commands onto input queue asynchronously!
	*/

    const ntg_node_attribute *attribute = NULL;

    ntg_lock_server();

    /* copy the address without the leading "/" */
	string path( &address[ 1 ] );

	/* replace dashes with dots */
	std::replace( path.begin(), path.end(), '/', '.' );

    ntg_unlock_server();

	map_string_to_attribute::const_iterator lookup = server_->state_table.find( path );
	if( lookup == server_->state_table.end() )
	{
        NTG_TRACE_ERROR_WITH_STRING("received set request for invalid path", address);
        return;		
	}

	ntg_server_receive_( server_, NTG_SOURCE_OSC_API, lookup->second, value );
}


int handler_namespace_method(const char *address, const char *types,
                             lo_arg ** argv, int argc, void *data,
                             void *user_data)
{

    return NTG_NO_ERROR;

    /* This function is the entry point for handling OSC requests.
     * It is called back when OSC messages are received via UDP
     * The current method of handling OSC messages enpoint-derived namespace 
     * (e.g. /Project/Track1/Block1/TapDelay1/delayTime) is now deprecated
     * and will be replaced by a mechanism that allows explicit setting of OSC
     * addresses per-endpoint, by the user.
     *
     * This code has been left in place temporarily to aid the development of 
     * this new functionality, but can eventually be removed 
     *
     * -jb 17/10/12
     */
#if 0

    ntg_value *value = NULL;

    switch (argc) 
	{
        case 0:
            /* if we don't get a value, we assume it's a BANG control, and pass NULL for value */
            value = NULL;
            break;
        case 1:
            value = get_value_from_osc(types[0], argv[0]);
            break;
        default:
            /* if we get multiple values ignore the request */
            NTG_TRACE_ERROR("multiple values unsupported");
			return NTG_ERROR;
    }

    osc_receive(address, value);

	if( value )
	{
		ntg_value_free(value);
	}

    return NTG_NO_ERROR;
#endif
}

ntg_value *get_value_from_osc(char osc_type, lo_arg *arg)
{
    switch (osc_type) {
        case LO_FLOAT:
            return ntg_value_new(NTG_FLOAT, &arg->f);

        case LO_INT32:
            return ntg_value_new(NTG_INTEGER, &arg->i);

        case LO_STRING:
            return ntg_value_new(NTG_STRING, &arg->s);

        default:
            NTG_TRACE_ERROR("unsupported type");
            return NULL;

    }
}


void ntg_osc_error(int num, const char *msg, const char *path)
{
	int trace_length;
	char *trace;
	const char *format="liblo server error %d in path %s: %s";

	trace_length = strlen(msg) + strlen(path) + strlen(format);
	trace = new char[ trace_length ];
	snprintf( trace, trace_length, format, num, path, msg );

    NTG_TRACE_ERROR(trace);
	delete trace;
}
