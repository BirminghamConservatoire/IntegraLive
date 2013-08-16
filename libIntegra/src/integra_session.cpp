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

#include <sys/stat.h>

#include "api/integra_session.h"
#include "api/trace.h"
#include "api/server_startup_info.h"
#include "server.h"

using namespace integra_internal;


namespace integra_api
{
	CIntegraSession::CIntegraSession()
	{
		m_server = NULL;
	}


	CIntegraSession::~CIntegraSession()
	{
		if( m_server )
		{
			end_session();
		}
	}



	CError CIntegraSession::start_session( const CServerStartupInfo &startup_info )
	{
		if( m_server )
		{
			INTEGRA_TRACE_ERROR << "Can't start session - session already started";
			return CError::FAILED;
		}

		if( startup_info.bridge_path.empty() ) 
		{
			INTEGRA_TRACE_ERROR << "bridge_path is empty";
			return CError::INPUT_ERROR;
		}

		struct stat file_buffer;
		if( stat( startup_info.bridge_path.c_str(), &file_buffer ) != 0 ) 
		{
			INTEGRA_TRACE_ERROR << "bridge_path points to a nonexsitant file";
			return CError::INPUT_ERROR;
		}

		if( startup_info.system_module_directory.empty() ) 
		{
			INTEGRA_TRACE_ERROR << "system_module_directory is empty";
			return CError::INPUT_ERROR;
		}

		if( startup_info.third_party_module_directory.empty() ) 
		{
			INTEGRA_TRACE_ERROR << "third_party_module_directory is empty";
			return CError::INPUT_ERROR;
		}

		m_server = new CServer( startup_info );

		return CError::SUCCESS;
	}


	CError CIntegraSession::end_session()
	{
		if( !m_server )
		{
			INTEGRA_TRACE_ERROR << "Can't end session - session wasn't started";
			return CError::FAILED;
		}

		delete m_server;
		m_server = NULL;
		return CError::SUCCESS;
	}


	CServerLock CIntegraSession::get_server()
	{
		return CServerLock( m_server );
	}
}


