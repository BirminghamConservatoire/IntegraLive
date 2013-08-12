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

#include "platform_specifics.h"

#include "player_logic.h"
#include "scene_logic.h"
#include "server.h"
#include "node.h"
#include "node_endpoint.h"
#include "trace.h"
#include "interface_definition.h"
#include "player_handler.h"
#include "api/command_api.h"

#include <assert.h>


namespace ntg_internal
{
	const string CPlayerLogic::endpoint_play = "play";
	const string CPlayerLogic::endpoint_tick = "tick";
	const string CPlayerLogic::endpoint_start = "start";
	const string CPlayerLogic::endpoint_end = "end";
	const string CPlayerLogic::endpoint_loop = "loop";
	const string CPlayerLogic::endpoint_rate = "rate";
	const string CPlayerLogic::endpoint_scene = "scene";
	const string CPlayerLogic::endpoint_next = "next";
	const string CPlayerLogic::endpoint_prev = "prev";



	CPlayerLogic::CPlayerLogic( const CNode &node )
		:	CLogic( node )
	{
	}


	CPlayerLogic::~CPlayerLogic()
	{
	}


	void CPlayerLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source )
	{
		CLogic::handle_set( server, node_endpoint, previous_value, source );

		const string &endpoint_name = node_endpoint.get_endpoint_definition().get_name();
	
		if( endpoint_name == endpoint_active || 
			endpoint_name == endpoint_play ||
			endpoint_name == endpoint_loop ||
			endpoint_name == endpoint_start ||
			endpoint_name == endpoint_end )
		{
			server.get_player_handler().update( get_node() );
			return;
		}

		if( endpoint_name == endpoint_tick )
		{
			if( source != CCommandSource::SYSTEM )
			{
				server.get_player_handler().update( get_node() );
			}
			return;
		}

		if( endpoint_name == endpoint_scene )
		{
			scene_handler( server );
			return;
		}

		if( endpoint_name == endpoint_next )
		{
			next_handler( server );
			return;
		}

		if( endpoint_name == endpoint_prev )
		{
			prev_handler( server );
			return;
		}
	}


	void CPlayerLogic::handle_rename( CServer &server, const string &previous_name, CCommandSource source )
	{
		CLogic::handle_rename( server, previous_name, source );

		server.get_player_handler().handle_path_change( get_node() );
	}


	void CPlayerLogic::handle_move( CServer &server, const CPath &previous_path, CCommandSource source )
	{
		CLogic::handle_move( server, previous_path, source );

		server.get_player_handler().handle_path_change( get_node() );
	}


	void CPlayerLogic::handle_delete( CServer &server, CCommandSource source )
	{
		CLogic::handle_delete( server, source );

		server.get_player_handler().handle_delete( get_node() );
	}


	void CPlayerLogic::update_on_activation( CServer &server )
	{
		CLogic::update_on_activation( server );

		const CNodeEndpoint *tick = get_node().get_node_endpoint( endpoint_tick );
		assert( tick );

		server.process_command( CSetCommandApi::create( tick->get_path(), tick->get_value() ), CCommandSource::SYSTEM );
	}


	void CPlayerLogic::update_on_path_change( CServer &server )
	{
		CLogic::update_on_path_change( server );

		server.get_player_handler().handle_path_change( get_node() );
	}


	void CPlayerLogic::scene_handler( CServer &server )
	{
		/* defaults for values to copy into the player.  The logic below updates these variables */

		int tick = -1;
		int play = 0;
		int loop = 0;
		int start = -1;
		int end = -1;

		/* handle scene selection */
		const CNode &player_node = get_node();
		const CNodeEndpoint *scene_endpoint = player_node.get_node_endpoint( endpoint_scene );
		assert( scene_endpoint );
		string scene_name = *scene_endpoint->get_value();

		const CNode *scene_node = player_node.get_child( scene_name );
		if( !scene_node )	
		{
			if( !scene_name.empty() )
			{
				NTG_TRACE_ERROR << "Player doesn't have scene " << scene_name;
				return;
			}
		}
		else
		{
			if( !dynamic_cast< const CSceneLogic * > ( &scene_node->get_logic() ) )
			{
				NTG_TRACE_ERROR << "Object referred to by player's scene endpoint is not a scene!";
				return;
			}

			const CNodeEndpoint *scene_start_endpoint = scene_node->get_node_endpoint( CSceneLogic::endpoint_start );
			const CNodeEndpoint *scene_length_endpoint = scene_node->get_node_endpoint( CSceneLogic::endpoint_length );
			const CNodeEndpoint *scene_mode_endpoint = scene_node->get_node_endpoint( CSceneLogic::endpoint_mode );
			assert( scene_start_endpoint && scene_length_endpoint && scene_mode_endpoint );

			string scene_mode = *scene_mode_endpoint->get_value();

			start = *scene_start_endpoint->get_value();
			int length = *scene_length_endpoint->get_value();
			end = start + length;
			tick = start;

			if( scene_mode == CSceneLogic::scene_mode_play )
			{
				play = 1;
			}
			else
			{
				if( scene_mode == CSceneLogic::scene_mode_loop )
				{
					play = 1;
					loop = 1;
				}
				else
				{
					assert( scene_mode == CSceneLogic::scene_mode_hold );
				}
			}
		}

		update_player( server, tick, play, loop, start, end );
	}


	void CPlayerLogic::next_handler( CServer &server )
	{
		const CNode &player_node = get_node();

		/* find selected scene start*/
		const CNodeEndpoint *scene_endpoint = player_node.get_node_endpoint( endpoint_scene );
		const CNodeEndpoint *tick_endpoint = player_node.get_node_endpoint( endpoint_tick );
		assert( scene_endpoint && tick_endpoint );

		int player_tick = *tick_endpoint->get_value();
	
		const CNode *selected_scene = NULL;
		const CNodeEndpoint *scene_start_endpoint = NULL;

		const string &selected_scene_name = *scene_endpoint->get_value();

		if( !selected_scene_name.empty() )
		{
			selected_scene = player_node.get_child( selected_scene_name );
			if( selected_scene )
			{
				scene_start_endpoint = selected_scene->get_node_endpoint( endpoint_start );
			}
		}

		/* iterate through scenes looking for next scene */
		const string *next_scene_name = NULL;
		int best_scene_start;
		int search_scene_start;

		const node_map &scenes = player_node.get_children();
		for( node_map::const_iterator i = scenes.begin(); i != scenes.end(); i++ )
		{
			const CNode *search_scene = i->second;
			if( !dynamic_cast< const CSceneLogic *> ( &search_scene->get_logic() ) )
			{
				NTG_TRACE_ERROR << "Object other than scene in player";
				continue;
			}

			if( search_scene != selected_scene )
			{
				const CNodeEndpoint *start_endpoint = search_scene->get_node_endpoint( endpoint_start );
				assert( start_endpoint );
				search_scene_start = *start_endpoint->get_value();

				if( search_scene_start >= player_tick )
				{
					if( !next_scene_name || search_scene_start < best_scene_start )
					{
						next_scene_name = &search_scene->get_name();
						best_scene_start = search_scene_start;
					}
				}
			}
		}

		if( next_scene_name )
		{
			server.process_command( CSetCommandApi::create( scene_endpoint->get_path(), &CStringValue( *next_scene_name ) ), CCommandSource::SYSTEM );
		}
	}


	void CPlayerLogic::prev_handler( CServer &server )
	{
		const CNode &player_node = get_node();

		/* find selected scene start*/
		const CNodeEndpoint *scene_endpoint = player_node.get_node_endpoint( endpoint_scene );
		const CNodeEndpoint *tick_endpoint = player_node.get_node_endpoint( endpoint_tick );
		assert( scene_endpoint && tick_endpoint );

		int player_tick = *tick_endpoint->get_value();
	
		const CNode *selected_scene = NULL;
		const CNodeEndpoint *scene_start_endpoint = NULL;

		const string &selected_scene_name = *scene_endpoint->get_value();

		if( !selected_scene_name.empty() )
		{
			selected_scene = player_node.get_child( selected_scene_name );
			if( selected_scene )
			{
				scene_start_endpoint = selected_scene->get_node_endpoint( endpoint_start );
			}
		}

		/* iterate through scenes looking for prev scene */
		const string *next_scene_name = NULL;
		int best_scene_start;
		int search_scene_start;

		const node_map &scenes = player_node.get_children();
		for( node_map::const_iterator i = scenes.begin(); i != scenes.end(); i++ )
		{
			const CNode *search_scene = i->second;
			if( !dynamic_cast< const CSceneLogic *> ( &search_scene->get_logic() ) )
			{
				NTG_TRACE_ERROR << "Object other than scene in player";
				continue;
			}

			if( search_scene != selected_scene )
			{
				const CNodeEndpoint *start_endpoint = search_scene->get_node_endpoint( endpoint_start );
				assert( start_endpoint );
				search_scene_start = *start_endpoint->get_value();

				if( search_scene_start < player_tick )
				{
					if( !next_scene_name || search_scene_start > best_scene_start )
					{
						next_scene_name = &search_scene->get_name();
						best_scene_start = search_scene_start;
					}
				}
			}
		}

		if( next_scene_name )
		{
			server.process_command( CSetCommandApi::create( scene_endpoint->get_path(), &CStringValue( *next_scene_name ) ), CCommandSource::SYSTEM );
		}	
	}


	void CPlayerLogic::update_player( CServer &server, int tick, int play, int loop, int start, int end )
	{
		/*
		updates player state.  ignores tick when < 0
		*/

		const CNode &player_node = get_node();

		/* look up the player endpoints to set */
		const CNodeEndpoint *player_tick_endpoint = player_node.get_node_endpoint( endpoint_tick );
		const CNodeEndpoint *player_play_endpoint = player_node.get_node_endpoint( endpoint_play );
		const CNodeEndpoint *player_loop_endpoint = player_node.get_node_endpoint( endpoint_loop );
		const CNodeEndpoint *player_start_endpoint = player_node.get_node_endpoint( endpoint_start );
		const CNodeEndpoint *player_end_endpoint = player_node.get_node_endpoint( endpoint_end );

		assert( player_tick_endpoint && player_play_endpoint && player_loop_endpoint && player_start_endpoint && player_end_endpoint );

		/* 
		Set the new values.  
		Order is important here as the player will set play = false when loop == false and tick > end 
		We can prevent this from being a problem by setting tick after start & end, and setting play last
		*/

		server.process_command( CSetCommandApi::create( player_loop_endpoint->get_path(), &CIntegerValue( loop ) ), CCommandSource::SYSTEM );
		server.process_command( CSetCommandApi::create( player_start_endpoint->get_path(), &CIntegerValue( start ) ), CCommandSource::SYSTEM );
		server.process_command( CSetCommandApi::create( player_end_endpoint->get_path(), &CIntegerValue( end ) ), CCommandSource::SYSTEM );

		/* don't set tick unless >= 0.  Allows calling functions to skip setting tick */
		if( tick >= 0 )
		{
			server.process_command( CSetCommandApi::create( player_tick_endpoint->get_path(), &CIntegerValue( tick ) ), CCommandSource::SYSTEM );
		}

		server.process_command( CSetCommandApi::create( player_play_endpoint->get_path(), &CIntegerValue( play ) ), CCommandSource::SYSTEM );
	}
}
