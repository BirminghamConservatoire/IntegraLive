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

#include <libxml/xmlreader.h>

#include "server.h"
#include "scratch_directory.h"
#include "osc_client.h"
#include "reentrance_checker.h"
#include "module_manager.h"
#include "api/trace.h"
#include "xmlrpc_server.h"
#include "api/value.h"
#include "api/path.h"
#include "bridge_host.h"
#include "api/guid_helper.h"
#include "lua_engine.h"
#include "player_handler.h"

#include "api/server_startup_info.h"
#include "api/command.h"

#include <assert.h>
#include <iostream>


namespace integra_internal
{
	#ifdef _WINDOWS
		static void invalid_parameter_handler( const wchar_t * expression, const wchar_t * function, const wchar_t * file, unsigned int line, uintptr_t pReserved )
		{
			INTEGRA_TRACE_ERROR << "CRT encoutered invalid parameter!";
		}
	#endif


	
	static void host_callback( internal_id id, const char *attribute_name, const CValue *value, void *context )
	{
		CServer *server = ( CServer * ) context;

		if( server->is_in_shutdown() ) 
		{
			return;
		}

		server->lock();

		const CNode *target = server->find_node( id );
		if( target ) 
		{
			CPath path( target->get_path() );
			path.append_element( attribute_name );

			server->process_command( ISetCommand::create( path, value ), CCommandSource::HOST );
		}
		else
		{
			INTEGRA_TRACE_ERROR << "couldn't find node with id " << id;
		}

		server->unlock();
	}


	CServer::CServer( const CServerStartupInfo &startup_info )
	{
		INTEGRA_TRACE_PROGRESS << "libIntegra version " << get_libintegra_version();

		pthread_mutex_init( &m_mutex, NULL );
		memset( &m_mutex_owner, 0, sizeof( pthread_t ) );

		#ifdef _WINDOWS
			_set_invalid_parameter_handler( invalid_parameter_handler );
		#endif

		m_sem_xmlrpc_initialized = create_semaphore( "sem_xmlrpc_initialized" );
		m_sem_system_shutdown = create_semaphore( "sem_system_shutdown" );

		m_next_internal_id = 0;

		m_scratch_directory = new CScratchDirectory;

		m_lua_engine = new CLuaEngine;

		m_player_handler = new CPlayerHandler( *this );

		m_module_manager = new CModuleManager( *this, startup_info.system_module_directory, startup_info.third_party_module_directory );

		m_osc_client = ntg_osc_client_new( startup_info.osc_client_url.c_str(), startup_info.osc_client_port );
		m_is_in_shutdown = false;

		m_reentrance_checker = new CReentranceChecker();

		m_bridge = ( ntg_bridge_interface * ) ntg_bridge_load( startup_info.bridge_path.c_str() );
		if( m_bridge ) 
		{
			m_bridge->bridge_init();
		} 
		else 
		{
			INTEGRA_TRACE_ERROR << "bridge failed to load";
		}

		/* Add the server receive callback to the bridge's methods */
		m_bridge->server_receive_callback = host_callback;
		m_bridge->server_receive_callback_context = this;

		/* create the xmlrpc interface */
		CXmlRpcServerContext *context = new CXmlRpcServerContext;
		context->m_server = this;
		context->m_port = startup_info.xmlrpc_server_port;
		context->m_sem_initialized = m_sem_xmlrpc_initialized;
		pthread_create( &m_xmlrpc_thread, NULL, ntg_xmlrpc_server_run, context );

		INTEGRA_TRACE_PROGRESS << "Server construction complete";
	}


	CServer::~CServer()
	{
		INTEGRA_TRACE_PROGRESS << "setting terminate flag";

		lock();
		m_is_in_shutdown = true;

		/* delete all nodes */
		node_map copy_of_nodes = m_nodes;
		for( node_map::const_iterator i = copy_of_nodes.begin(); i != copy_of_nodes.end(); i++ )
		{
			process_command( IDeleteCommand::create( i->second->get_path() ), CCommandSource::SYSTEM );
		}
	
		/* de-reference bridge */
	    m_bridge = NULL;

		delete m_module_manager;

		delete m_reentrance_checker;

		delete m_scratch_directory;

		delete m_lua_engine;

		delete m_player_handler;

		INTEGRA_TRACE_PROGRESS << "shutting down OSC client";
		ntg_osc_client_destroy( m_osc_client );
		
		INTEGRA_TRACE_PROGRESS << "shutting down XMLRPC interface";
		ntg_xmlrpc_server_terminate( m_sem_xmlrpc_initialized );

		/* FIX: for now we only support the old 'stable' xmlrpc-c, which can't
		   wake up a sleeping server */
		INTEGRA_TRACE_PROGRESS << "joining xmlrpc thread";
		pthread_join( m_xmlrpc_thread, NULL );



		/* FIX: This hangs on all platforms, just comment out for now */
		/*
		INTEGRA_TRACE_PROGRESS("closing bridge");
		dlclose(bridge_handle);
		*/

		INTEGRA_TRACE_PROGRESS << "cleaning up XML parser";
		xmlCleanupParser();
		xmlCleanupGlobals();


		INTEGRA_TRACE_PROGRESS << "done!";

		destroy_semaphore( m_sem_xmlrpc_initialized );
		destroy_semaphore( m_sem_system_shutdown );

		unlock();

		pthread_mutex_destroy( &m_mutex );

		INTEGRA_TRACE_PROGRESS << "server destruction complete";
	}


	void CServer::block_until_shutdown_signal()
	{
		INTEGRA_TRACE_PROGRESS << "server blocking until shutdown signal...";

		sem_wait( m_sem_system_shutdown );

		INTEGRA_TRACE_PROGRESS << "server blocking finished...";
	}


	void CServer::lock()
	{
		pthread_t current_thread = pthread_self();
		if( memcmp( &current_thread, &m_mutex_owner, sizeof( pthread_t ) ) == 0 )
		{
			INTEGRA_TRACE_ERROR << "Attempt to lock server in thread which has already locked it!  Deadlock!";
			assert( false );
		}

	    pthread_mutex_lock( &m_mutex );
		m_mutex_owner = current_thread;
	}


	void CServer::unlock()
	{
		memset( &m_mutex_owner, 0, sizeof( pthread_t ) );
		pthread_mutex_unlock( &m_mutex );
	}


	const INode *CServer::find_node( const string &path_string, const INode *relative_to ) const
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


	const node_map &CServer::get_siblings( const INode &node ) const
	{
		const INode *parent = node.get_parent();
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


	const INodeEndpoint *CServer::find_node_endpoint( const string &path_string, const INode *relative_to ) const
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
		const INodeEndpoint *node_endpoint = find_node_endpoint( path.get_string() );
		
		return node_endpoint ? node_endpoint->get_value() : NULL;
	}


	const string &CServer::get_scratch_directory() const
	{
		return m_scratch_directory->get_scratch_directory();
	}


	IModuleManager &CServer::get_module_manager() const
	{
		return *m_module_manager;
	}


	const guid_set &CServer::get_all_module_ids() const
	{
		return m_module_manager->get_all_module_ids();
	}


	const IInterfaceDefinition *CServer::find_interface( const GUID &module_id ) const
	{
		return m_module_manager->get_interface_by_module_id( module_id );
	}


	void CServer::dump_state( const node_map &nodes, int indentation ) const 
	{
		for( node_map::const_iterator i = nodes.begin(); i != nodes.end(); i++ )
		{
			const INode *node = i->second;

			for( int i = 0; i < indentation; i++ )
			{
				std::cout << "  |";
			}

			const IInterfaceDefinition &interface_definition = node->get_interface_definition();
			string module_id_string = CGuidHelper::guid_to_string( interface_definition.get_module_guid() );
			std::cout << "  Node: \"" << node->get_name() << "\".\t module name: " << interface_definition.get_interface_info().get_name() << ".\t module id: " << module_id_string << ".\t Path: " << node->get_path().get_string() << std::endl;

			bool has_children = !node->get_children().empty();

			const node_endpoint_map &node_endpoints = node->get_node_endpoints();
			for( node_endpoint_map::const_iterator node_endpoint_iterator = node_endpoints.begin(); node_endpoint_iterator != node_endpoints.end(); node_endpoint_iterator++ )
			{
				const INodeEndpoint *node_endpoint = node_endpoint_iterator->second;
				const CValue *value = node_endpoint->get_value();
				if( !value ) continue;

				for( int i = 0; i < indentation; i++ )
				{
					std::cout << "  |";
				}

				std::cout << ( has_children ? "  |" : "   " );

				string value_string = value->get_as_string();

				std::cout << "   -Attribute:  " << node_endpoint->get_endpoint_definition().get_name() << " = " << value_string << std::endl;
			}
		
			if( has_children )
			{
				dump_state( node->get_children(), indentation + 1 );
			}
		}
	}


	void CServer::dump_state()
	{
		std::cout << std::endl;
		std::cout << "Print State:" << std::endl;
		std::cout << "************" << std::endl;
		std::cout << std::endl;
		dump_state( get_nodes(), 0 );
	}


	internal_id CServer::create_internal_id()
	{
		internal_id id = m_next_internal_id;
		m_next_internal_id ++;
		return id;
	}


	CError CServer::process_command( ICommand *command, CCommandSource command_source, CCommandResult *result )
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
							(LPCTSTR) CTrace::error, 
							&module_handle);

			size = GetModuleFileName(module_handle, file_name, _MAX_PATH);
			file_name[size] = 0;
			size = GetFileVersionInfoSize(file_name, &handle);
			version_info = new BYTE[ size ];
			if (!GetFileVersionInfo(file_name, handle, size, version_info))
			{
				INTEGRA_TRACE_ERROR << "Failed to read version number from module";
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


	sem_t *CServer::create_semaphore( const string &name ) const
	{
		#ifdef __APPLE__
			sem_t *semaphore = sem_open( name.c_str(), O_CREAT, 0777, 0 );
		#else
			sem_t *semaphore = new sem_t;
			sem_init( semaphore, 0, 0 );
		#endif

		return semaphore;
	}


	void CServer::destroy_semaphore( sem_t *semaphore ) const
	{
		#ifdef __APPLE__
			sem_close( semaphore );
		#else
			sem_destroy( semaphore );
		#endif
	}


	void CServer::send_shutdown_signal()
	{
		sem_post( m_sem_system_shutdown );
	}
	
}


