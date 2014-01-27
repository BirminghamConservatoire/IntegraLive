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




#ifndef INTEGRA_NOTIFICATION_SINK_API
#define INTEGRA_NOTIFICATION_SINK_API

#include "common_typedefs.h"


namespace integra_api
{
	class CCommandSource;
	class IServer;
	class CPath;

	/** \class INotificationSink node_endpoint.h "api/notification_sink.h"
	 *  \brief provides mechanism to recieve feedback about changes to libIntegra's state
	 *
	 * In order to receive feedback from libIntegra, the caller can subclass INotificationSink, 
	 * and pass the subclass into IntegraSession via CServerStartupInfo.
	 *
	 * \note libIntegra may use this notification sink from many different threads, although it will
	 * only use it when the server is locked (so it will can call it from multiple threads simultaneously).
	 * If the user is developing a single-threaded gui application, they may wish to use the 
	 * helper class CPollingNotificationSink, instead of using INotificationSink directly.
	 */
	class INTEGRA_API INotificationSink
	{
		protected:

			INotificationSink() {}

		public:

			virtual ~INotificationSink() {}

			virtual void on_set_command( const IServer &server, const CPath &endpoint_path, const CCommandSource &source ) = 0;
	};
}



#endif 