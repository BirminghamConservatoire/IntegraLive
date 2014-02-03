/** IntegraServer - console app to expose xmlrpc interface to libIntegra
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

#ifndef NTG_XMLRPC_SERVER_PRIVATE_H
#define NTG_XMLRPC_SERVER_PRIVATE_H


namespace integra_api
{
	class CIntegraSession;
}

using namespace integra_api;

class CXmlRpcServer
{
	public:

		CXmlRpcServer( CIntegraSession &integra_session, unsigned short port );

		void run();

		void shutdown();

	private:

		CIntegraSession &m_integra_session;
		unsigned short m_port;

		bool m_shutdown;
};




#endif

