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

extern "C"
{
void lo_address_set_flags(lo_address t, int flags);
}


#include "Integra/integra_bridge.h"

#include "src/interface_definition.h"
#include "src/node.h"
#include "src/path.h"
#include "src/trace.h"
#include "src/value.h"

using namespace integra_api;
using namespace integra_internal;

#define NTG_OSC_ERROR -1
#define NTG_BRIDGE_LISTEN_PORT "7772"
#define NTG_BRIDGE_SEND_PORT "7773"

/* OSC server thread reference */
lo_server_thread st;

/* module host address */
lo_address module_host;

/* The interface generator array */
extern "C"
{
INTEGRA_BRIDGE_API ntg_bridge_interface_generator interface_generator[1];
}

/* ========== Global variables ========== */
static ntg_bridge_interface *bridge_interface = NULL;


/* ========== OSC handlers ========== */
void handler_osc_error(int num, const char *msg, const char *path){

    NTG_TRACE_ERROR << "liblo server error" << msg;
}

CValue *new_value_from_lo_typed(const char lo_type, lo_arg *lo_value)
{
    switch(lo_type){

        case 'f':
            return new CFloatValue( lo_value->f );

        case 'i':
            return new CIntegerValue( lo_value->i );

		case 's':
            return new CStringValue( &lo_value->s );

		case 'N':
            return NULL;

		default:
            NTG_TRACE_ERROR <<"unsupported type: " << lo_type;
			return NULL;
    }
}


int handler_bridge_callback(const char *path, const char *types, lo_arg **argv,
        int argc, void *data, void *user_data)
{
    int id;
    char *attribute_name = NULL;
    char *dim = NULL;


    id = argv[0]->i;
    attribute_name = &argv[1]->s;
    dim = &argv[2]->s;

    CValue *value = new_value_from_lo_typed (types[3], argv[3]);

	if( bridge_interface->server_receive_callback )
	{
		bridge_interface->server_receive_callback( id, attribute_name, value, bridge_interface->server_receive_callback_context );
	}
	else
	{
		NTG_TRACE_ERROR << "server_receive_callback not set";
	}

	if( value )
	{
		delete value;
	}

    return 0;

}


static int osc_module_load( const internal_id instance_id, const char *implementation_name )
{

	int res = 0;

    if(!implementation_name){
	    NTG_TRACE_ERROR << "implementation_name is NULL";
    }

    /* Load the module */
    res = lo_send(module_host, "/load", "si", implementation_name, instance_id);    
    if(res==-1) {
	    NTG_TRACE_ERROR << lo_address_errstr( module_host );
    }
    return 0;
}

static int osc_module_remove(const internal_id id)
{

    /* delete the instance */
    lo_send(module_host, "/remove", "i", id);

    return 0;

}


static bool osc_get_stream_connection_name( char *dest, const CEndpointDefinition &endpoint_definition, const CInterfaceDefinition &interface_definition )
{
	bool found( false );
	int index = 1;

	assert( dest && endpoint_definition.is_audio_stream() );

	endpoint_definition_list endpoint_definitions = interface_definition.get_endpoint_definitions();
	for( endpoint_definition_list::const_iterator i = endpoint_definitions.begin(); i != endpoint_definitions.end(); i++ )
	{
		const CEndpointDefinition *prior_endpoint = *i;
		
		if( prior_endpoint == &endpoint_definition )
		{
			found = true;
			break;
		}

		if( prior_endpoint->is_audio_stream() ) 
		{
			continue;
		}

		const CStreamInfo *prior_stream = prior_endpoint->get_stream_info();
		const CStreamInfo *my_stream = endpoint_definition.get_stream_info();

		if( prior_stream->get_type() == my_stream->get_type() && prior_stream->get_direction() == my_stream->get_direction() )
		{
			index ++;
		}
	}

	if( !found )
	{
		/* endpoint not found! */
		return false;
	}

	switch( endpoint_definition.get_stream_info()->get_direction() )
	{
		case CStreamInfo::INPUT:
			sprintf( dest, "in%i", index );
			return true;

		case CStreamInfo::OUTPUT:
			sprintf( dest, "out%i", index );
			return true;

		default:
			return false;
	}
}


static int osc_module_connect( const CNodeEndpoint *source, const CNodeEndpoint *target )
{
	char source_name[ 10 ];
	char target_name[ 10 ];
	assert( source && target );

	if( !osc_get_stream_connection_name( source_name, source->get_endpoint_definition(), source->get_node().get_interface_definition() ) )
	{
		NTG_TRACE_ERROR << "Failed to get stream connection name";
		return -1;
	}

	if( !osc_get_stream_connection_name( target_name, target->get_endpoint_definition(), target->get_node().get_interface_definition() ) )
	{
		NTG_TRACE_ERROR << "Failed to get stream connection name";
		return -1;
	}

	/* Make the connection */
    lo_send(module_host, "/connect", "isis", source->get_node().get_id(), source_name, target->get_node().get_id(), target_name );

    return 0;

}

static int osc_module_disconnect(const CNodeEndpoint *source, const CNodeEndpoint *target)
{
	char source_name[ 10 ];
	char target_name[ 10 ];
	assert( source && target );

	osc_get_stream_connection_name( source_name, source->get_endpoint_definition(), source->get_node().get_interface_definition() );
	osc_get_stream_connection_name( target_name, target->get_endpoint_definition(), target->get_node().get_interface_definition() );

	/* remove the connection */
    lo_send(module_host, "/disconnect", "isis", source->get_node().get_id(), source_name, target->get_node().get_id(), target_name );

	return 0;
}


static void osc_send_value( const CNodeEndpoint *node_endpoint )
{
	assert( node_endpoint );

	int module_id = node_endpoint->get_node().get_id();
	const string &endpoint_name = node_endpoint->get_endpoint_definition().get_name();
	const CValue *value = node_endpoint->get_value();

	if( value )
	{
		switch( value->get_type() )
		{
			case CValue::FLOAT:
				lo_send(module_host, "/send", "isf", module_id, endpoint_name.c_str(), ( float ) *value );
				break;

			case CValue::INTEGER:
				lo_send(module_host, "/send", "isi", module_id, endpoint_name.c_str(), ( int ) *value );
				break;

			case CValue::STRING:
				lo_send(module_host, "/send", "iss", module_id, endpoint_name.c_str(), ( ( const string & ) *value ).c_str() );
				break;

			default:
				NTG_TRACE_ERROR << "invalid type";
				break;
		}
	}
	else
	{
		lo_send( module_host, "/send", "iss", module_id, endpoint_name.c_str(), "bang" );
	}
}

static void osc_host_dsp(int status) 
{
    lo_send(module_host, "/dsp", "i", status);
}

void osc_bridge_init(void) 
{
    /* print something */
    NTG_TRACE_PROGRESS << "Integra OSC bridge init";
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



