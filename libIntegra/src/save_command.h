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


#ifndef INTEGRA_SAVE_COMMAND_PRIVATE
#define INTEGRA_SAVE_COMMAND_PRIVATE

#include "api/command_api.h"
#include "path.h"

using namespace ntg_api;




namespace ntg_internal
{
	class CSaveCommand : public CSaveCommandApi
	{
		public:
			CSaveCommand( const string &file_path, const CPath &node_path );

		private:
			
			CError execute( CServer &server, CCommandSource source, CCommandResult *result );

			string m_file_path;
			CPath m_node_path;
	};
}



#endif /*INTEGRA_SAVE_COMMAND_PRIVATE*/