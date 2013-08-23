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


#ifndef INTEGRA_LOGIC_PRIVATE
#define INTEGRA_LOGIC_PRIVATE

#include "api/common_typedefs.h"
#include "api/value.h"
#include "api/error.h"
#include "api/command_source.h"


using namespace integra_api;

namespace integra_api
{
	class CPath;
	class INode;
	class INodeEndpoint;
}



namespace integra_internal
{
	class CNode;
	class CNodeEndpoint;
	class CServer;


	class CLogic 
	{
		protected:
			CLogic( const CNode &node );

		public:

			static CLogic *create( const CNode &node );

			virtual ~CLogic();

			virtual void handle_new( CServer &server, CCommandSource source );
			virtual void handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source );
			virtual void handle_rename( CServer &server, const string &previous_name, CCommandSource source );
			virtual void handle_move( CServer &server, const CPath &previous_path, CCommandSource source );
			virtual void handle_delete( CServer &server, CCommandSource source );

			bool node_is_active() const;
			bool should_copy_input_file( const CNodeEndpoint &input_file, CCommandSource source ) const;
			bool has_data_directory() const;
			const string *get_data_directory() const;

			virtual void update_on_activation( CServer &server ) {}
			virtual void update_on_path_change( CServer &server );

		protected:

			const CNode &get_node() const { return m_node; }

			bool are_all_ancestors_active() const;

			CError connect_audio_in_host( CServer &server, const INodeEndpoint &source, const INodeEndpoint &target, bool connect );

			static const string endpoint_active;
			static const string endpoint_data_directory; 
			static const string endpoint_source_path;
			static const string endpoint_target_path;

		private:

			void non_container_active_initializer( CServer &server );
			void data_directory_handler( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source );
			void handle_input_file( CServer &server, const CNodeEndpoint &input_file );
			void handle_connections( CServer &server, const CNode &search_node, const CNodeEndpoint &changed_endpoint );

			void quantize_to_allowed_states( CValue &value, const value_set &allowed_states ) const;

			void update_connection_path_on_rename( CServer &server, const CNodeEndpoint &connection_path, const string &previous_name, const string &new_name );
			void update_connections_on_rename( CServer &server, const CNode &search_node, const string &previous_name, const string &new_name );

			void update_connections_on_move( CServer &server, const CNode &search_node, const CPath &previous_path, const CPath &new_path );
			void update_connection_path_on_move( CServer &server, const CNodeEndpoint &connection_path, const CPath &previous_path, const CPath &new_path );

			const GUID &get_connection_interface_guid( CServer &server );

			const CNode &m_node;

			/* store a cache of connection's guid since we refer to it very often, to prevent multiple lookups */
			GUID m_connection_interface_guid;

			static const string module_container;
			static const string module_script;
			static const string module_scaler;
			static const string module_control_point;
			static const string module_envelope;
			static const string module_player;
			static const string module_scene;
			static const string module_connection;
			static const string module_audio_settings;

	};
}



#endif /*INTEGRA_LOGIC_PRIVATE*/