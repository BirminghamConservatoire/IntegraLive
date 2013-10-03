/** libIntegra multimedia module interface
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

#include <unistd.h>

#include "platform_specifics.h"
#include "player_handler.h"
#include "node.h"
#include "node_endpoint.h"
#include "player_logic.h"
#include "server.h"
#include "api/command.h"
#include "api/trace.h"

#include <assert.h>



#ifdef _WINDOWS
#include <windows.h>	/*for Sleep function */
#else
#include <sys/time.h> /* for gettimeofday() */
#endif


namespace integra_internal
{
	/* 
	 hardcoded player update rate of 40hz 
	*/
	const int CPlayerHandler::player_update_microseconds = 25000;

	/* 
	 in case the user updates their clock, or DST starts or ends.  
	 When elapsed time between player updates exceeds this value, clock is reset to avoid jumping around 
	*/
	const int CPlayerHandler::player_sanity_check_seconds = 30;



	CPlayerHandler::CPlayerHandler( CServer &server )
		:	m_server( server )
	{
		pthread_mutex_init( &m_mutex, NULL);

		#ifdef __APPLE__
			m_thread_shutdown_semaphore= sem_open( "sem_player_thread_shutdown" , O_CREAT, 0777, 0 );
		#else
			m_thread_shutdown_semaphore = new sem_t;
			sem_init( m_thread_shutdown_semaphore, 0, 0 );
		#endif

		pthread_create( &m_thread, NULL, player_handler_thread_function, this );
	}


	CPlayerHandler::~CPlayerHandler()
	{
		INTEGRA_TRACE_PROGRESS << "stopping player thread";

		sem_post( m_thread_shutdown_semaphore );
		pthread_join( m_thread, NULL);

		#ifdef __APPLE__
			sem_close( m_thread_shutdown_semaphore );
		#else
			sem_destroy( m_thread_shutdown_semaphore );
			delete m_thread_shutdown_semaphore;
		#endif

		INTEGRA_TRACE_PROGRESS << "freeing player states";

		pthread_mutex_lock( &m_mutex );

		for( player_state_map::iterator i = m_player_states.begin(); i != m_player_states.end(); i++ )
		{
			delete i->second;
		}

		pthread_mutex_unlock( &m_mutex );

		pthread_mutex_destroy( &m_mutex );
	}


	void CPlayerHandler::update( const CNode &player_node )
	{
		const INodeEndpoint *play_endpoint = player_node.get_node_endpoint( CPlayerLogic::endpoint_play );
		const INodeEndpoint *active_endpoint = player_node.get_node_endpoint( CPlayerLogic::endpoint_active );
		const INodeEndpoint *tick_endpoint = player_node.get_node_endpoint( CPlayerLogic::endpoint_tick );
		assert( play_endpoint && active_endpoint && tick_endpoint );

		int play_value = *play_endpoint->get_value();
		int active_value = *active_endpoint->get_value();

		if( play_value == 0 || active_value == 0 )
		{
			stop_player( player_node.get_id() );
			return;
		}

		/*
		lookup player attributes
		*/
		const INodeEndpoint *rate_endpoint = player_node.get_node_endpoint( CPlayerLogic::endpoint_rate );
		const INodeEndpoint *loop_endpoint = player_node.get_node_endpoint( CPlayerLogic::endpoint_loop );
		const INodeEndpoint *start_endpoint = player_node.get_node_endpoint( CPlayerLogic::endpoint_start );
		const INodeEndpoint *end_endpoint = player_node.get_node_endpoint( CPlayerLogic::endpoint_end );

		assert( rate_endpoint && loop_endpoint && start_endpoint && end_endpoint );

		pthread_mutex_lock( &m_mutex );

		/*
		see if the player is already playing
		*/

		CPlayerState *player_state = NULL;

		internal_id player_id = player_node.get_id();
		player_state_map::iterator lookup = m_player_states.find( player_id );
		if( lookup == m_player_states.end() )
		{
			/* create new player if not already playing */
			player_state = new CPlayerState;
			player_state->m_id = player_id;
			m_player_states[ player_id ] = player_state;
		}
		else
		{
			/*this player is already playing - update it*/
			player_state = lookup->second;
		}

		/* recreate paths, in case they have changed */
		player_state->m_tick_path = player_node.get_path();
		player_state->m_tick_path.append_element( CPlayerLogic::endpoint_tick );

		player_state->m_play_path = player_node.get_path();
		player_state->m_play_path.append_element( CPlayerLogic::endpoint_play );

		/*
		setup all other player state fields
		*/

		player_state->m_initial_ticks = *tick_endpoint->get_value(); 
		player_state->m_previous_ticks = player_state->m_initial_ticks; 
		player_state->m_rate = *rate_endpoint->get_value();
		player_state->m_start_msecs = get_current_msecs();

		int loop_value = *loop_endpoint->get_value();
		player_state->m_loop = ( loop_value != 0 );
		player_state->m_loop_start_ticks = *start_endpoint->get_value();
		player_state->m_loop_end_ticks = *end_endpoint->get_value();

		pthread_mutex_unlock( &m_mutex );
	}


	void CPlayerHandler::handle_path_change( const CNode &player_node )
	{
		pthread_mutex_lock( &m_mutex );

		player_state_map::iterator lookup = m_player_states.find( player_node.get_id() );
		if( lookup != m_player_states.end() )
		{
			CPlayerState *player_state = lookup->second;

			player_state->m_tick_path = player_node.get_path();
			player_state->m_tick_path.append_element( CPlayerLogic::endpoint_tick );

			player_state->m_play_path = player_node.get_path();
			player_state->m_play_path.append_element( CPlayerLogic::endpoint_play );
		}

		pthread_mutex_unlock( &m_mutex );	
	}


	void CPlayerHandler::handle_delete( const CNode &player_node )
	{
		stop_player( player_node.get_id() );
	}


	void CPlayerHandler::stop_player( internal_id player_id )
	{
		pthread_mutex_lock( &m_mutex );

		player_state_map::iterator lookup = m_player_states.find( player_id );
		if( lookup != m_player_states.end() )
		{
			CPlayerState *player_state = lookup->second;

			delete player_state;

			m_player_states.erase( player_id );
		}

		pthread_mutex_unlock( &m_mutex );	
	}


	int64_t CPlayerHandler::get_current_msecs() const
	{
		#ifdef _WINDOWS

			assert( CLOCKS_PER_SEC == 1000 );
			return clock();

		#else

			struct timeval time_data;
	
			gettimeofday( &time_data, NULL );

			int64_t result = time_data.tv_sec;
			result *= 1000;
	
			result += ( time_data.tv_usec / 1000 );
	
			return result;

		#endif	
	}


	void CPlayerHandler::thread_function()
	{
		while( sem_trywait( m_thread_shutdown_semaphore ) < 0 ) 
		{
			usleep( CPlayerHandler::player_update_microseconds );

			std::list<ISetCommand *> commands;

			pthread_mutex_lock( &m_mutex );

			int64_t current_msecs = get_current_msecs();

			for( player_state_map::const_iterator i = m_player_states.begin(); i != m_player_states.end(); i++ )
			{
				CPlayerState *player_state = i->second;
				int player_rate = player_state->m_rate;
				int elapsed_ticks = ( current_msecs - player_state->m_start_msecs ) * player_rate / 1000;
			
				int new_tick_value = player_state->m_initial_ticks + elapsed_ticks;

				if( abs( new_tick_value - player_state->m_previous_ticks ) > player_sanity_check_seconds * player_rate )
				{
					/* special case to handle unusual number of elapsed ticks - for example when clocks go forward or back */
					player_state->m_start_msecs = current_msecs - ( player_state->m_previous_ticks - player_state->m_initial_ticks ) * 1000 / player_rate; 
					new_tick_value = player_state->m_previous_ticks;
				}
		
				if( new_tick_value >= player_state->m_loop_end_ticks && player_state->m_loop_end_ticks > 0 )
				{
					if( player_state->m_loop )
					{
						int loop_duration = ( player_state->m_loop_end_ticks - player_state->m_loop_start_ticks );
						if( loop_duration > 0 )
						{
							new_tick_value = ( new_tick_value - player_state->m_loop_start_ticks ) % loop_duration + player_state->m_loop_start_ticks;
						}
					}
					else
					{
						commands.push_back( ISetCommand::create( player_state->m_play_path, &CIntegerValue( 0 ) ) );
					}
				}

				if( new_tick_value != player_state->m_previous_ticks )
				{
					commands.push_back( ISetCommand::create( player_state->m_tick_path, &CIntegerValue( new_tick_value ) ) );
					player_state->m_previous_ticks = new_tick_value;
				}
			}

			pthread_mutex_unlock( &m_mutex );

			if( !commands.empty() )
			{
				m_server.lock();
				for( std::list<ISetCommand *>::const_iterator i = commands.begin(); i != commands.end(); i++ )
				{
					m_server.process_command( *i, CCommandSource::SYSTEM );
				}
				m_server.unlock();
			}
		}
	}


	CPlayerHandler::CPlayerState::CPlayerState()
	{
		m_id = 0;
		m_rate = 0;
		m_initial_ticks = 0;
		m_previous_ticks = 0;
		m_start_msecs = 0;

		m_loop = 0;
		m_loop_start_ticks = false;
		m_loop_end_ticks = false;
	}


	void *player_handler_thread_function( void *context )
	{
		CPlayerHandler *player_handler = static_cast< CPlayerHandler * > ( context );
		player_handler->thread_function();

		return NULL;
	}
}
