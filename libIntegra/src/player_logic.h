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


#ifndef INTEGRA_PLAYER_LOGIC_PRIVATE
#define INTEGRA_PLAYER_LOGIC_PRIVATE

#include "logic.h"


namespace integra_internal
{
	class CPlayerLogic : public CLogic
	{
		friend class CSceneLogic;
		friend class CPlayerHandler;

		public:
			CPlayerLogic( const CNode &node );
			~CPlayerLogic();

			void handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source );
			void handle_rename( CServer &server, const string &previous_name, CCommandSource source );
			void handle_move( CServer &server, const CPath &previous_path, CCommandSource source );
			void handle_delete( CServer &server, CCommandSource source );

		private:

			void update_on_activation( CServer &server );
			void update_on_path_change( CServer &server );

			void scene_handler( CServer &server );
			void next_handler( CServer &server );
			void prev_handler( CServer &server );

			void update_player( CServer &server, int tick, int play, int loop, int start, int end );

			static const string endpoint_play;
			static const string endpoint_tick;
			static const string endpoint_start;
			static const string endpoint_end;
			static const string endpoint_loop;
			static const string endpoint_rate;
			static const string endpoint_scene;
			static const string endpoint_next;
			static const string endpoint_prev;
	};
}



#endif /*INTEGRA_NEW_COMMAND_PRIVATE*/