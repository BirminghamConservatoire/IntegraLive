 /* libIntegra modular audio framework
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

#include "scene_logic.h"
#include "player_logic.h"

#include "node.h"
#include "node_endpoint.h"
#include "interface_definition.h"
#include "server.h"
#include "api/trace.h"
#include "api/command.h"

#include <assert.h>

namespace integra_internal
{
	const string CSceneLogic::endpoint_activate = "activate";
	const string CSceneLogic::endpoint_start = "start";
	const string CSceneLogic::endpoint_length = "length";
	const string CSceneLogic::endpoint_mode = "mode";

	const string CSceneLogic::scene_mode_hold = "hold";
	const string CSceneLogic::scene_mode_play = "play";
	const string CSceneLogic::scene_mode_loop = "loop";


	CSceneLogic::CSceneLogic( const CNode &node )
		:	CLogic( node )
	{
	}


	CSceneLogic::~CSceneLogic()
	{
	}

	
	void CSceneLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source )
	{
		CLogic::handle_set( server, node_endpoint, previous_value, source );

		const string &endpoint_name = node_endpoint.get_endpoint_definition().get_name();

		if( endpoint_name == endpoint_activate )
		{
			activate_scene( server );
			return;
		}

		if( endpoint_name == endpoint_mode )
		{
			handle_mode( server, *node_endpoint.get_value() );
			return;
		}

		if( endpoint_name == endpoint_start || endpoint_name == endpoint_length )
		{
			handle_start_and_length( server );
			return;
		}
	}


	void CSceneLogic::handle_rename( CServer &server, const string &previous_name, CCommandSource source )
	{
		CLogic::handle_rename( server, previous_name, source );

		/* if this is the selected scene, need to update the player's scene endpoint */

		const CNode &scene_node = get_node();
		const CNode *player_node = CNode::downcast( scene_node.get_parent() );
		if( !player_node || !dynamic_cast< const CPlayerLogic * >( &player_node->get_logic() ) )
		{
			INTEGRA_TRACE_ERROR << "scene not in a player";
			return;
		}

		const INodeEndpoint *scene_endpoint = player_node->get_node_endpoint( CPlayerLogic::endpoint_scene );
		assert( scene_endpoint );

		const string &scene_value = *scene_endpoint->get_value();
		if( scene_value == previous_name )
		{
			server.process_command( ISetCommand::create( scene_endpoint->get_path(), CStringValue( scene_node.get_name() ) ), CCommandSource::SYSTEM );
		}
	}


	void CSceneLogic::handle_delete( CServer &server, CCommandSource source )
	{
		CLogic::handle_delete( server, source );

		/* if this is the selected scene, need to clear the player's scene endpoint */

		const CNode &scene_node = get_node();
		const CNode *player_node = CNode::downcast( scene_node.get_parent() );
		if( !player_node || !dynamic_cast< const CPlayerLogic * >( &player_node->get_logic() ) )
		{
			INTEGRA_TRACE_ERROR << "parent of deleted scene is not a player";
			return;
		}

		const INodeEndpoint *scene_endpoint = player_node->get_node_endpoint( CPlayerLogic::endpoint_scene );
		assert( scene_endpoint );

		const string &scene_value = *scene_endpoint->get_value();
		if( scene_value == scene_node.get_name() ) 
		{
			server.process_command( ISetCommand::create( scene_endpoint->get_path(), CStringValue( "" ) ), CCommandSource::SYSTEM );
		}
	}


	void CSceneLogic::activate_scene( CServer &server )
	{
		const CNode *player_node = CNode::downcast( get_node().get_parent() );
		if( !player_node || !dynamic_cast< const CPlayerLogic * >( &player_node->get_logic() ) )
		{
			INTEGRA_TRACE_ERROR << "scene not inside player";
			return;
		}

		const INodeEndpoint *player_scene_endpoint = player_node->get_node_endpoint( CPlayerLogic::endpoint_scene );
		assert( player_scene_endpoint );

		server.process_command( ISetCommand::create( player_scene_endpoint->get_path(), CStringValue( get_node().get_name() ) ), CCommandSource::SYSTEM );
	}


	void CSceneLogic::handle_mode( CServer &server, const string &mode )
	{
		if( !is_scene_selected() )
		{
			return;
		}

		const CNode &scene_node = get_node();

		const INodeEndpoint *scene_start_endpoint = scene_node.get_node_endpoint( endpoint_start );
		const INodeEndpoint *scene_length_endpoint = scene_node.get_node_endpoint( endpoint_length );
		assert( scene_start_endpoint && scene_length_endpoint );

		int start = *scene_start_endpoint->get_value();
		int length = *scene_length_endpoint->get_value();
		int end = start + length;
		int tick = 0;
		int play = 0;
		int loop = 0;

		if( mode == scene_mode_hold )
		{
			tick = start;
			play = 0;
			loop = 0;
		}
		else
		{
			if( mode == scene_mode_loop )
			{
				loop = 1;
			}
			else
			{
				assert( mode == scene_mode_play );

				loop = 0;
			}

			tick = -1;
			play = 1;
		}

		const CNode *parent_node = CNode::downcast( scene_node.get_parent() );
		if( !parent_node )
		{
			INTEGRA_TRACE_ERROR << "Scene has no parent node";
			return;
		}

		CPlayerLogic *player_logic = dynamic_cast< CPlayerLogic * > ( &parent_node->get_logic() );
		if( !player_logic )
		{
			INTEGRA_TRACE_ERROR << "Scene's parent is not a Player";
			return;
		}

		player_logic->update_player( server, tick, play, loop, start, end );	
	}


	void CSceneLogic::handle_start_and_length( CServer &server )
	{
		if( !is_scene_selected() )
		{
			return;
		}

		const CNode &scene_node = get_node();

		const INodeEndpoint *scene_start = scene_node.get_node_endpoint( endpoint_start );
		const INodeEndpoint *scene_length = scene_node.get_node_endpoint( endpoint_length );

		const INodeEndpoint *player_tick = scene_node.get_parent()->get_node_endpoint( CPlayerLogic::endpoint_tick );
		const INodeEndpoint *player_start = scene_node.get_parent()->get_node_endpoint( CPlayerLogic::endpoint_start );
		const INodeEndpoint *player_end = scene_node.get_parent()->get_node_endpoint( CPlayerLogic::endpoint_end );

		assert( scene_start && scene_length && player_tick && player_start && player_end );

		int start = *scene_start->get_value();
		int length = *scene_length->get_value();
		int end = start + length;

		CIntegerValue player_start_value( start );
		CIntegerValue player_end_value( end );

		server.process_command( ISetCommand::create( player_tick->get_path(), player_start_value ), CCommandSource::SYSTEM );
		server.process_command( ISetCommand::create( player_start->get_path(), player_start_value ), CCommandSource::SYSTEM );
		server.process_command( ISetCommand::create( player_end->get_path(), player_end_value ), CCommandSource::SYSTEM );
	}


	bool CSceneLogic::is_scene_selected() const
	{
		const CNode &scene_node = get_node();
		const CNode *player_node = CNode::downcast( scene_node.get_parent() );
		if( !player_node || !dynamic_cast< const CPlayerLogic * >( &player_node->get_logic() ) )
		{
			INTEGRA_TRACE_ERROR << "Scene is not inside a Player";
			return false;
		}

		const INodeEndpoint *scene_endpoint = player_node->get_node_endpoint( CPlayerLogic::endpoint_scene );
		assert( scene_endpoint );

		const string &scene = *scene_endpoint->get_value();

		return ( scene == scene_node.get_name() );
	}


	bool CSceneLogic::can_be_child_of( const CNode *candidate_parent ) const
	{
		/*
		 scenes can only be children of players
		 */

		if( !candidate_parent )		
		{
			//can't be top-level
			return false;
		}

		if( dynamic_cast<CPlayerLogic *>( &candidate_parent->get_logic() ) )	
		{
			//can be inside player
			return true;
		}

		//can't be inside anything else
		return false;
	}

}
