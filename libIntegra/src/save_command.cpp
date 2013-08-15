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

#include "save_command.h"
#include "server.h"
#include "api/trace.h"
#include "file_io.h"
#include "file_helper.h"
#include "api/command_result.h"

#include <assert.h>


namespace integra_api
{
	ISaveCommand *ISaveCommand::create( const string &file_path, const CPath &node_path )
	{
		return new integra_internal::CSaveCommand( file_path, node_path );
	}
}


namespace integra_internal
{
	CSaveCommand::CSaveCommand( const string &file_path, const CPath &node_path )
	{
		m_file_path = file_path;
		m_node_path = node_path;
	}


	CError CSaveCommand::execute( CServer &server, CCommandSource source, CCommandResult *result )
	{
		const CNode *node = CNode::downcast( server.find_node( m_node_path ) );
		if( !node ) 
		{
			return CError::PATH_ERROR;
		}

		if( m_file_path.empty() ) 
		{
			INTEGRA_TRACE_ERROR  <<  "file path is empty";
			return CError::INPUT_ERROR;
		}

		string file_path_with_suffix = CFileHelper::ensure_filename_has_suffix( m_file_path, CFileIO::file_suffix );

		INTEGRA_TRACE_PROGRESS << "saving to " << file_path_with_suffix;

		return CFileIO::save( server, file_path_with_suffix, *node );
	}


}

