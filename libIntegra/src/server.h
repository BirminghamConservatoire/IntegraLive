/* libIntegra multimedia module interface
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

#ifndef INTEGRA_SERVER_PRIVATE_H
#define INTEGRA_SERVER_PRIVATE_H

#include "api/server.h"

#include "Integra/integra_bridge.h"
#include "node.h"
#include "api/path.h"
#include "state_table.h"
#include "osc_client.h"

#include <semaphore.h>
#include <pthread.h>


namespace integra_api
{
	class CServerStartupInfo;
	class ICommand;
	class CCommandResult;
}

using namespace integra_api;


namespace integra_internal
{
	class CNode;
	class CNodeEndpoint;
	class CReentranceChecker;
	class CModuleManager;
	class CScratchDirectory;
	class CLuaEngine;
	class CPlayerHandler;

	class CServer : public IServer
	{
		public:

			CServer( const CServerStartupInfo &startup_info );
			~CServer();

			void block_until_shutdown_signal();

			void lock();
			void unlock();

			const node_map &get_nodes() const { return m_nodes; }
			node_map &get_nodes_writable() { return m_nodes; }

			const INode *find_node( const string &path_string, const INode *relative_to = NULL ) const;
			const CNode *find_node( internal_id id ) const;

			CNode *find_node_writable( const string &path_string, const CNode *relative_to = NULL );

			const node_map &get_siblings( const INode &node ) const;
			node_map &get_sibling_set_writable( CNode &node );

			const INodeEndpoint *find_node_endpoint( const string &path_string, const INode *relative_to = NULL ) const;
			CNodeEndpoint *find_node_endpoint_writable( const string &path_string, const CNode *relative_to = NULL );

			const CValue *get_value( const CPath &path ) const;

			CError process_command( ICommand *command, CCommandSource source, CCommandResult *result = NULL );

			ntg_bridge_interface *get_bridge() { return m_bridge; }
			ntg_osc_client *get_osc_client() { return m_osc_client; }
			CStateTable &get_state_table() { return m_state_table;  }

			CReentranceChecker &get_reentrance_checker() const { return *m_reentrance_checker; }

			IModuleManager &get_module_manager() const;

			const guid_set &get_all_module_ids() const;
			const CInterfaceDefinition *find_interface( const GUID &module_id ) const;

			const string &get_scratch_directory() const;

			CLuaEngine &get_lua_engine() { return *m_lua_engine; }

			CPlayerHandler &get_player_handler() { return *m_player_handler; }

			internal_id create_internal_id();

			void dump_state();

			string get_libintegra_version() const;

			void send_shutdown_signal();
			bool is_in_shutdown() const { return m_is_in_shutdown; }

		private:

			void dump_state( const node_map &nodes, int indentation ) const;

			sem_t *create_semaphore( const string &name ) const;
			void destroy_semaphore( sem_t *semaphore ) const;

			pthread_mutex_t m_mutex;
			pthread_t m_mutex_owner;

			node_map m_nodes;
			ntg_bridge_interface *m_bridge;
			ntg_osc_client *m_osc_client;
			CStateTable m_state_table; 
			CReentranceChecker *m_reentrance_checker;
			CModuleManager *m_module_manager;
			CScratchDirectory *m_scratch_directory;
			CLuaEngine *m_lua_engine;
			CPlayerHandler *m_player_handler;

			pthread_t m_xmlrpc_thread;
			sem_t *m_sem_xmlrpc_initialized;

			sem_t *m_sem_system_shutdown;
			bool m_is_in_shutdown;

			internal_id m_next_internal_id; 
	};
}


#endif
