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

/** \file server_lock.h
 *  \brief defines class CServerLock
 */

#ifndef INTEGRA_SERVER_LOCK_H
#define INTEGRA_SERVER_LOCK_H

#include "common_typedefs.h"


namespace integra_api
{
	class IServer;

	/** \class CServerLock server_lock.h "api/server_lock.h"
	 *  \brief locking mechanism for IServer
	 *
	 *  Users of libIntegra api should only call methods on IServer when exactly one CServerLock instance exists.
	 *	This is because all the methods of IServer assumes that the server is locked.
	 *	The way to do this is as follows:
	 *
	 *	1) Obtain a CServerLock from CIntegraSession each time you need to interact with libIntegra
	 *
	 *	2) Use CServerLock::operator-> and CServerLock::operator* to call IServer methods
	 *
	 *	3) Ensure that the CServerLock is destroyed as soon as you are finished with it, typically by declaring 
	 *	it as a local variable which falls out of scope
	 *
	 *	Example 1 (code block):
	 *	{
	 *		CServerLock server = m_integra_session.get_server();
	 *		server.do_something();
	 *	}
	 *
	 *	Example 2 (inline):
	 *
	 *	m_integra_session.get_server().do_something();
	 */	
	class INTEGRA_API CServerLock
	{
		public:
			CServerLock( IServer *server );
			~CServerLock();

			IServer &operator*();
			IServer *operator->();

		private:	

			IServer *m_server;
	};
}


#endif 