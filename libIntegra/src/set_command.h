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



#ifndef INTEGRA_SET_COMMAND_PRIVATE
#define INTEGRA_SET_COMMAND_PRIVATE

#include "api/command.h"
#include "api/path.h"

using namespace integra_api;


namespace integra_internal
{
	class CNodeEndpoint;
	class CInterfaceDefinition;


	class CSetCommand : public ISetCommand
	{
		public:
			CSetCommand( const CPath &endpoint_path, const CValue &value );
			CSetCommand( const CPath &endpoint_path );
			~CSetCommand();

		private:
			
			CError execute( CServer &server, CCommandSource source, CCommandResult *result );

			bool should_send_to_host( const CNodeEndpoint &endpoint, const CInterfaceDefinition &interface_definition, CCommandSource source ) const;

			const CPath &get_endpoint_path() const { return m_endpoint_path; }

			CPath m_endpoint_path;
			CValue *m_value;
	};
}



#endif /*INTEGRA_SET_COMMAND_PRIVATE*/