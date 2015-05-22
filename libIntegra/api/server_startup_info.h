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

/** \file server_startup_info.h
 *  \brief Defines class CServerStartupInfo
 */

#ifndef INTEGRA_SERVER_STARTUP_INFO_H
#define INTEGRA_SERVER_STARTUP_INFO_H

#include "common_typedefs.h"

namespace integra_api
{
	class INotificationSink;


	/** \class CServerStartupInfo server_startup_info.h "api/server_startup_info.h"
	 *  \brief Holds configuration data for libIntegra
	 *
	 *  CServerStartupInfo is passed into CIntegraSession::start_session
	 */	
	class INTEGRA_API CServerStartupInfo
	{
		
		public:
			/** \brief Construct empty startup info */
			CServerStartupInfo()
			{
				system_module_directory = "";
				third_party_module_directory = "";
		
				notification_sink = NULL;
			}

			/** \brief Disk location of the shipped-with-libIntegra modules.
			 *
			 * Typically this would be somewhere in your application's installation directory, eg (for windows) C:\Program Files\<Your Integra Application>\modules\
			 * \note This directory is required - libIntegra won't work unless it is provided
			 */
			string system_module_directory;

			/** \brief Disk location for 3rd party modules
			 *
			 * Typically this would be in a hidden application storage directory, eg (for windows) C:\Users\<Account Name>\AppData\Roaming\<Application Name>\Local Store\ThirdPartyModules
			 * \note This directory is required - libIntegra won't work unless it is provided
			 */
			string third_party_module_directory;
			
			/** \brief Pointer to an INotificationSink subclass, for receiving feedback when control endpoints are set.
			 *
			 * \note notification_sink is not required.  Leave it as NULL if you don't need notifications.
			 */
			INotificationSink *notification_sink;
	};
}



#endif