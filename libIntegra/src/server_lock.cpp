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

#include "api/integra_session.h"
#include "api/trace.h"
#include "api/server_startup_info.h"
#include "server.h"

#include <assert.h>

using namespace integra_internal;

namespace integra_api
{
	CServerLock::CServerLock( IServer *server )
	{
		m_server = server;

		CServer *inner_server = dynamic_cast<CServer *>( m_server );
		if( !inner_server->lock() )
		{
			INTEGRA_TRACE_ERROR << "illegal attempt to obtain server lock during server destruction";
			assert( false );
		}
	}


	CServerLock::~CServerLock()
	{
		CServer *inner_server = dynamic_cast<CServer *>( m_server );
		inner_server->unlock();
	}


	IServer &CServerLock::operator*()
	{
		return *m_server;
	}


	IServer *CServerLock::operator->()
	{
		return m_server;
	}
}


