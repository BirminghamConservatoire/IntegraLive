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
#include "server.h"
#include "api/command_api.h"

#include <assert.h>


namespace ntg_internal
{
	const ntg_api::string CPlayerLogic::s_endpoint_play = "play";
	const ntg_api::string CPlayerLogic::s_endpoint_tick = "tick";
	const ntg_api::string CPlayerLogic::s_endpoint_start = "start";
	const ntg_api::string CPlayerLogic::s_endpoint_end = "end";
	const ntg_api::string CPlayerLogic::s_endpoint_loop = "loop";
	const ntg_api::string CPlayerLogic::s_endpoint_rate = "rate";



	CPlayerLogic::CPlayerLogic( const CNode &node )
		:	CLogic( node )
	{
	}


	CPlayerLogic::~CPlayerLogic()
	{
	}

	
	void CPlayerLogic::handle_new( CServer &server, ntg_command_source source )
	{
		CLogic::handle_new( server, source );

		//todo - implement
	}


	void CPlayerLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, ntg_command_source source )
	{
		CLogic::handle_set( server, node_endpoint, previous_value, source );

		//todo - implement
	}


	void CPlayerLogic::handle_rename( CServer &server, const string &previous_name, ntg_command_source source )
	{
		CLogic::handle_rename( server, previous_name, source );

		//todo - implement
	}


	void CPlayerLogic::handle_move( CServer &server, const CPath &previous_path, ntg_command_source source )
	{
		CLogic::handle_move( server, previous_path, source );

		//todo - implement
	}


	void CPlayerLogic::handle_delete( CServer &server, ntg_command_source source )
	{
		CLogic::handle_delete( server, source );

		//todo - implement
	}


	void CPlayerLogic::update_on_activation( CServer &server )
	{
		const CNodeEndpoint *tick = get_node().get_node_endpoint( s_endpoint_tick );
		assert( tick );

		server.process_command( CSetCommandApi::create( tick->get_path(), tick->get_value() ), NTG_SOURCE_SYSTEM );
	}

}
