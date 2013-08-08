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
#include "value.h"

namespace ntg_api
{
	class CPath;
}


namespace ntg_internal
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

			virtual void handle_new( CServer &server, ntg_command_source source );
			virtual void handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const ntg_api::CValue *previous_value, ntg_command_source source );
			virtual void handle_rename( CServer &server, const ntg_api::string &previous_name, ntg_command_source source );
			virtual void handle_move( CServer &server, const ntg_api::CPath &previous_path, ntg_command_source source );
			virtual void handle_delete( CServer &server, ntg_command_source source );

			bool node_is_active() const;
			bool should_copy_input_file( const CNodeEndpoint &input_file, ntg_command_source source ) const;
			bool has_data_directory() const;
			const ntg_api::string *get_data_directory() const;

			virtual void update_on_activation( CServer &server ) {}

		protected:

			const CNode &get_node() const { return m_node; }

			bool are_all_ancestors_active() const;

			static const ntg_api::string s_endpoint_active;
			static const ntg_api::string s_endpoint_data_directory; 
			static const ntg_api::string s_endpoint_source_path;
			static const ntg_api::string s_endpoint_target_path;

		private:

			void non_container_active_initializer( CServer &server );
			void data_directory_handler( CServer &server, const CNodeEndpoint &node_endpoint, const ntg_api::CValue *previous_value, ntg_command_source source );
			void handle_input_file( CServer &server, const CNodeEndpoint &input_file );
			void handle_connections( CServer &server, const CNode &search_node, const CNodeEndpoint &changed_endpoint );

			void quantize_to_allowed_states( ntg_api::CValue &value, const ntg_api::value_set &allowed_states ) const;

			const GUID &get_connection_interface_guid( CServer &server );

			const CNode &m_node;

			/* store a cache of connection's guid since we refer to it very often, to prevent multiple lookups */
			GUID m_connection_interface_guid;

			static const ntg_api::string s_module_container;
			static const ntg_api::string s_module_script;
			static const ntg_api::string s_module_scaler;
			static const ntg_api::string s_module_control_point;
			static const ntg_api::string s_module_envelope;
			static const ntg_api::string s_module_player;
			static const ntg_api::string s_module_scene;
			static const ntg_api::string s_module_connection;

	};
}



#endif /*INTEGRA_NEW_COMMAND_PRIVATE*/