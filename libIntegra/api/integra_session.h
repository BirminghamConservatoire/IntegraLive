/* libIntegra multimedia module info interface
 *
 * Copyright (C) 2007 Jamie Bullock, Henrik Frisk
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

#ifndef INTEGRA_SESSION_H
#define INTEGRA_SESSION_H

#include "common_typedefs.h"
#include "error.h"
#include "server_lock.h"


namespace integra_api
{
	class CServerStartupInfo;
	class IServer;

	class INTEGRA_API CIntegraSession
	{
		public:
			CIntegraSession();
			~CIntegraSession();

			CError start_session( const CServerStartupInfo &startup_info );
			CError end_session();

			CServerLock get_server();

		private:	

			IServer *m_server;
	};
}



#endif 