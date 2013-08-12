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
 * USA.
 */


#ifndef INTEGRA_COMMAND_SOURCE
#define INTEGRA_COMMAND_SOURCE

#include "api/common_typedefs.h"

namespace integra_api
{
	class INTEGRA_API CCommandSource
	{
		public:

			enum source 
			{
				NONE = -1,
				INITIALIZATION,
				LOAD,
				SYSTEM,
				CONNECTION,
				HOST,
				SCRIPT,
				XMLRPC_API,
				PUBLIC_API
			}; 

			CCommandSource();
			CCommandSource( source command_source );

			operator source() const;
			string get_text() const;

		private:

			source m_command_source;
	};
}



#endif /*INTEGRA_COMMAND_SOURCE*/