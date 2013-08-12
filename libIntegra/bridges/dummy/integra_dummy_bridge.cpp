/* libIntegra multimedia module definition interface
 * 
 * Copyright (C) 2007 Jamie Bullock, Henrik Frisk
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#ifdef _WINDOWS
#include "windows.h"
#endif

#include "Integra/integra_bridge.h"


#define INTEGRA_DUMMY_BRIDGE_VERSION "0.3"

/* The interface generator array */
INTEGRA_BRIDGE_API ntg_bridge_interface_generator interface_generator[1];


/* ========== Global variables ========== */
static ntg_bridge_interface *bridge_interface = NULL;


static int dummy_module_load(const integra_internal::internal_id instance_id, const char *implementation_name){

    fprintf(stderr, "%s(): instance_id = %d, implementation_name = %s\n",
            __FUNCTION__, (int)instance_id, implementation_name);

    return 0;
}

static int dummy_module_remove(const integra_internal::internal_id id){

    fprintf(stderr, "%s(): id = %d\n", __FUNCTION__, (int)id);

    return 0;

}

static int dummy_module_connect(const integra_internal::CNodeEndpoint *source, const integra_internal::CNodeEndpoint *target)
{
    fprintf(stderr, "%s()\n", __FUNCTION__);

    return 0;

}

static int dummy_module_disconnect(const integra_internal::CNodeEndpoint *source, const integra_internal::CNodeEndpoint *target)
{
    fprintf(stderr, "%s()\n", __FUNCTION__);

    return 0;

}

static void dummy_send_value(const integra_internal::CNodeEndpoint *target)
{

    fprintf(stderr, "%s()\n", __FUNCTION__);

}

void dummy_bridge_init(void) {

    fprintf(stderr, "%s()\n", __FUNCTION__);

}

void dummy_bridge_callback(int argc, void *argv){

    fprintf(stderr, "%s()\n", __FUNCTION__);

}

const ntg_bridge_interface *ntg_bridge_interface_new(void)
{

    fprintf(stderr, "%s()\n", __FUNCTION__);
    return bridge_interface;

}


void startupBridge()
{
    bridge_interface =
        (ntg_bridge_interface *)malloc(sizeof(ntg_bridge_interface));

    if(bridge_interface != NULL)
	{
        bridge_interface->module_load = dummy_module_load;
        bridge_interface->module_remove = dummy_module_remove;
        bridge_interface->module_connect = dummy_module_connect;
        bridge_interface->module_disconnect = dummy_module_disconnect;
        bridge_interface->send_value = dummy_send_value;
        bridge_interface->bridge_init = dummy_bridge_init;
        bridge_interface->bridge_callback = dummy_bridge_callback;

        *interface_generator = ntg_bridge_interface_new;
    }
    else
	{
        *interface_generator = NULL;
	}
}


void shutdownBridge()
{
    if(bridge_interface)
        free(bridge_interface);
}



#ifdef __GNUC__
void __attribute__((constructor)) my_init(void)
{
	startupBridge();
}
#else
#ifdef _WINDOWS
BOOL WINAPI DllMain( HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved )
{
	switch( fdwReason )
	{
		case DLL_PROCESS_ATTACH:
			startupBridge();
			break;

		case DLL_PROCESS_DETACH:
			shutdownBridge();
			break;

		default:
			break;
	}

	return TRUE;
}
#else
void _init()
{
	startupBridge();
}
#endif
#endif


#ifdef __GNUC__
void __attribute__((destructor)) my_fini(void)
{
	shutdownBridge();
}
#else
#ifndef _WINDOWS
void _fini()
{
	shutdownBridge();
}
#endif
#endif
