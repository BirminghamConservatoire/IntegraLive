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

#include "script_logic.h"
#include "node_endpoint.h"
#include "server.h"
#include "lua_engine.h"
#include "interface_definition.h"
#include "api/trace.h"
#include "api/command.h"

#include <assert.h>



namespace integra_internal
{
	const string CScriptLogic::endpoint_trigger = "trigger";
	const string CScriptLogic::endpoint_text = "text";
	const string CScriptLogic::endpoint_info = "info";



	CScriptLogic::CScriptLogic( const CNode &node )
		:	CLogic( node )
	{
	}


	CScriptLogic::~CScriptLogic()
	{
	}

	
	void CScriptLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source )
	{
		CLogic::handle_set( server, node_endpoint, previous_value, source );

		const string &endpoint_name = node_endpoint.get_endpoint_definition().get_name();
	
		if( endpoint_name == endpoint_trigger )
		{
			trigger_handler( server );
			return;
		}	
	}


	void CScriptLogic::trigger_handler( CServer &server )
	{
		const CNode &script_node = get_node();

		const INodeEndpoint *text_endpoint = script_node.get_node_endpoint( endpoint_text );
		assert( text_endpoint );

		const string &script = *text_endpoint->get_value();

		INTEGRA_TRACE_VERBOSE << "running script...   " << script;

		const CPath &parent_path = script_node.get_parent_path();
	
		string script_output = server.get_lua_engine().run_script( server, parent_path, script );
		server.process_command( ISetCommand::create( script_node.get_node_endpoint( endpoint_info )->get_path(), CStringValue( script_output ) ), CCommandSource::SYSTEM );

		INTEGRA_TRACE_VERBOSE << "script finished";
	}
}
