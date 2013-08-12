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


#ifndef INTEGRA_CONTAINER_LOGIC_PRIVATE
#define INTEGRA_CONTAINER_LOGIC_PRIVATE

#include "logic.h"
#include "path.h"


namespace ntg_internal
{
	class CContainerLogic : public CLogic
	{
		public:
			CContainerLogic( const CNode &node );
			~CContainerLogic();

			void handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source );

		private:

			void active_handler( CServer &server, bool active );
			void activate_tree( CServer &server, const CNode &node, bool activate, path_list &activated_nodes );
	};
}



#endif /*INTEGRA_NEW_COMMAND_PRIVATE*/