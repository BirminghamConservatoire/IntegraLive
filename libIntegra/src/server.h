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

#define NTG_RETURN_COMMAND_STATUS command_status.error_code = error_code;return command_status;
#define NTG_RETURN_ERROR_CODE( ERROR_CODE ) command_status.error_code = ERROR_CODE;return command_status;
#define NTG_COMMAND_STATUS_INIT command_status.data = NULL, command_status.error_code = NTG_NO_ERROR;

#include <pthread.h>

#include "api/server_api.h"

#include "Integra/integra_bridge.h"
#include "node.h"
#include "path.h"
#include "state_table.h"
#include "osc_client.h"


#ifndef ntg_system_class_data 
typedef struct ntg_system_class_data_ ntg_system_class_data;
#endif

namespace ntg_api
{
	class CServerStartupInfo;
}


namespace ntg_internal
{
	class CNode;
	class CNodeEndpoint;
	class CReentranceChecker;
	class CModuleManager;

	class CServer : public ntg_api::CServerApi
	{
		public:

			CServer( const ntg_api::CServerStartupInfo &startup_info );
			~CServer();

			void block_until_shutdown_signal();

			void lock();
			void unlock();

			const node_map &get_nodes() const { return m_nodes; }
			node_map &get_nodes_writable() { return m_nodes; }

			const CNode *find_node( const ntg_api::string &path_string, const CNode *relative_to = NULL ) const;
			const CNode *find_node( internal_id id ) const;

			CNode *find_node_writable( const ntg_api::string &path_string, const CNode *relative_to = NULL );

			const node_map &get_sibling_set( const CNode &node ) const;
			node_map &get_sibling_set_writable( CNode &node );

			const CNodeEndpoint *find_node_endpoint( const ntg_api::string &path_string, const CNode *relative_to = NULL ) const;
			CNodeEndpoint *find_node_endpoint_writable( const ntg_api::string &path_string, const CNode *relative_to = NULL );

			ntg_bridge_interface *get_bridge() { return m_bridge; }
			ntg_osc_client *get_osc_client() { return m_osc_client; }
			CStateTable &get_state_table() { return m_state_table;  }

			CReentranceChecker &get_reentrance_checker() const { return *m_reentrance_checker; }

			const CModuleManager &get_module_manager() const { return *m_module_manager; }
			CModuleManager &get_module_manager_writable() { return *m_module_manager; }

			struct ntg_system_class_data_ *get_system_class_data() { return m_system_class_data; }
			void set_system_class_data( struct ntg_system_class_data_ *data ) { m_system_class_data = data; }

			const ntg_api::string &scratch_directory_root() const { return m_scratch_directory_root; }
			ntg_api::string &scratch_directory_root_writable() { return m_scratch_directory_root; }

			bool get_terminate_flag() const { return m_terminate; }

		private:

			pthread_mutex_t m_mutex;

			node_map m_nodes;
			ntg_bridge_interface *m_bridge;
			ntg_osc_client *m_osc_client;
			CStateTable m_state_table; 
			CReentranceChecker *m_reentrance_checker;
			CModuleManager *m_module_manager;
			struct ntg_system_class_data_ *m_system_class_data;
			ntg_api::string m_scratch_directory_root;

			pthread_t m_xmlrpc_thread;

			bool m_terminate;
	};
}

#if 0 //Deprecated


/** \brief Definition of the type ntg_server. @see Integra/integra.h */
typedef struct ntg_server_ {
	ntg_internal::node_map root_nodes;
    ntg_bridge_interface *bridge;
    struct ntg_osc_client_ *osc_client;
	ntg_internal::CStateTable state_table; 
	ntg_internal::CReentranceChecker *reentrance_checker;
	ntg_internal::CModuleManager *module_manager;
    struct ntg_system_class_data_ *system_class_data;
    char *scratch_directory_root;
    bool terminate;
    bool loading;
} ntg_server;

void ntg_server_halt(ntg_server *server);

ntg_server *ntg_server_new(const char *osc_client_url, unsigned short osc_client_port, const char *system_module_directory, const char *third_party_module_directory );
void ntg_server_free(ntg_server *server);




/** \brief Callback function corresponing to ih_callback in the bridge interface (see integra_bridge.h ntg_bridge_interface->ih_callback */
void ntg_server_receive_from_host(ntg_id id, const char *attribute_name, const ntg_api::CValue *value);


/** \brief Update a connection 
    \param do_connect Toggles the connection 0 = disconnect 1 = connec
 */
ntg_error_code ntg_server_connect_in_host( ntg_server *server, const ntg_internal::CNodeEndpoint *source, 
											const ntg_internal::CNodeEndpoint *target, bool connect );



const ntg_internal::CNodeEndpoint *ntg_find_node_endpoint( const ntg_api::string &path_string, const ntg_internal::CNode *relative_to = NULL );
ntg_internal::CNodeEndpoint *ntg_find_node_endpoint_writable( const ntg_api::string &path_string, const ntg_internal::CNode *relative_to = NULL );

const ntg_internal::CNode *ntg_find_node( const ntg_api::string &path_string, const ntg_internal::CNode *relative_to = NULL );
const ntg_internal::CNode *ntg_find_node( ntg_id id );

ntg_internal::CNode *ntg_find_node_writable( const ntg_api::string &path_string, const ntg_internal::CNode *relative_to = NULL );

const ntg_internal::node_map &ntg_get_sibling_set( ntg_server *server, const ntg_internal::CNode &node );
ntg_internal::node_map &ntg_get_sibling_set_writable( ntg_server *server, ntg_internal::CNode &node );



void ntg_server_set_host_dsp(const ntg_server *server, bool status);

bool ntg_saved_version_is_newer_than_current( const char *saved_version );

void ntg_lock_server(void);
void ntg_unlock_server(void);



/** \brief Terminate the server and cleanup */
LIBINTEGRA_API void ntg_terminate(void);

#endif

#endif
