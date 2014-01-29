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

/** \file polling_notification_sink.h
 *  \brief Defines class CPollingNotificationSink
 */


#ifndef INTEGRA_SINGLE_THREADED_NOTIFICATIONS_H
#define INTEGRA_SINGLE_THREADED_NOTIFICATIONS_H

#include "common_typedefs.h"

#include "notification_sink.h"

#include <pthread.h>

namespace integra_api
{
	/** \class CPollingNotificationSink polling_notification_sink.h "api/polling_notification_sink.h"
	 *  \brief Helper class to receive notifications within a single thread
	 *
	 * CPollingNotificationSink is a helper class for users who wish to receive notifications 
	 *  about changed endpoints within a single thread, for example in an event-driven gui application.
	 * 
	 *  To use it, create an instance of CPollingNotificationSink, and pass a pointer to it via
	 *  CServerStartupInfo into CIntegraSession::start_session.
	 * 
	 *  To receive notifications about changed endpoints, users should repeatedly call get_changed_endpoints.  The 
	 *  method will return the set of endpoints which have been set since the method was last called, mapped
	 *  to the command source for each set command.  
	 */
	class INTEGRA_API CPollingNotificationSink : public INotificationSink
	{
		public:

			CPollingNotificationSink();
			~CPollingNotificationSink();

			/** Map string-representation of endpoint path to CCommandSource */
			typedef std::unordered_map<string, CCommandSource> changed_endpoint_map;

			/** \brief Polling function
			 *
			 * /param[out] changed_endpoints This map will be populated with the paths of all control endpoints
			 * which have been set since the polling function was last called.  Each map entry also stores the 
			 * CCommandSource relating to why the endpoint was set.
			 */
			void get_changed_endpoints( changed_endpoint_map &changed_endpoints );

		private:
			
			void on_set_command( const IServer &server, const CPath &endpoint_path, const CCommandSource &source );

			changed_endpoint_map m_changed_endpoints;

			pthread_mutex_t m_mutex;
	};
}



#endif