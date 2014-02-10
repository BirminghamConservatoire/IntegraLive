/* libIntegra modular audio framework
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

#include "node.h"
#include "state_table.h"

#include "api/path.h"
#include "api/command_source.h"

#include <semaphore.h>
#include <pthread.h>


namespace integra_api
{
	class CServerStartupInfo;
	class ICommand;
	class CCommandResult;
	class INotificationSink;
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
	class CDspEngine;
	class IAudioEngine;
	class IMidiEngine;
	class CMidiInputDispatcher;


	class CServer : public IServer
	{
		public:

			CServer( const CServerStartupInfo &startup_info );
			~CServer();

			/* lock returns false if can't be locked because already in shutdown */
			bool lock();	
			void unlock();

			const node_map &get_nodes() const { return m_nodes; }
			node_map &get_nodes_writable() { return m_nodes; }

			const INode *find_node( const CPath &path, const INode *relative_to = NULL ) const;
			const CNode *find_node( internal_id id ) const;

			CNode *find_node_writable( const CPath &path, const CNode *relative_to = NULL );

			const node_map &get_siblings( const INode &node ) const;
			node_map &get_sibling_set_writable( CNode &node );

			const INodeEndpoint *find_node_endpoint( const CPath &path, const INode *relative_to = NULL ) const;
			CNodeEndpoint *find_node_endpoint_writable( const CPath &path, const CNode *relative_to = NULL );

			const CValue *get_value( const CPath &path ) const;

			/* exposed in IServer, to process commands from the public api */
			CError process_command( ICommand *command, CCommandResult *result );

			/* internal command processor, to process all commands */
			CError process_command( ICommand *command, CCommandSource source, CCommandResult *result = NULL );

			CStateTable &get_state_table() { return m_state_table;  }

			CReentranceChecker &get_reentrance_checker() const { return *m_reentrance_checker; }

			IModuleManager &get_module_manager() const;

			CDspEngine &get_dsp_engine() const { return *m_dsp_engine; }

			IAudioEngine &get_audio_engine() const { return *m_audio_engine; }
			IMidiEngine &get_midi_engine() const { return *m_midi_engine; }

			CMidiInputDispatcher &get_midi_input_dispatcher() const { return *m_midi_input_dispatcher; }

			const guid_set &get_all_module_ids() const;
			const IInterfaceDefinition *find_interface( const GUID &module_id ) const;

			const string &get_scratch_directory() const;

			CLuaEngine &get_lua_engine() { return *m_lua_engine; }

			CPlayerHandler &get_player_handler() { return *m_player_handler; }

			INotificationSink *get_notification_sink() { return m_notification_sink; }

			internal_id create_internal_id();

			void dump_libintegra_state();
			void dump_dsp_state( const string &file );
			void ping_all_dsp_modules();

			string get_libintegra_version() const;

		private:

			void dump_state( const node_map &nodes, int indentation ) const;

			pthread_mutex_t m_mutex;
			pthread_t m_mutex_owner;

			pthread_mutex_t m_shutdown_mutex;

			node_map m_nodes;
			CStateTable m_state_table; 
			CReentranceChecker *m_reentrance_checker;
			CModuleManager *m_module_manager;
			CScratchDirectory *m_scratch_directory;
			CLuaEngine *m_lua_engine;
			CPlayerHandler *m_player_handler;
			CDspEngine *m_dsp_engine;
			IAudioEngine *m_audio_engine;
			IMidiEngine *m_midi_engine;
			CMidiInputDispatcher *m_midi_input_dispatcher;

			INotificationSink *m_notification_sink;

			internal_id m_next_internal_id; 
	};
}


#endif
