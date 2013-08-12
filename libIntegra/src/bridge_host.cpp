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

#include <stdlib.h>

extern "C" 
{
#include <dlfcn.h>
}

#include <assert.h>

#include "Integra/integra_bridge.h"

#include "bridge_host.h"
#include "trace.h"


void *ntg_bridge_load(const char *so_name)
{
    ntg_bridge_interface *bridge_interface = NULL;

    ntg_bridge_interface_generator *interface_generator = NULL;

    NTG_TRACE_PROGRESS << "Trying to load bridge: " << so_name;

    void *handle = dlopen( so_name, RTLD_NOW | RTLD_LOCAL );

    if (handle != NULL) 
	{
        NTG_TRACE_PROGRESS << "bridge loaded";
    } 
	else 
	{
        NTG_TRACE_ERROR << "bridge not loaded";
        assert( false );
    }

    interface_generator = (ntg_bridge_interface_generator *) dlsym( handle, "interface_generator" );

    char *error = dlerror();

    if (error != NULL) {
        NTG_TRACE_ERROR << "dlerror" << error;
    }

    if (interface_generator != NULL) {
        NTG_TRACE_PROGRESS << "Got interface generator, trying to load interface...";
        if (*interface_generator != NULL) {
            bridge_interface =
                (ntg_bridge_interface *) interface_generator[0] ();
        } else {
            NTG_TRACE_ERROR << "interface generator function is NULL";
            assert(false);
        }
    } else {
        NTG_TRACE_ERROR << "interface generator is NULL";
        assert(false);
    }

    if (bridge_interface != NULL) {
        NTG_TRACE_PROGRESS << "...interface function loaded";
    } else {
        NTG_TRACE_ERROR << "bridge interface not loaded";
        assert(false);
    }

    return bridge_interface;
}
