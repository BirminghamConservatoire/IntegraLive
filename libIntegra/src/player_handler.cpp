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


#include "platform_specifics.h"

#include <pthread.h>
#include <assert.h>
#include <unistd.h>
#include <semaphore.h>

#include "value.h"
#include "player_handler.h"
#include "system_class_literals.h"
#include "system_class_handlers.h"
#include "trace.h"
#include "globals.h"
#include "path.h"
#include "server_commands.h"


#ifdef _WINDOWS
#include <windows.h>	/*for Sleep function */
#else
#include <sys/time.h> /* for gettimeofday() */
#endif

using namespace ntg_api;
using namespace ntg_internal;

/* 
 hardcoded player update rate of 40hz 
 */
#define NTG_PLAYER_UPDATE_MICROSECONDS 25000

/* 
 in case the user updates their clock, or DST starts or ends.  
 When elapsed time between player updates exceeds this value, clock is reset to avoid jumping around 
 */
#define NTG_PLAYER_SANITY_CHECK_SECONDS 30



typedef struct ntg_player_state_ 
{
	internal_id id;
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


void ntg_player_state_free( ntg_player_state *state )
{
	delete state;
}


sem_t *ntg_player_data_get_thread_shutdown_semaphore( ntg_player_data *player_data )
{
#ifdef __APPLE__
	return player_data->sem_player_thread_shutdown;
#else
	return &player_data->sem_player_thread_shutdown;
#endif
}


void ntg_player_set_value( CServer &server, const CPath &attribute, const CValue *value )
{
	server.lock();
	ntg_set_( server, NTG_SOURCE_SYSTEM, attribute, value );
	server.unlock();
}


void ntg_player_stop( CServer &server, internal_id player_id, int final_tick )
{
	/*
	look through player states list, remove state for the first matching player_id found
	nb:assumes there's only one player state per player
	*/

	ntg_player_data *player_data = NULL;
	ntg_player_state *iterator = NULL;
	ntg_player_state **previous = NULL; 

	player_data = server.get_system_class_data()->player_data;

	pthread_mutex_lock(&player_data->player_state_mutex);

	previous = &(player_data->player_states); 

	for( iterator = *previous; iterator; iterator = iterator->next )
	{
		if( iterator->id == player_id )
		{
			/* set final tick */

			if( final_tick != iterator->previous_ticks )
			{
				ntg_player_set_value( server, iterator->tick_path, &CIntegerValue( final_tick ) );
			}

			/* remove and free the player state */

			*previous = iterator->next;

			ntg_player_state_free( iterator );
			break;	

			previous = &(iterator->next);
		}
	}

	pthread_mutex_unlock(&player_data->player_state_mutex);
}


int64_t ntg_get_current_msecs()
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


void *ntg_player_thread( void *context )
{
	ntg_player_state *player = NULL;
	int64_t current_msecs;
	int player_rate;
	int elapsed_ticks;
	int new_tick_value;
	int loop_duration;

	ntg_player_data *player_data = static_cast< ntg_player_data * > ( context );

	while( sem_trywait( ntg_player_data_get_thread_shutdown_semaphore( player_data ) ) < 0 ) 
	{
		usleep( NTG_PLAYER_UPDATE_MICROSECONDS );

		pthread_mutex_lock(&player_data->player_state_mutex);

		current_msecs = ntg_get_current_msecs();

		for( player = player_data->player_states; player; player = player->next )
		{
			player_rate = player->rate;
			elapsed_ticks = ( current_msecs - player->start_msecs ) * player_rate / 1000;
			
			new_tick_value = player->initial_ticks + elapsed_ticks;

			if( abs( new_tick_value - player->previous_ticks ) > NTG_PLAYER_SANITY_CHECK_SECONDS * player_rate )
			{
				/* special case to handle unusual number of elapsed ticks - for example when clocks go forward or back */
				player->start_msecs = current_msecs - ( player->previous_ticks - player->initial_ticks ) * 1000 / player_rate; 
				new_tick_value = player->previous_ticks;
			}
		
			if( new_tick_value >= player->loop_end_ticks && player->loop_end_ticks > 0 )
			{
				if( player->loop )
				{
					loop_duration = ( player->loop_end_ticks - player->loop_start_ticks );
					if( loop_duration > 0 )
					{
						new_tick_value = ( new_tick_value - player->loop_start_ticks ) % loop_duration + player->loop_start_ticks;
					}
				}
				else
				{
					ntg_player_set_value( *server_, player->play_path, &CIntegerValue( 0 ) );
					continue;
				}
			}

			if( new_tick_value != player->previous_ticks )
			{
				ntg_player_set_value( *server_, player->tick_path, &CIntegerValue( new_tick_value ) );
				player->previous_ticks = new_tick_value;
			}
		}

		pthread_mutex_unlock(&player_data->player_state_mutex);
    }

	return NULL;
}


void ntg_player_initialize( CServer &server )
{
	ntg_player_data *player_data = new ntg_player_data;

	player_data->player_states = NULL;

	/*player_data->player_state_mutex = PTHREAD_MUTEX_INITIALIZER;*/
	pthread_mutex_init(&player_data->player_state_mutex, NULL);

#ifdef __APPLE__
    player_data->sem_player_thread_shutdown = sem_open("sem_player_thread_shutdown", O_CREAT, 0777, 0);
#else
	sem_init(&player_data->sem_player_thread_shutdown, 0, 0);
#endif

	pthread_create( &player_data->thread, NULL, ntg_player_thread, player_data);

	server.get_system_class_data()->player_data = player_data;
}


void ntg_player_free( CServer &server )
{
	ntg_player_state *next_state = NULL;
	ntg_player_data *player_data = server.get_system_class_data()->player_data;
	assert( player_data );

    NTG_TRACE_PROGRESS("stopping player thread");

	sem_post( ntg_player_data_get_thread_shutdown_semaphore( player_data ) );
	pthread_join( player_data->thread, NULL);

    NTG_TRACE_PROGRESS("freeing player states");

	pthread_mutex_lock(&player_data->player_state_mutex);

	while( player_data->player_states )
	{
		next_state = player_data->player_states->next;

		ntg_player_state_free( player_data->player_states );

		player_data->player_states = next_state;		
	}

	pthread_mutex_unlock(&player_data->player_state_mutex);

	pthread_mutex_destroy( &player_data->player_state_mutex );

	delete player_data;
}


void ntg_player_update( CServer &server, internal_id player_id )
{
	ntg_player_data *player_data = server.get_system_class_data()->player_data;
	assert( player_data );

	const CNode *player_node = server.find_node( player_id );
	assert( player_node );

	const CNodeEndpoint *play_endpoint = player_node->get_node_endpoint( NTG_ENDPOINT_PLAY );
	const CNodeEndpoint *active_endpoint = player_node->get_node_endpoint( NTG_ENDPOINT_ACTIVE );
	const CNodeEndpoint *tick_endpoint = player_node->get_node_endpoint( NTG_ENDPOINT_TICK );
	assert( play_endpoint && active_endpoint && tick_endpoint );

	int play_value = *play_endpoint->get_value();
	int active_value = *active_endpoint->get_value();

	if( play_value == 0 || active_value == 0 )
	{
		ntg_player_stop( server, player_id, *tick_endpoint->get_value() );
		return;
	}

	/*
	lookup player attributes
	*/
	const CNodeEndpoint *rate_endpoint = player_node->get_node_endpoint( NTG_ENDPOINT_RATE );
	const CNodeEndpoint *loop_endpoint = player_node->get_node_endpoint( NTG_ENDPOINT_LOOP );
	const CNodeEndpoint *start_endpoint = player_node->get_node_endpoint( NTG_ENDPOINT_START );
	const CNodeEndpoint *end_endpoint = player_node->get_node_endpoint( NTG_ENDPOINT_END );

	assert( rate_endpoint && loop_endpoint && start_endpoint && end_endpoint );

	pthread_mutex_lock(&player_data->player_state_mutex);

	/*
	see if the player is already playing
	*/

	ntg_player_state *player_state;
	for( player_state = player_data->player_states; player_state; player_state = player_state->next )
	{
		if( player_state->id == player_id )
		{
			/*this player is already playing - update it*/
			break;
		}
	}

	if( !player_state )
	{
		/* create new player if not already playing */
		player_state = new ntg_player_state;
		player_state->id = player_id;
		player_state->next = player_data->player_states;
		player_data->player_states = player_state;
	}

	/* recreate paths, in case they have changed */
	player_state->tick_path = player_node->get_path();
	player_state->tick_path.append_element( NTG_ENDPOINT_TICK );

	player_state->play_path = player_node->get_path();
	player_state->play_path.append_element( NTG_ENDPOINT_PLAY );

	/*
	setup all other player state fields
	*/

	player_state->initial_ticks = *tick_endpoint->get_value(); 
	player_state->previous_ticks = player_state->initial_ticks; 
	player_state->rate = *rate_endpoint->get_value();
	player_state->start_msecs = ntg_get_current_msecs();

	int loop_value = *loop_endpoint->get_value();
	player_state->loop = ( loop_value != 0 );
	player_state->loop_start_ticks = *start_endpoint->get_value();
	player_state->loop_end_ticks = *end_endpoint->get_value();

	pthread_mutex_unlock( &player_data->player_state_mutex );
}


void ntg_player_handle_path_change( CServer &server, const CNode &player_node )
{
	ntg_player_data *player_data = NULL;
	ntg_player_state *player_state = NULL;

	player_data = server.get_system_class_data()->player_data;
	assert( player_data );

	pthread_mutex_lock( &player_data->player_state_mutex );

	for( player_state = player_data->player_states; player_state; player_state = player_state->next )
	{
		if( player_state->id == player_node.get_id() )
		{
			player_state->tick_path = player_node.get_path();
			player_state->tick_path.append_element( NTG_ENDPOINT_TICK );

			player_state->play_path = player_node.get_path();
			player_state->play_path.append_element( NTG_ENDPOINT_PLAY );
		}
	}

	pthread_mutex_unlock( &player_data->player_state_mutex );
}


void ntg_player_handle_delete( CServer &server, const CNode &player_node )
{
	ntg_player_stop( server, player_node.get_id(), 0 );
}
