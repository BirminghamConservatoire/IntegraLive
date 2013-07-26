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

extern "C" 
{
#include <dlfcn.h>
}

#include <sys/stat.h>

#include <libxml/xmlreader.h>

#include "server.h"
#include "scratch_directory.h"
#include "osc_client.h"
#include "system_class_handlers.h"
#include "reentrance_checker.h"
#include "module_manager.h"
#include "trace.h"
#include "globals.h"
#include "xmlrpc_server.h"
#include "helper.h"
#include "value.h"
#include "path.h"
#include "server_commands.h"
#include "bridge_host.h"

#include "api/server_startup_info.h"


using namespace ntg_api;


namespace ntg_api
{
	CServerApi *CServerApi::create_server( const ntg_api::CServerStartupInfo &startup_info )
	{
		NTG_TRACE_PROGRESS_WITH_STRING( "libIntegra version", ntg_version().c_str() );

		#ifdef __APPLE__
			sem_abyss_init = sem_open("sem_abyss_init", O_CREAT, 0777, 0);
			sem_system_shutdown = sem_open("sem_system_shutdown", O_CREAT, 0777, 0);
		#else
			sem_init(&sem_abyss_init, 0, 0);
			sem_init(&sem_system_shutdown, 0, 0);
		#endif

		if( startup_info.bridge_path.empty() ) 
		{
			NTG_TRACE_ERROR("bridge_path is empty" );
			return NULL;
		}

		struct stat file_buffer;
		if( stat( startup_info.bridge_path.c_str(), &file_buffer ) != 0 ) 
		{
			NTG_TRACE_ERROR( "bridge_path points to a nonexsitant file" );
			return NULL;
		}

		if( startup_info.system_module_directory.empty() ) 
		{
			NTG_TRACE_ERROR("system_module_directory is empty" );
			return NULL;
		}

		if( startup_info.third_party_module_directory.empty() ) 
		{
			NTG_TRACE_ERROR("third_party_module_directory is empty" );
			return NULL;
		}

		return new ntg_internal::CServer( startup_info );
	}
}


namespace ntg_internal
{
	#ifdef _WINDOWS
		static void invalid_parameter_handler( const wchar_t * expression, const wchar_t * function, const wchar_t * file, unsigned int line, uintptr_t pReserved )
		{
			NTG_TRACE_ERROR( "CRT encoutered invalid parameter!" );
		}
	#endif


	
	static void host_callback( internal_id id, const char *attribute_name, const CValue *value )
	{
		if( server_->get_terminate_flag() ) 
		{
			return;
		}

		server_->lock();

		const CNode *target = server_->find_node( id );
		if( target ) 
		{
			CPath path( target->get_path() );
			path.append_element( attribute_name );

			ntg_set_( *server_, NTG_SOURCE_HOST, path, value );
		}
		else
		{
			NTG_TRACE_ERROR_WITH_INT("couldn't find node with id", id );
		}

		server_->unlock();
	}


	CServer::CServer( const ntg_api::CServerStartupInfo &startup_info )
	{
		NTG_TRACE_PROGRESS( "constructing server" );

		server_ = this;

		pthread_mutex_init( &m_mutex, NULL );

		#ifdef _WINDOWS
			_set_invalid_parameter_handler( invalid_parameter_handler );
		#endif

		m_scratch_directory = new CScratchDirectory;

		m_module_manager = new CModuleManager( get_scratch_directory(), startup_info.system_module_directory, startup_info.third_party_module_directory );

		m_osc_client = ntg_osc_client_new( startup_info.osc_client_url.c_str(), startup_info.osc_client_port );
		m_terminate = false;

		ntg_system_class_handlers_initialize( *this );

		m_reentrance_checker = new CReentranceChecker();

		m_bridge = ( ntg_bridge_interface * ) ntg_bridge_load( startup_info.bridge_path.c_str() );
		if( m_bridge ) 
		{
			m_bridge->bridge_init();
		} 
		else 
		{
			NTG_TRACE_ERROR( "bridge failed to load" );
		}

		/* Add the server receive callback to the bridge's methods */
		m_bridge->server_receive_callback = host_callback;

		/* create the xmlrpc interface */
		unsigned short *xmlport = new unsigned short;
		*xmlport = startup_info.xmlrpc_server_port;
		pthread_create( &m_xmlrpc_thread, NULL, ntg_xmlrpc_server_run, xmlport );

	#ifndef _WINDOWS
		ntg_sig_setup();
	#endif

		NTG_TRACE_PROGRESS( "Server construction complete" );
	}


	CServer::~CServer()
	{
		NTG_TRACE_PROGRESS("setting terminate flag");

		lock();
		m_terminate = true; /* FIX: use a semaphore or condition */

		/* delete all nodes */
		node_map copy_of_nodes = m_nodes;
		for( node_map::const_iterator i = copy_of_nodes.begin(); i != copy_of_nodes.end(); i++ )
		{
			ntg_delete_( *this, NTG_SOURCE_SYSTEM, i->second->get_path() );
		}
	
		/* shutdown system class handlers */
		ntg_system_class_handlers_shutdown( *this );

		/* de-reference bridge */
	    m_bridge = NULL;

		delete m_module_manager;

		delete m_reentrance_checker;

		delete m_scratch_directory;

		NTG_TRACE_PROGRESS( "shutting down OSC client" );
		ntg_osc_client_destroy( m_osc_client );
		
		NTG_TRACE_PROGRESS("shutting down XMLRPC interface");
		ntg_xmlrpc_server_terminate();

		/* FIX: for now we only support the old 'stable' xmlrpc-c, which can't
		   wake up a sleeping server */
		NTG_TRACE_PROGRESS("joining xmlrpc thread");
		pthread_join( m_xmlrpc_thread, NULL );



		/* FIX: This hangs on all platforms, just comment out for now */
		/*
		NTG_TRACE_PROGRESS("closing bridge");
		dlclose(bridge_handle);
		*/

		NTG_TRACE_PROGRESS( "cleaning up XML parser" );
		xmlCleanupParser();
		xmlCleanupGlobals();


		NTG_TRACE_PROGRESS( "done!" );

		server_ = NULL;

		unlock();

		pthread_mutex_destroy( &m_mutex );

		NTG_TRACE_PROGRESS( "server destruction complete" );
	}


	void CServer::block_until_shutdown_signal()
	{
		NTG_TRACE_PROGRESS("server blocking until shutdown signal...");

		sem_wait( SEM_SYSTEM_SHUTDOWN );

		NTG_TRACE_PROGRESS("server blocking finished...");
	}


	void CServer::lock()
	{
	    pthread_mutex_lock( &m_mutex );
	}


	void CServer::unlock()
	{
		pthread_mutex_unlock( &m_mutex );
	}


	const CNode *CServer::find_node( const ntg_api::string &path_string, const CNode *relative_to ) const
	{
		if( relative_to )
		{
			return m_state_table.lookup_node( relative_to->get_path().get_string() + "." + path_string );
		}
		else
		{
			return m_state_table.lookup_node( path_string );
		}
	}


	const CNode *CServer::find_node( internal_id id ) const
	{
		return m_state_table.lookup_node( id );
	}


	CNode *CServer::find_node_writable( const ntg_api::string &path_string, const CNode *relative_to )
	{
		if( relative_to )
		{
			return m_state_table.lookup_node_writable( relative_to->get_path().get_string() + "." + path_string );
		}
		else
		{
			return m_state_table.lookup_node_writable( path_string );
		}
	}


	const node_map &CServer::get_sibling_set( const CNode &node ) const
	{
		const CNode *parent = node.get_parent();
		if( parent )
		{
			return parent->get_children();
		}
		else
		{
			return m_nodes;
		}
	}


	node_map &CServer::get_sibling_set_writable( CNode &node )
	{
		CNode *parent = node.get_parent_writable();
		if( parent )
		{
			return parent->get_children_writable();
		}
		else
		{
			return m_nodes;
		}
	}


	const CNodeEndpoint *CServer::find_node_endpoint( const ntg_api::string &path_string, const CNode *relative_to ) const
	{
		if( relative_to )
		{
			return m_state_table.lookup_node_endpoint( relative_to->get_path().get_string() + "." + path_string );
		}
		else
		{
			return m_state_table.lookup_node_endpoint( path_string );
		}
	}


	CNodeEndpoint *CServer::find_node_endpoint_writable( const ntg_api::string &path_string, const CNode *relative_to )
	{
		if( relative_to )
		{
			return m_state_table.lookup_node_endpoint_writable( relative_to->get_path().get_string() + "." + path_string );
		}
		else
		{
			return m_state_table.lookup_node_endpoint_writable( path_string );
		}
	}


	const string &CServer::get_scratch_directory() const
	{
		return m_scratch_directory->get_scratch_directory();
	}



	
}





#if 0 //DEPRECATED

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>

#include <pthread.h>
#include <semaphore.h>

extern "C" 
{
#include <dlfcn.h>
}

#include <sys/stat.h>

#include <libxml/encoding.h>
#include <libxml/xmlwriter.h>
#include <libxml/xmlreader.h>

#include "lua.h"
#include "xmlrpc_server.h"
#include "helper.h"
#include "globals.h"
#include "luascripting.h"
#include "value.h"
#include "validate.h"
#include "server.h"
#include "node.h"
#include "bridge_host.h"
#include "signals.h"
#include "server_commands.h"
#include "system_class_handlers.h"
#include "module_manager.h"
#include "data_directory.h"
#include "scratch_directory.h"
#include "player_handler.h"
#include "osc_client.h"
#include "interface.h"
#include "reentrance_checker.h"

#ifdef _WINDOWS
	#ifdef interface 
		#undef interface
	#endif
#endif

using namespace ntg_api;
using namespace ntg_internal;


static pthread_mutex_t server_mutex = PTHREAD_MUTEX_INITIALIZER;


void ntg_lock_server(void)
{
    pthread_mutex_lock(&server_mutex);
}

void ntg_unlock_server(void)
{
    pthread_mutex_unlock(&server_mutex);
}


void ntg_server_set_host_dsp(const ntg_server *server, bool status)
{

    if(server->bridge != NULL) {
        server->bridge->host_dsp(status);
    }

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
	version_info = new BYTE[ size ];
	if (!GetFileVersionInfo(file_name, handle, size, version_info))
	{
		NTG_TRACE_ERROR("Failed to read version number from module");
		delete[] version_info;

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

	delete[] version_info;

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


static void ntg_server_destroy_osc_client(ntg_server *server)
{
    ntg_osc_client_destroy(server->osc_client);
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


    server = new ntg_server;

	ntg_scratch_directory_initialize(server);

	server->module_manager = new CModuleManager( server->scratch_directory_root, system_module_directory, third_party_module_directory );

    server->osc_client				= ntg_osc_client_new(osc_client_url, osc_client_port);
    server->terminate				= false;

	ntg_system_class_handlers_initialize( server );

	server->reentrance_checker = new CReentranceChecker();

    server_ = server;

    return server_;

}

void ntg_server_free(ntg_server *server)
{
	assert( server );

	/* delete all nodes */
	node_map copy_of_root_nodes = server->root_nodes;
	for( node_map::const_iterator i = copy_of_root_nodes.begin(); i != copy_of_root_nodes.end(); i++ )
	{
		ntg_delete_( server, NTG_SOURCE_SYSTEM, i->second->get_path() );
	}
	
	/* free libxml state */
	xmlCleanupParser();
	xmlCleanupGlobals();

	/* shutdown system class handlers */
	ntg_system_class_handlers_shutdown(server);

    /* de-reference bridge */
//    server->bridge = NULL;

	delete server->module_manager;

	delete server->reentrance_checker;

	ntg_scratch_directory_free(server);

    delete server;

    /* FIX is there a luascripting_free() */

}



void ntg_server_receive_from_host( ntg_id id, const char *attribute_name, const CValue *value )
{
    if( server_->terminate ) 
	{
        return;
    }

    ntg_lock_server();

	const CNode *target = ntg_find_node( id );
    if( !target ) 
	{
        NTG_TRACE_ERROR_WITH_INT("couldn't find node with id", id );
        ntg_unlock_server();
        return;
    }

	CPath path( target->get_path() );
	path.append_element( attribute_name );

	ntg_set_( server_, NTG_SOURCE_HOST, path, value );

    ntg_unlock_server();
}


ntg_error_code ntg_server_connect_in_host( ntg_server *server, const CNodeEndpoint *source, const CNodeEndpoint *target, bool connect )
{
	assert( server && source && target );
	
	const ntg_endpoint *source_endpoint = source->get_endpoint();
	const ntg_endpoint *target_endpoint = target->get_endpoint();

	if( !ntg_endpoint_is_audio_stream( source_endpoint ) || source_endpoint->stream_info->direction != NTG_STREAM_OUTPUT )
	{
		NTG_TRACE_ERROR( "trying to make incorrect connection in host - source isn't an audio output" );
		return NTG_ERROR;
	}

	if( !ntg_endpoint_is_audio_stream( target_endpoint ) || target_endpoint->stream_info->direction != NTG_STREAM_INPUT )
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


const ntg_internal::CNodeEndpoint *ntg_find_node_endpoint( const ntg_api::string &path_string, const ntg_internal::CNode *relative_to )
{
	if( relative_to )
	{
		return server_->state_table.lookup_node_endpoint( relative_to->get_path().get_string() + "." + path_string );
	}
	else
	{
		return server_->state_table.lookup_node_endpoint( path_string );
	}
}


ntg_internal::CNodeEndpoint *ntg_find_node_endpoint_writable( const ntg_api::string &path_string, const ntg_internal::CNode *relative_to )
{
	if( relative_to )
	{
		return server_->state_table.lookup_node_endpoint_writable( relative_to->get_path().get_string() + "." + path_string );
	}
	else
	{
		return server_->state_table.lookup_node_endpoint_writable( path_string );
	}
}


const ntg_internal::CNode *ntg_find_node( const ntg_api::string &path_string, const ntg_internal::CNode *relative_to )
{
	if( relative_to )
	{
		return server_->state_table.lookup_node( relative_to->get_path().get_string() + "." + path_string );
	}
	else
	{
		return server_->state_table.lookup_node( path_string );
	}
}


const ntg_internal::CNode *ntg_find_node( ntg_id id )
{
	return server_->state_table.lookup_node( id );
}


ntg_internal::CNode *ntg_find_node_writable( const ntg_api::string &path_string, const ntg_internal::CNode *relative_to )
{
	if( relative_to )
	{
		return server_->state_table.lookup_node_writable( relative_to->get_path().get_string() + "." + path_string );
	}
	else
	{
		return server_->state_table.lookup_node_writable( path_string );
	}
}


const ntg_internal::node_map &ntg_get_sibling_set( ntg_server *server, const ntg_internal::CNode &node )
{
	const CNode *parent = node.get_parent();
	if( parent )
	{
		return parent->get_children();
	}
	else
	{
		return server->root_nodes;
	}
}


ntg_internal::node_map &ntg_get_sibling_set_writable( ntg_server *server, ntg_internal::CNode &node )
{
	CNode *parent = node.get_parent_writable();
	if( parent )
	{
		return parent->get_children_writable();
	}
	else
	{
		return server->root_nodes;
	}
}


void ntg_server_halt(ntg_server * server)
{
    NTG_TRACE_PROGRESS("setting terminate flag");

    ntg_lock_server();
    server->terminate = true; /* FIX: use a semaphore or condition */

    NTG_TRACE_PROGRESS("shutting down OSC client");
    ntg_server_destroy_osc_client(server);
    NTG_TRACE_PROGRESS("shutting down XMLRPC interface");
    ntg_xmlrpc_server_terminate();

    /* FIX: for now we only support the old 'stable' xmlrpc-c, which can't
       wake up a sleeping server */
    NTG_TRACE_PROGRESS("joining xmlrpc thread");
    pthread_join(xmlrpc_thread, NULL);

    ntg_unlock_server();
    NTG_TRACE_PROGRESS("deallocating server");
    ntg_server_free(server);

    /* FIX: This hangs on all platforms, just comment out for now */
    /*
    NTG_TRACE_PROGRESS("closing bridge");
    dlclose(bridge_handle);
    */

    NTG_TRACE_PROGRESS("cleaning up XML parser");
    xmlCleanupParser();

	server_ = NULL;

    NTG_TRACE_PROGRESS("done!");
}

ntg_error_code ntg_server_run(const char *bridge_path,
		const char *system_module_directory,
		const char *third_party_module_directory,
        unsigned short xmlrpc_server_port,
        const char *osc_client_url,
        unsigned short osc_client_port)
{
    ntg_bridge_interface *p;
    struct stat file_buffer;
    char version[NTG_LONG_STRLEN];

    unsigned short*xmlport=NULL;

    p = NULL;

    ntg_version(version, NTG_LONG_STRLEN);
    NTG_TRACE_PROGRESS_WITH_STRING("libIntegra version", version);

#ifdef __APPLE__
    sem_abyss_init = sem_open("sem_abyss_init", O_CREAT, 0777, 0);
    sem_system_shutdown = sem_open("sem_system_shutdown", O_CREAT, 0777, 0);
#else
    sem_init(&sem_abyss_init, 0, 0);
    sem_init(&sem_system_shutdown, 0, 0);
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
    p->server_receive_callback = ntg_server_receive_from_host;

    server_->bridge = p;

    xmlport = new unsigned short;
    *xmlport = xmlrpc_server_port;
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


#endif