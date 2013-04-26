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

#ifdef HAVE_CONFIG_H
#    include <config.h>
#endif


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>

#include <pthread.h>
#include <semaphore.h>
#include <dlfcn.h>

#include <sys/stat.h>

#include <libxml/encoding.h>
#include <libxml/xmlwriter.h>
#include <libxml/xmlreader.h>

/* integra public headers */

/* integra private headers */
#include "lua.h"
#include "xmlrpc_server.h"
#include "helper.h"
#include "memory.h"
#include "globals.h"
#include "luascripting.h"
#include "value.h"
#include "validate.h"
#include "server.h"
#include "command.h"
#include "node.h"
#include "attribute.h"
#include "queue.h"
#include "bridge_host.h"
#include "signals.h"
#include "osc.h"
#include "server_commands.h"
#include "list.h"
#include "system_class_handlers.h"
#include "module_manager.h"
#include "data_directory.h"
#include "scratch_directory.h"
#include "player_handler.h"
#include "osc_client.h"
#include "interface.h"

#ifdef _WINDOWS
	#ifdef interface 
		#undef interface
	#endif
#endif

#define NTG_SERVER_WAIT_TIME 1000000 * 20 /* == 20 ms */
#define NTG_DEQUEUE_WAIT_TIME 0


static pthread_mutex_t queue_mutex  = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t server_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  server_cond  = PTHREAD_COND_INITIALIZER;

void ntg_lock_server(void)
{
    pthread_mutex_lock(&server_mutex);
}

void ntg_unlock_server(void)
{
    pthread_mutex_unlock(&server_mutex);
}


const ntg_node_attribute *ntg_server_resolve_relative_path( 
        const ntg_server *server,
		const ntg_node *root,
        const char *path)
{
	char *composite_path = NULL;
	const ntg_node_attribute *attribute = NULL;

	composite_path = ntg_malloc( strlen( root->path->string ) + strlen( path ) + 2 );
	sprintf( composite_path, "%s.%s", root->path->string, path );

    attribute = ntg_hashtable_lookup_string( server->state_table, composite_path );

	ntg_free( composite_path );

	return attribute;
}


void ntg_server_set_host_dsp(const ntg_server *server, bool status)
{

    if(server->bridge != NULL) {
        server->bridge->host_dsp(status);
    }

}


ntg_path *ntg_server_path_from_id(ntg_server * server, ntg_id id)
{

    ntg_node *root, *found;
    ntg_path *path;

    root = ntg_server_get_root(server);
    found = ntg_node_find_by_id_r(root, id);

    if (!found) {
        return NULL;
    }

    path = ntg_node_get_path(found);

    return path;

}

void print_node_state(ntg_server *server, ntg_node *first,int indentation)
{
    ntg_node *current = first;
    ntg_node *next;
	ntg_node_attribute *attribute = NULL;
    int i;
	bool has_children;
	char value_buffer[ NTG_LONG_STRLEN ];

    if(first==NULL){
        printf("No nodes\n");
        return;
    }

	do{
        assert(current != NULL);
        next = current->next;
        for(i=0;i<indentation;i++)
            printf("  |");

		printf("  Node: \"%s\".\t interface name: %s.\t Path: %s\n",current->name,current->interface->info->name, current->path->string);

		has_children = (current->nodes!=NULL);

		for( attribute = current->attributes; attribute != NULL; attribute = attribute->next )
		{
			if( attribute->value )
			{
				for(i=0;i<indentation;i++)
					printf("  |");

				printf( has_children ? "  |" : "   ");

				if( ntg_value_sprintf( value_buffer, NTG_LONG_STRLEN, attribute->value ) != NTG_NO_ERROR )
				{
					strcpy( value_buffer, "Error printing attribute - buffer too short?" );
				}

				printf("   -Attribute:  %s = %s\n", attribute->endpoint->name, value_buffer );
			}

			if( attribute == current->attribute_last )
			{
				break;
			}
		}

        if(has_children)
            print_node_state(server,current->nodes,indentation+1);
        current = next;
    }while(current!=first);
}


ntg_list *ntg_server_get_nodelist(const ntg_server * server,
        ntg_node *container,
        ntg_path *parent_path,
        ntg_list *nodelist)
{

    int parent_n_elems = 0;
    ntg_path *path = NULL;
    ntg_path **nodes = NULL;
    ntg_node *current, *marker;

    if (nodelist == NULL) {
        nodelist = ntg_list_new(NTG_LIST_NODES);
    }

    if (parent_path != NULL) {
        parent_n_elems = parent_path->n_elems;
    }

    if (container != NULL) {
        current = container;
    } else {
        current = ntg_server_get_root(server);
    }

    if (current->nodes != NULL) {
        current = current->nodes;
    } else {
        /* we're in an empty container */
        return nodelist;        /* no nodes to add */
    }

    marker = current;

    do {

        /* get path from node */
        if (ntg_path_validate(current->path) == NTG_NO_ERROR) {
            path = current->path;
        } else {
            path = ntg_node_update_path(current);
        }

        /* add the path to the node list */
        nodelist->n_elems++;
        nodes = (ntg_path **)nodelist->elems;
        nodes = ntg_realloc(nodes, nodelist->n_elems * sizeof(ntg_path));
		nodelist->elems = nodes;
        nodes[nodelist->n_elems - 1] = ntg_path_copy(path);

        if (current->nodes != NULL) {
            nodelist = ntg_server_get_nodelist(server, current, path, nodelist);
        }

        current = current->next;

    } while (current != marker);

    return nodelist;
}


void ntg_version(char *destination, int destination_size)
{
#ifdef _WINDOWS

	/*windows only - read version number from current module*/

	HMODULE module_handle = NULL;
	WCHAR file_name[_MAX_PATH];
	DWORD handle = 0;
	BYTE *version_info = NULL;
	UINT len = 0;
	VS_FIXEDFILEINFO *vsfi = NULL;
	DWORD size; 

	GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS| 
					GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
					(LPCTSTR)ntg_version, 
					&module_handle);

	size = GetModuleFileName(module_handle, file_name, _MAX_PATH);
	file_name[size] = 0;
	size = GetFileVersionInfoSize(file_name, &handle);
	version_info = ntg_malloc(size);
	if (!GetFileVersionInfo(file_name, handle, size, version_info))
	{
		NTG_TRACE_ERROR("Failed to read version number from module");
		ntg_free(version_info);

		snprintf( destination, destination_size, "no version number" );
		return;
	}
	// we have version information
	VerQueryValue(version_info, L"\\", (void**)&vsfi, &len);

	snprintf(destination, destination_size, "%i.%i.%i.%i", 
						HIWORD(vsfi->dwFileVersionMS), 
						LOWORD(vsfi->dwFileVersionMS),
						HIWORD(vsfi->dwFileVersionLS),
						LOWORD(vsfi->dwFileVersionLS) );

	ntg_free(version_info);

#else

	/*non-windows - use version number from preprocessor macro*/
	snprintf(destination, destination_size, TOSTRING(LIBINTEGRA_VERSION) );

#endif
}


bool ntg_saved_version_is_newer_than_current( const char *saved_version )
{
	char current_version[ NTG_LONG_STRLEN ];
	const char *saved_build_number;
	const char *current_build_number;

	assert( saved_version );

	ntg_version( current_version, NTG_LONG_STRLEN );

	saved_build_number = strrchr( saved_version, '.' ) + 1;
	current_build_number = strrchr( current_version, '.' ) + 1;

	return ( atoi( saved_build_number ) > atoi( current_build_number ) );
}


static int ntg_server_add_osc_interface(ntg_server *server, unsigned short port) 
{

    char sport[6];
    sport[5]=0;
    snprintf(sport, 5, "%d", port);

    osc_interface = lo_server_thread_new(sport, ntg_osc_error);

    if(osc_interface) {
        /* catch all */
        lo_server_thread_add_method(osc_interface, NULL, NULL,
                handler_namespace_method, server);

        lo_server_thread_start(osc_interface);

        return 1;
    }
    return 0;
}

static void ntg_server_destroy_osc_client(ntg_server *server)
{
    ntg_osc_client_destroy(server->osc_client);
}

static void ntg_server_destroy_osc_interface(ntg_server *server)
{
	return; /* LH - temporary hack - lo_server_thread_free is causing crash!*/

    lo_server_thread_free(osc_interface);
}


#ifdef _WINDOWS
static void invalid_parameter_handler( const wchar_t * expression, const wchar_t * function, const wchar_t * file, unsigned int line, uintptr_t pReserved )
{
	NTG_TRACE_ERROR( "CRT encoutered invalid parameter!" );
}
#endif



ntg_server *ntg_server_new( const char *osc_client_url, unsigned short osc_client_port, const char *system_module_directory, const char *third_party_module_directory )
{
    ntg_server *server = NULL;

    if(server_ != NULL) {
        NTG_TRACE_ERROR("ntg_server is a singleton, returning existing instance");
        return server_;
    }

#ifdef _WINDOWS
	_set_invalid_parameter_handler( invalid_parameter_handler );
#endif


    server = ntg_malloc(sizeof(ntg_server));

	ntg_scratch_directory_initialize(server);

	server->module_manager = ntg_module_manager_create( server->scratch_directory_root, system_module_directory, third_party_module_directory );

    server->state_table				= ntg_hashtable_new();
    server->osc_client				= ntg_osc_client_new(osc_client_url, osc_client_port);
    server->terminate				= false;
    server->loading					= false;
    server->root					= NULL;

	ntg_system_class_handlers_initialize( server );

    server_ = server;

    command_queue_ = ntg_queue_new(NTG_COMMAND_QUEUE_ELEMENTS);
	
    return server_;

}

void ntg_server_free(ntg_server *server)
{

    if (server == NULL) {
        return;
    }

	/* free libxml state */
	xmlCleanupParser();
	xmlCleanupGlobals();

	/* shutdown system class handlers */
	ntg_system_class_handlers_shutdown(server);

    /* free node graph */
    ntg_server_node_delete(server, ntg_server_get_root(server));

    /* de-reference bridge */
//    server->bridge = NULL;

	ntg_module_manager_free( server->module_manager );

	ntg_hashtable_free(server->state_table);

	ntg_scratch_directory_free(server);

    ntg_free(server);

#if BUILD_LUASCRIPTING
    /* FIX is there a luascripting_free() */
#endif

}

/* run server command -- non-blocking version
 * command is queued and any return value is discarded */
void ntg_command_enqueue(ntg_command_id command_id, const int argc, ...)
{

    ntg_command *command = NULL;
    va_list argv;

    /* check command is valid */
    if(command_id <= NTG_COMMAND_ID_begin || command_id >= NTG_COMMAND_ID_end) {
        NTG_TRACE_ERROR_WITH_INT("erroneous command_id id", command_id);
        return;
    }
    /* don't queue any more commands if termination has been requested */
    if(server_->terminate) {
        return;
    }

    va_start(argv, argc);
    command = ntg_command_new(command_id, argc, argv);
    va_end(argv);

    pthread_mutex_lock(&queue_mutex);
    if(!ntg_queue_push(command_queue_, command)) {
        NTG_TRACE_ERROR("command queue is full, cannot execute command");
        ntg_command_free(command);
    } else {
        pthread_cond_signal(&server_cond);
    }
    pthread_mutex_unlock(&queue_mutex);
}

ntg_bridge_callback ntg_server_get_bridge_callback(void)
{
    return server_->bridge->bridge_callback;
}

static void *ntg_server_dequeue_commands(void *argv)
{
    ntg_command *command = NULL;
    ntg_args_set *args_set = NULL;

#ifndef _WINDOWS
    ntg_sig_unblock(&signal_sigset);
#endif

    while (1) 
	{
        pthread_mutex_lock(&server_mutex);
        /* we don't use timedwait, because there are no circumstances
         * under which messages can get added to the queue without a wakeup
         * signal being sent */
        pthread_cond_wait(&server_cond, &server_mutex);

        while((command = ntg_queue_pop(command_queue_)) != NULL) 
		{
            switch(command->command_id) 
			{
                case NTG_SET:
                    args_set = (ntg_args_set *)command->argv;
                    ntg_set_( server_, args_set->source, args_set->path, args_set->value);
                    break;
                default:
                    NTG_TRACE_VERBOSE_WITH_INT("unhandled server command: ", command->command_id);
                    break;
            }

            ntg_command_free(command);
            usleep (NTG_DEQUEUE_WAIT_TIME);
        }
        pthread_mutex_unlock(&server_mutex);
        if (server_->terminate) {
            pthread_exit(NULL);
            break;
        }
    }

    return NULL;
}


ntg_node *ntg_server_get_root(const ntg_server * server)
{
    return server->root;
}

void ntg_server_receive_(ntg_server * server,
        ntg_command_source source,
        const ntg_node_attribute *node_attribute,
        const ntg_value * value)
{
    if (server->loading) 
	{
        return;
    }

    ntg_lock_server();
    ntg_command_enqueue(NTG_SET, 3, source, node_attribute->path, value);
    ntg_unlock_server();
}


void receive_callback(ntg_id id, const char *attribute_name,
        const ntg_value * value)
{
    const ntg_node_attribute *attribute = NULL;
    ntg_node *target                    = NULL;
    ntg_node *root                      = NULL;

    ntg_lock_server();
    root = ntg_server_get_root(server_);
    target = ntg_node_find_by_id_r(root, id);

    if (target == NULL) {
        NTG_TRACE_ERROR_WITH_INT("couldn't find node with id", id);
        ntg_unlock_server();
        return;
    }

    attribute = ntg_find_attribute(target, attribute_name);

    if (attribute == NULL) {
        NTG_TRACE_ERROR_WITH_STRING("couldn't find attribute", attribute_name);
        ntg_unlock_server();
        return;
    }
    ntg_unlock_server();

    ntg_server_receive_(server_, NTG_SOURCE_HOST, attribute, value);
}


ntg_error_code ntg_server_connect_in_host( ntg_server *server, const ntg_node_attribute *source, const ntg_node_attribute *target, bool connect )
{
	assert( server && source && target );
	
	if( !ntg_endpoint_is_audio_stream( source->endpoint ) || source->endpoint->stream_info->direction != NTG_STREAM_OUTPUT )
	{
		NTG_TRACE_ERROR( "trying to make incorrect connection in host - source isn't an audio output" );
		return NTG_ERROR;
	}

	if( !ntg_endpoint_is_audio_stream( target->endpoint ) || target->endpoint->stream_info->direction != NTG_STREAM_INPUT )
	{
		NTG_TRACE_ERROR( "trying to make incorrect connection in host - target isn't an audio output" );
		return NTG_ERROR;
	}

    if( connect ) 
	{
        server->bridge->module_connect( source, target );
    } 
	else 
	{
        server->bridge->module_disconnect( source, target );
    }

    return NTG_NO_ERROR;
}


int ntg_server_node_delete_r_(ntg_server * server, ntg_node * node)
{

    ntg_node *current, *next;

    if (node == NULL) {
        return NTG_ERROR;
    }

    current = node;

    while (1) {
        if (current->next == current) {
            break;
        }
        next = current->next;

        ntg_server_node_delete(server, current);
        current = next;

    }

    ntg_server_node_delete(server, current);

    return NTG_NO_ERROR;

}

ntg_error_code ntg_server_node_delete(ntg_server * server, ntg_node * node)
{
    if (node == NULL) {
        NTG_TRACE_ERROR("node is NULL");
        return NTG_ERROR;
    }

    /* recursively delete subnodes */
    ntg_server_node_delete_r_(server, node->nodes);

    /* remove from module host */
    if (server->bridge != NULL) 
	{
		if( node->interface && ntg_interface_has_implementation( node->interface ) )
		{
			server->bridge->module_remove(node->id);
		}
    }

    /* unlink */
    if (node->parent == NULL) {
        /* root node */
    } else if (node->parent->nodes == node) {
        /* first node in list */
        if (node == node->next) {
            node->parent->nodes = NULL;
        } else {
            node->parent->nodes = node->next;
        }
    }

    /* free the node */
    ntg_node_free(node);

    return NTG_NO_ERROR;

}


void ntg_server_halt(ntg_server * server)
{
    NTG_TRACE_PROGRESS("setting terminate flag");

    ntg_lock_server();
    server->terminate = true; /* FIX: use a semaphore or condition */

    pthread_cond_signal(&server_cond); /* wake the server thread up */

    NTG_TRACE_PROGRESS("shutting down OSC client");
    ntg_server_destroy_osc_client(server);
    NTG_TRACE_PROGRESS("shutting down XMLRPC interface");
    ntg_xmlrpc_server_terminate();

    /* FIX: for now we only support the old 'stable' xmlrpc-c, which can't
       wake up a sleeping server */
    NTG_TRACE_PROGRESS("joining xmlrpc thread");
    pthread_join(xmlrpc_thread, NULL);

    NTG_TRACE_PROGRESS("shutting down OSC interface");
    ntg_server_destroy_osc_interface(server);

    NTG_TRACE_PROGRESS("joining server thread");
    ntg_unlock_server();
    pthread_join(server_thread, NULL);
    NTG_TRACE_PROGRESS("deallocating server");
    ntg_server_free(server);

    /* FIX: This hangs on all platforms, just comment out for now */
    /*
    NTG_TRACE_PROGRESS("closing bridge");
    dlclose(bridge_handle);
    */

    NTG_TRACE_PROGRESS("freeing command queue");
    ntg_queue_free(command_queue_);
    NTG_TRACE_PROGRESS("cleaning up XML parser");
    xmlCleanupParser();

	server_ = NULL;
    command_queue_ = NULL;

    NTG_TRACE_PROGRESS("done!");
}

ntg_error_code ntg_server_run(const char *bridge_path,
		const char *system_module_directory,
		const char *third_party_module_directory,
        unsigned short xmlrpc_server_port,
        unsigned short osc_server_port,
        const char *osc_client_url,
        unsigned short osc_client_port)
{
    ntg_node *root;
    ntg_bridge_interface *p;
    struct stat file_buffer;
    char version[NTG_LONG_STRLEN];

    unsigned short*xmlport=NULL;

    p = NULL;
    root = NULL;

    ntg_version(version, NTG_LONG_STRLEN);
    NTG_TRACE_PROGRESS_WITH_STRING("libIntegra version", version);

#ifdef __APPLE__
    sem_abyss_init = sem_open("sem_abyss_init", O_CREAT, 0777, 0);
    sem_system_shutdown = sem_open("sem_system_shutdown", O_CREAT, 0777, 0);
#else
    sem_init(&sem_abyss_init, 0, 0);
    sem_init(&sem_system_shutdown, 0, 0);
#endif

#ifndef _WINDOWS
    ntg_sig_block(&signal_sigset);
#endif

    if (bridge_path == NULL) 
	{
        NTG_TRACE_ERROR("bridge_path is NULL");
        return NTG_ERROR;
    }

    if( system_module_directory == NULL) 
	{
        NTG_TRACE_ERROR("system_module_directory is NULL");
        return NTG_ERROR;
    }

    if( third_party_module_directory == NULL) 
	{
        NTG_TRACE_ERROR("third_party_module_directory is NULL");
        return NTG_ERROR;
    }

    server_ = ntg_server_new( osc_client_url, osc_client_port, system_module_directory, third_party_module_directory );

    if (bridge_path == NULL) 
	{
        NTG_TRACE_ERROR("bridge_path is NULL");
        return NTG_ERROR;
    }

    if (stat(bridge_path, &file_buffer) != 0) 
	{
        NTG_TRACE_ERROR("bridge_path points to a nonexsitant file");
        return NTG_ERROR;
    }

    p = (ntg_bridge_interface *) ntg_bridge_load(bridge_path);

    if (p != NULL) 
	{
        p->bridge_init();
    } 
	else 
	{
        NTG_TRACE_ERROR("bridge init failed");
        fflush(stderr);
        return NTG_FAILED;
    }

    /* Add the server receive callback to the bridge's methods */
    p->server_receive_callback = receive_callback;

    server_->bridge = p;

    root = ntg_node_new();

    root->path = ntg_path_new();
    /* not sure we need to set an interface for the root node?
	ntg_node_set_interface(root, ??? );
	*/

    ntg_node_set_name(root, "root");
    server_->root = root;

    if(ntg_server_add_osc_interface(server_, osc_server_port)) 
	{
        NTG_TRACE_PROGRESS_WITH_INT("running OSC interface on port", osc_server_port);
    } 
	else 
	{
        NTG_TRACE_ERROR_WITH_INT("failed to start OSC interface on port", osc_server_port);
    }

    /* 'consumer' thread */
    pthread_create(&server_thread, NULL, ntg_server_dequeue_commands, server_);

    xmlport=(unsigned short*)ntg_malloc(sizeof(unsigned short));
    *xmlport=xmlrpc_server_port;
    pthread_create(&xmlrpc_thread, NULL, ntg_xmlrpc_server_run, xmlport);
    NTG_TRACE_PROGRESS_WITH_INT("running XMLRPC interface on port", xmlrpc_server_port);


#ifndef _WINDOWS
    ntg_sig_setup();
#endif

    NTG_TRACE_PROGRESS("server running...");

    sem_wait(SEM_SYSTEM_SHUTDOWN);

    NTG_TRACE_PROGRESS("server shutting down...");

    ntg_terminate();

    NTG_TRACE_PROGRESS("server terminated!");

    return NTG_NO_ERROR;
}
