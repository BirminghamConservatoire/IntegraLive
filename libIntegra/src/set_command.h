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


#ifndef INTEGRA_SET_COMMAND_PRIVATE
#define INTEGRA_SET_COMMAND_PRIVATE

#include "api/command_api.h"
#include "path.h"


namespace ntg_internal
{
	class CNodeEndpoint;
	class CInterfaceDefinition;


	class LIBINTEGRA_API CSetCommand : public ntg_api::CSetCommandApi
	{
		public:
			CSetCommand( const ntg_api::CPath &endpoint_path, const ntg_api::CValue *value );
			~CSetCommand();

		private:
			
			ntg_api::CError execute( CServer &server, ntg_command_source source, ntg_api::CCommandResult *result );

			bool should_send_to_host( const CNodeEndpoint &endpoint, const CInterfaceDefinition &interface_definition, ntg_command_source source ) const;

			ntg_api::CPath m_endpoint_path;
			ntg_api::CValue *m_value;
	};
}



#endif /*INTEGRA_SET_COMMAND_PRIVATE*/