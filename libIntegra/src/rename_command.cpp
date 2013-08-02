/** libIntegra multimedia module interface
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

#include "rename_command.h"
#include "server.h"
#include "trace.h"
#include "helper.h"
#include "system_class_handlers.h"

#include <assert.h>

using namespace ntg_api;


namespace ntg_api
{
	CRenameCommandApi *CRenameCommandApi::create( const CPath &path, const string &new_name )
	{
		return new ntg_internal::CRenameCommand( path, new_name );
	}
}


namespace ntg_internal
{
	CRenameCommand::CRenameCommand( const CPath &path, const string &new_name )
	{
		m_path = path;
		m_new_name = new_name;
	}


	CError CRenameCommand::execute( CServer &server, ntg_command_source source, CCommandResult *result )
	{
		CNode *node = server.find_node_writable( m_path );
		if( !node ) 
		{
			return CError::PATH_ERROR;
		}

		if( !ntg_validate_node_name( m_new_name.c_str() ) )
		{
			NTG_TRACE_ERROR_WITH_STRING( "node name contains invalid characters", m_new_name.c_str() );
			return CError::INPUT_ERROR;
		}

		/* First check if node name is already taken */
		node_map &sibling_set = server.get_sibling_set_writable( *node );
		while( sibling_set.count( m_new_name ) > 0 ) 
		{
			NTG_TRACE_PROGRESS_WITH_STRING( "node name is in use; appending underscore", m_new_name.c_str() );
			m_new_name += "_";
		}

		string previous_name = node->get_name();

		/* remove old state table entries for node and children */
		server.get_state_table().remove( *node );

		node->rename( m_new_name );

		sibling_set.erase( previous_name );
		sibling_set[ m_new_name ] = node;

		/* add new state table entries for node and children */
		server.get_state_table().add( *node );

		ntg_system_class_handle_rename( server, *node, previous_name.c_str(), source );

		if( ntg_should_send_to_client( source ) ) 
		{
			ntg_osc_client_send_rename( server.get_osc_client(), source, m_path, m_new_name.c_str() );
		}

		return CError::SUCCESS;
	}


}

