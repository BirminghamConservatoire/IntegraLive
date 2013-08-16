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

#ifndef NTG_OSC_CLIENT_PRIVATE_H
#define NTG_OSC_CLIENT_PRIVATE_H


#include "api/notification_sink.h"

#include "lo/lo.h" 


namespace integra_api
{
	class IServer;
	class CCommandSource;
	class CPath;
	class CValue;
}

using namespace integra_api;


class COscClient : public INotificationSink
{
	public:

		COscClient( const string &url, unsigned short port );
		~COscClient();

	private:

		void on_set_command( const IServer &server, const CPath &endpoint_path, const CCommandSource &source );

		bool should_send_to_client( const CCommandSource &source ) const;

		void send_sss( const char *path, const char *s1, const char *s2, const char *s3 );
		void send_ssi( const char *path, const char *s1, const char *s2, int i );
		void send_ssf( const char *path, const char *s1, const char *s2, float f );
		void send_ssN( const char *path, const char *s1, const char *s2 );

		lo_address m_address;
};


#endif

