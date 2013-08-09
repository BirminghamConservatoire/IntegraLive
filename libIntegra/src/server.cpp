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
#include "reentrance_checker.h"
#include "module_manager.h"
#include "trace.h"
#include "globals.h"
#include "xmlrpc_server.h"
#include "value.h"
#include "path.h"
#include "bridge_host.h"
#include "string_helper.h"
#include "lua_engine.h"
#include "player_handler.h"

#include "api/server_startup_info.h"
#include "api/command_api.h"

#include <assert.h>

namespace ntg_api
{
	CServerApi *CServerApi::create_server( const CServerStartupInfo &startup_info )
	{
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

			server_->process_command( CSetCommandApi::create( path, value ), NTG_SOURCE_HOST );
		}
		else
		{
			NTG_TRACE_ERROR_WITH_INT("couldn't find node with id", id );
		}

		server_->unlock();
	}


	CServer::CServer( const CServerStartupInfo &startup_info )
	{
		NTG_TRACE_PROGRESS_WITH_STRING( "libIntegra version", get_libintegra_version().c_str() );

		server_ = this;

		pthread_mutex_init( &m_mutex, NULL );

		#ifdef _WINDOWS
			_set_invalid_parameter_handler( invalid_parameter_handler );
		#endif

		m_next_internal_id = 0;

		m_scratch_directory = new CScratchDirectory;

		m_lua_engine = new CLuaEngine;

		m_player_handler = new CPlayerHandler( *this );

		m_module_manager = new CModuleManager( get_scratch_directory(), startup_info.system_module_directory, startup_info.third_party_module_directory );

		m_osc_client = ntg_osc_client_new( startup_info.osc_client_url.c_str(), startup_info.osc_client_port );
		m_terminate = false;

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
			process_command( CDeleteCommandApi::create( i->second->get_path() ), NTG_SOURCE_SYSTEM );
		}
	
		/* de-reference bridge */
	    m_bridge = NULL;

		delete m_module_manager;

		delete m_reentrance_checker;

		delete m_scratch_directory;

		delete m_lua_engine;

		delete m_player_handler;

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


	const CNode *CServer::find_node( const string &path_string, const CNode *relative_to ) const
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


	CNode *CServer::find_node_writable( const string &path_string, const CNode *relative_to )
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


	const CNodeEndpoint *CServer::find_node_endpoint( const string &path_string, const CNode *relative_to ) const
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


	CNodeEndpoint *CServer::find_node_endpoint_writable( const string &path_string, const CNode *relative_to )
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


	const CValue *CServer::get_value( const CPath &path ) const
	{
		const CNodeEndpoint *node_endpoint = find_node_endpoint( path.get_string() );
		
		return node_endpoint ? node_endpoint->get_value() : NULL;
	}


	const string &CServer::get_scratch_directory() const
	{
		return m_scratch_directory->get_scratch_directory();
	}


	void CServer::dump_state( const node_map &nodes, int indentation )
	{
		for( node_map::const_iterator i = nodes.begin(); i != nodes.end(); i++ )
		{
			const CNode *node = i->second;

			for( int i = 0; i < indentation; i++ )
			{
				printf("  |");
			}

			const CInterfaceDefinition &interface_definition = node->get_interface_definition();
			string module_id_string = CStringHelper::guid_to_string( interface_definition.get_module_guid() );
			printf("  Node: \"%s\".\t module name: %s.\t module id: %s.\t Path: %s\n", node->get_name(), interface_definition.get_interface_info().get_name().c_str(), module_id_string.c_str(), node->get_path().get_string().c_str() );

			bool has_children = !node->get_children().empty();

			const node_endpoint_map &node_endpoints = node->get_node_endpoints();
			for( node_endpoint_map::const_iterator node_endpoint_iterator = node_endpoints.begin(); node_endpoint_iterator != node_endpoints.end(); node_endpoint_iterator++ )
			{
				const CNodeEndpoint *node_endpoint = node_endpoint_iterator->second;
				const CValue *value = node_endpoint->get_value();
				if( !value ) continue;

				for( int i = 0; i < indentation; i++ )
				{
					printf("  |");
				}

				printf( has_children ? "  |" : "   ");

				string value_string = value->get_as_string();

				printf("   -Attribute:  %s = %s\n", node_endpoint->get_endpoint_definition().get_name().c_str(), value_string.c_str() );
			}
		
			if( has_children )
			{
				dump_state( node->get_children(), indentation + 1 );
			}
		}
	}


	void CServer::dump_state()
	{
		printf("Print State:\n");
		printf("***********:\n\n");
		dump_state( server_->get_nodes(), 0 );
		fflush( stdout );
	}


	internal_id CServer::create_internal_id()
	{
		internal_id id = m_next_internal_id;
		m_next_internal_id ++;
		return id;
	}


	CError CServer::process_command( CCommandApi *command, ntg_command_source command_source, CCommandResult *result )
	{
		assert( command );

		CError error = command->execute( *this, command_source, result );

		delete command;

		return error;
	}


	string CServer::get_libintegra_version() const
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

			GetModuleHandleEx( GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS| 
							GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
							(LPCTSTR) CServerApi::create_server, 
							&module_handle);

			size = GetModuleFileName(module_handle, file_name, _MAX_PATH);
			file_name[size] = 0;
			size = GetFileVersionInfoSize(file_name, &handle);
			version_info = new BYTE[ size ];
			if (!GetFileVersionInfo(file_name, handle, size, version_info))
			{
				NTG_TRACE_ERROR( "Failed to read version number from module" );
				delete[] version_info;

				return "<failed to read version number>";
			}

			// we have version information
			VerQueryValue(version_info, L"\\", (void**)&vsfi, &len);

			ostringstream stream;
			stream << HIWORD( vsfi->dwFileVersionMS ) << ".";
			stream << LOWORD( vsfi->dwFileVersionMS ) << ".";
			stream << HIWORD( vsfi->dwFileVersionLS ) << ".";
			stream << LOWORD( vsfi->dwFileVersionLS );

			return stream.str();

			delete[] version_info;

		#else

			/*non-windows - use version number from preprocessor macro*/
			return string( TOSTRING( LIBINTEGRA_VERSION ) );

		#endif
	}

	
}


