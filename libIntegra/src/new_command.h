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


#ifndef INTEGRA_NEW_COMMAND_PRIVATE
#define INTEGRA_NEW_COMMAND_PRIVATE

#include "api/command_api.h"
#include "api/path.h"

using namespace integra_api;



namespace integra_internal
{
	class CNewCommand : public CNewCommandApi
	{
		public:
			CNewCommand( const GUID &module_id, const string &node_name, const CPath &parent_path );

		private:
			
			CError execute( CServer &server, CCommandSource source, CCommandResult *result );

			string make_node_name( CServer &server, const string &module_name ) const;

			GUID m_module_id;
			string m_node_name;
			CPath m_parent_path;
	};
}



#endif /*INTEGRA_NEW_COMMAND_PRIVATE*/