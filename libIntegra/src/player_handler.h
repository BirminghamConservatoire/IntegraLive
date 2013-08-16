/* libIntegra multimedia module interface
 *  
 * Copyright (C) 2012 Birmingham City University
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

#ifndef INTEGRA_PLAYER_HANDLER_H
#define INTEGRA_PLAYER_HANDLER_H

#include "api/common_typedefs.h"

#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>

#include "api/path.h"
#include "node.h"

using namespace integra_api;


namespace integra_internal
{
	class CNode;
	class CServer;

	class CPlayerHandler
	{
		public:
			CPlayerHandler( CServer &server );
			~CPlayerHandler();

			void update( const CNode &player_node );

			void handle_path_change( const CNode &player_node );
			void handle_delete( const CNode &player_node );

		private:

			friend void *player_handler_thread_function( void *context );

			void thread_function();

			void stop_player( internal_id player_id );
			int64_t get_current_msecs() const;


			class CPlayerState 
			{
				public:
					CPlayerState();

					integra_internal::internal_id m_id;
					CPath m_tick_path;
					CPath m_play_path;
					int m_rate;
					int m_initial_ticks;
					int m_previous_ticks;
					int64_t m_start_msecs;

					bool m_loop;
					int m_loop_start_ticks;
					int m_loop_end_ticks;
			};

			typedef std::unordered_map<internal_id, CPlayerState *> player_state_map;

			player_state_map m_player_states;

			pthread_t m_thread;
			pthread_mutex_t m_mutex;

			sem_t *m_thread_shutdown_semaphore;

			CServer &m_server;

			static const int player_update_microseconds;
			static const int player_sanity_check_seconds;
	};
}



#endif /*INTEGRA_PLAYER_HANDLER_H*/
