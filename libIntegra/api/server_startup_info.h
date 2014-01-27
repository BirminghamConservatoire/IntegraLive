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


#ifndef INTEGRA_SERVER_STARTUP_INFO_H
#define INTEGRA_SERVER_STARTUP_INFO_H

#include "common_typedefs.h"

namespace integra_api
{
	class INotificationSink;


	class INTEGRA_API CServerStartupInfo
	{
		
		public:
			CServerStartupInfo()
			{
				system_module_directory = "";
				third_party_module_directory = "";
		
				notification_sink = NULL;
			}

			string system_module_directory;
			string third_party_module_directory;
			
			INotificationSink *notification_sink;
	};
}



#endif