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

#include "api/polling_notification_sink.h"
#include "api/path.h"
#include "api/command_source.h"


namespace integra_api
{
	CPollingNotificationSink::CPollingNotificationSink()
	{
		pthread_mutex_init( &m_mutex, NULL );
	}


	CPollingNotificationSink::~CPollingNotificationSink()
	{
		pthread_mutex_destroy( &m_mutex );
	}


	void CPollingNotificationSink::get_changed_endpoints( changed_endpoint_map &changed_endpoints )
	{
	    pthread_mutex_lock( &m_mutex );

		changed_endpoints = m_changed_endpoints;
		
		m_changed_endpoints.clear();

	    pthread_mutex_unlock( &m_mutex );
	}


	void CPollingNotificationSink::on_set_command( const IServer &server, const CPath &endpoint_path, const CCommandSource &source )
	{
	    pthread_mutex_lock( &m_mutex );

		m_changed_endpoints[ endpoint_path.get_string() ] = source;

	    pthread_mutex_unlock( &m_mutex );
	}
}