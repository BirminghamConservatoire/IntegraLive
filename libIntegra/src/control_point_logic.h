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


#ifndef INTEGRA_CONTROLPOINT_LOGIC_PRIVATE
#define INTEGRA_CONTROLPOINT_LOGIC_PRIVATE

#include "logic.h"


namespace ntg_internal
{
	class CControlPointLogic : public CLogic
	{
		friend class CEnvelopeLogic;

		public:
			CControlPointLogic( const CNode &node );
			~CControlPointLogic();

			void handle_new( CServer &server, ntg_command_source source );
			void handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, ntg_command_source source );
			void handle_move( CServer &server, const CPath &previous_path, ntg_command_source source );
			void handle_delete( CServer &server, ntg_command_source source );

		private:

			void update_envelope( CServer &server, const CNode *envelope_node, bool is_deleting = false );

			static const string s_endpoint_tick;
			static const string s_endpoint_value;
			static const string s_endpoint_curvature;
	};
}



#endif /*INTEGRA_NEW_COMMAND_PRIVATE*/