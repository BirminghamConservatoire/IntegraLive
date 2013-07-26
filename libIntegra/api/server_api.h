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

#ifndef SERVER_API_H
#define SERVER_API_H

#include "common_typedefs.h"


namespace ntg_api
{
	class CServerStartupInfo;

	class LIBINTEGRA_API CServerApi
	{
		protected:
			CServerApi() {}

		public:

			static CServerApi *create_server( const CServerStartupInfo &startup_info );
			virtual ~CServerApi() {}

			virtual void block_until_shutdown_signal() = 0;

	};
}



#endif 