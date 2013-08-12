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

#include "load_command.h"
#include "server.h"
#include "api/trace.h"
#include "file_io.h"
#include "api/command_result.h"

#include <assert.h>


namespace integra_api
{
	CLoadCommandApi *CLoadCommandApi::create( const string &file_path, const CPath &parent_path )
	{
		return new integra_internal::CLoadCommand( file_path, parent_path );
	}
}


namespace integra_internal
{
	CLoadCommand::CLoadCommand( const string &file_path, const CPath &parent_path )
	{
		m_file_path = file_path;
		m_parent_path = parent_path;
	}


	CError CLoadCommand::execute( CServer &server, CCommandSource source, CCommandResult *result )
	{
		const CNode *parent = server.find_node( m_parent_path );

		guid_set new_embedded_module_ids;

		CError error = CFileIO::load( server, m_file_path, parent, new_embedded_module_ids );

		if( error != CError::SUCCESS )
		{
			return error;
		}

		if( result )
		{
			CLoadCommandResult *load_command_result = dynamic_cast<CLoadCommandResult *> ( result );
			if( load_command_result )
			{
				load_command_result->set_new_embedded_module_ids( new_embedded_module_ids );
			}
			else
			{
				INTEGRA_TRACE_ERROR << "incorrect command result type - can't store result";
			}
		}

		return CError::SUCCESS;
	}


}

