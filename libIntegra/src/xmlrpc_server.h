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
_resolve * USA.
 */

#ifndef NTG_XMLRPC_SERVER_PRIVATE_H
#define NTG_XMLRPC_SERVER_PRIVATE_H


#define NTG_NULL_STRING "None"


class CXmlRpcServerContext
{
	public:

		CXmlRpcServerContext() { m_server = NULL; m_port = 0; m_sem_initialized = NULL; }

		integra_internal::CServer *m_server;
		unsigned short m_port;

		sem_t *m_sem_initialized;
};


void *ntg_xmlrpc_server_run( void *context );
void ntg_xmlrpc_server_terminate( sem_t *sem_initialized );


#endif

