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

#include "path.h"


namespace ntg_internal
{
	class CNode;
	class CServer;

	typedef struct ntg_player_state_ 
	{
		ntg_internal::internal_id id;
		ntg_api::CPath tick_path;
		ntg_api::CPath play_path;
		int rate;
		int initial_ticks;
		int previous_ticks;
		int64_t start_msecs;

		bool loop;
		int loop_start_ticks;
		int loop_end_ticks;

		struct ntg_player_state_ *next;

	} ntg_player_state;


	typedef struct ntg_player_data_
	{
		ntg_player_state *player_states;

		pthread_t thread;
		pthread_mutex_t player_state_mutex;

	#ifdef __APPLE__
		sem_t *sem_player_thread_shutdown;
	#else
		sem_t sem_player_thread_shutdown;
	#endif

	} ntg_player_data;


	void ntg_player_initialize( ntg_internal::CServer &server );
	void ntg_player_free( ntg_internal::CServer &server );

	void ntg_player_update( ntg_internal::CServer &server, ntg_internal::internal_id player_id );

	void ntg_player_handle_path_change( ntg_internal::CServer &server, const ntg_internal::CNode &player_node );
	void ntg_player_handle_delete( ntg_internal::CServer &server, const ntg_internal::CNode &player_node );
}



#endif /*INTEGRA_PLAYER_HANDLER_H*/
