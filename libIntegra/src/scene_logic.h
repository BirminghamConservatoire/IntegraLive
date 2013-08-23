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


#ifndef INTEGRA_SCENE_LOGIC_PRIVATE
#define INTEGRA_SCENE_LOGIC_PRIVATE

#include "logic.h"

using namespace integra_api;



namespace integra_internal
{
	class CSceneLogic : public CLogic
	{
		friend class CPlayerLogic;

		public:
			CSceneLogic( const CNode &node );
			~CSceneLogic();

			void handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source );
			void handle_rename( CServer &server, const string &previous_name, CCommandSource source );
			void handle_delete( CServer &server, CCommandSource source );

		private:

			void activate_scene( CServer &server );
			void handle_mode( CServer &server, const string &mode );
			void handle_start_and_length( CServer &server );

			bool is_scene_selected() const;


			static const string endpoint_activate;
			static const string endpoint_start;
			static const string endpoint_length;
			static const string endpoint_mode;

			static const string scene_mode_hold;
			static const string scene_mode_play;
			static const string scene_mode_loop;
	};
}



#endif /*INTEGRA_SCENE_LOGIC_PRIVATE*/