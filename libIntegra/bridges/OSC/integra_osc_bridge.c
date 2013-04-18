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
#include "windows_build_stuff.h"
#endif

#define inline __inline

#include "lo/lo.h"
void lo_address_set_flags(lo_address t, int flags);


#include "Integra/integra_bridge.h"
#include "Integra/integra_bridge.h"

#include "src/interface.h"
#include "src/attribute.h"
#include "src/node.h"

#include "src/path.h"

#define NTG_OSC_ERROR -1
#define NTG_BRIDGE_LISTEN_PORT "7772"
#define NTG_BRIDGE_SEND_PORT "7773"

/* OSC server thread reference */
lo_server_thread st;

/* module host address */
lo_address module_host;

/* The interface generator array */
INTEGRA_BRIDGE_API ntg_bridge_interface_generator interface_generator[1];

/* ========== Global variables ========== */
static ntg_bridge_interface *bridge_interface = NULL;


/* ========== OSC handlers ========== */
void handler_osc_error(int num, const char *msg, const char *path){

    NTG_TRACE_ERROR_WITH_STRING("liblo server error", msg);
}

ntg_value *new_value_from_lo_typed(const char lo_type, lo_arg *lo_value)
{
    ntg_value *value = NULL;

    switch(lo_type){

        case 'f':
            value = ntg_value_new(NTG_FLOAT, &lo_value->f);
            break;
        case 'i':
			value = ntg_value_new(NTG_INTEGER, &lo_value->i);
            break;
        case 's':
            value = ntg_value_new(NTG_STRING, &lo_value->s);
            break;
        case 'N':
            value = NULL;
            break;
        default:
            NTG_TRACE_ERROR_WITH_INT("unsupported type", lo_type);
            break;

    }
    return value;
}


int handler_bridge_callback(const char *path, const char *types, lo_arg **argv,
        int argc, void *data, void *user_data)
{

    ntg_value *value = NULL;
    int id;
    char *attribute_name = NULL;
    char *dim = NULL;


    id = argv[0]->i;
    attribute_name = &argv[1]->s;
    dim = &argv[2]->s;

    value = new_value_from_lo_typed (types[3], argv[3]);

	if( bridge_interface->server_receive_callback )
	{
	    bridge_interface->server_receive_callback(id, attribute_name, value);
	}
	else
	{
		NTG_TRACE_ERROR( "server_receive_callback not set" );
	}


	if( value )
	{
		ntg_value_free(value);
	}

    return 0;

}


static int osc_module_load(const ntg_id instance_id, const char *implementation_name){

	int res = 0;

    if(!implementation_name){
	    NTG_TRACE_ERROR("implementation_name is NULL");
    }

	NTG_TRACE_PROGRESS_WITH_INT( implementation_name, instance_id );

    /* Load the module */
    res = lo_send(module_host, "/load", "si", implementation_name, instance_id);    
    if(res==-1) {
	    NTG_TRACE_ERROR(lo_address_errstr(module_host));
    }
    return 0;
}

static int osc_module_remove(const ntg_id id){

	NTG_TRACE_PROGRESS_WITH_INT( "", id );

    /* delete the instance */
    lo_send(module_host, "/remove", "i", id);

    return 0;

}


static bool osc_get_stream_connection_name( char *dest, const ntg_endpoint *endpoint, const ntg_interface *interface )
{
	int index = 1;
	const ntg_endpoint *endpoint_iterator;

	assert( dest && endpoint && endpoint->stream_info && interface );

	for( endpoint_iterator = interface->endpoint_list; endpoint_iterator; endpoint_iterator = endpoint_iterator->next )
	{
		if( endpoint_iterator == endpoint )
		{
			break;
		}

		if( !endpoint_iterator->stream_info ) 
		{
			continue;
		}

		if( endpoint_iterator->stream_info->type == endpoint->stream_info->type && endpoint_iterator->stream_info->direction == endpoint->stream_info->direction )
		{
			index ++;
		}
	}

	if( !endpoint_iterator )
	{
		/* endpoint not found! */
		return false;
	}

	switch( endpoint->stream_info->direction )
	{
		case NTG_STREAM_INPUT:
			sprintf( dest, "in%i", index );
			return true;

		case NTG_STREAM_OUTPUT:
			sprintf( dest, "out%i", index );
			return true;

		default:
			return false;
	}
}


static int osc_module_connect(const ntg_node_attribute *source, const ntg_node_attribute *target)
{
	char source_name[ 10 ];
	char target_name[ 10 ];
	assert( source && target );

	if( !osc_get_stream_connection_name( source_name, source->endpoint, source->node->interface ) )
	{
		NTG_TRACE_ERROR( "Failed to get stream connection name" );
		return -1;
	}

	if( !osc_get_stream_connection_name( target_name, target->endpoint, target->node->interface ) )
	{
		NTG_TRACE_ERROR( "Failed to get stream connection name" );
		return -1;
	}

	/* Make the connection */
    lo_send(module_host, "/connect", "isis", source->node->id, source_name, target->node->id, target_name );

    return 0;

}

static int osc_module_disconnect(const ntg_node_attribute *source, const ntg_node_attribute *target)
{
	char source_name[ 10 ];
	char target_name[ 10 ];
	assert( source && target );

	osc_get_stream_connection_name( source_name, source->endpoint, source->node->interface );
	osc_get_stream_connection_name( target_name, target->endpoint, target->node->interface );

	/* remove the connection */
    lo_send(module_host, "/disconnect", "isis", source->node->id, source_name, target->node->id, target_name );

	return 0;
}


static void osc_send_value(const ntg_node_attribute *attribute)
{
    int module_id;
    const char *attribute_name;
	const ntg_value *value;

	assert( attribute );

	module_id = attribute->node->id;
	attribute_name = attribute->endpoint->name;
	value = attribute->value;

	if( value && value->type == NTG_STRING )
	{
		NTG_TRACE_PROGRESS_WITH_STRING( attribute->path->string, value->ctype.s );
	}

	if( value )
	{
		switch( ntg_value_get_type(value) )
		{
			case NTG_FLOAT:
				lo_send(module_host, "/send", "isf", module_id, attribute_name,
						ntg_value_get_float(value));
				break;
			case NTG_INTEGER:
				lo_send(module_host, "/send", "isi", module_id, attribute_name,
						ntg_value_get_int(value));
				break;
			case NTG_STRING:
				lo_send(module_host, "/send", "iss", module_id, attribute_name,
						ntg_value_get_string(value));
				break;
			default:
				NTG_TRACE_ERROR("invalid type");
				break;
		}
	}
	else
	{
		lo_send(module_host, "/send", "iss", module_id, attribute_name, "bang");
	}
}

static void osc_host_dsp(int status) 
{
    lo_send(module_host, "/dsp", "i", status);
}

void osc_bridge_init(void) 
{
    /* print something */
    NTG_TRACE_PROGRESS("Integra OSC bridge init" );
}


const ntg_bridge_interface *ntg_bridge_interface_new(void)
{

    return bridge_interface;

}




void startupBridge()
{
    bridge_interface =
        (ntg_bridge_interface *)malloc(sizeof(ntg_bridge_interface));

    if(bridge_interface != NULL)
	{
        bridge_interface->module_load = osc_module_load;
        bridge_interface->module_remove = osc_module_remove;
        bridge_interface->module_connect = osc_module_connect;
        bridge_interface->module_disconnect = osc_module_disconnect;
        bridge_interface->send_value = osc_send_value;
        bridge_interface->host_dsp = osc_host_dsp;
        bridge_interface->bridge_init = osc_bridge_init;
        bridge_interface->bridge_callback = NULL;
		bridge_interface->server_receive_callback = NULL;

        *interface_generator = ntg_bridge_interface_new;
    }
    else
	{
        *interface_generator = NULL;
    }

    /* start OSC server to listen for replies */
    st = lo_server_thread_new(NTG_BRIDGE_LISTEN_PORT, handler_osc_error);

    /* create OSC destination */
    //module_host = lo_address_new(NULL, NTG_BRIDGE_SEND_PORT);
    module_host = lo_address_new_with_proto(LO_TCP, "localhost",
            NTG_BRIDGE_SEND_PORT);
    if(module_host==NULL) {
        abort();
    }

    lo_address_set_flags(module_host, LO_SLIP);

    /* add method to handle replies from the module host */
    lo_server_thread_add_method(st, "/integra", NULL, handler_bridge_callback,
            NULL);

    /* start the listening server */
    lo_server_thread_start(st);
}


void shutdownBridge()
{
    if(bridge_interface)
        free(bridge_interface);

    lo_server_thread_free(st);
}



#ifdef __GNUC__
__attribute__((constructor)) static void my_init(void)
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
__attribute__((destructor)) static void my_fini(void)
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



