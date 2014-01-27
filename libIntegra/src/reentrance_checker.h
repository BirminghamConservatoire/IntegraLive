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


#ifndef INTEGRA_REENTRANCE_CHECKER_H
#define INTEGRA_REENTRANCE_CHECKER_H

#include <list>
#include <unordered_map>

#include "api/common_typedefs.h"
#include "api/command_source.h"


using namespace integra_api;


namespace integra_internal
{
	class CNodeEndpoint;


	class CReentranceChecker
	{
		public:	

			CReentranceChecker();
			~CReentranceChecker();

			/**\brief push reentrance stack, returns true if rentrance detected */
			bool push( const CNodeEndpoint *node_endpoint, CCommandSource source );

			/**\brief pop reentrance stack.  must be called once for every push which returns false */
			void pop();

		private:

			static bool cares_about_source( CCommandSource source );


			typedef std::list<const CNodeEndpoint *> node_endpoint_stack;
			typedef std::unordered_map<const CNodeEndpoint *, CCommandSource> map_node_endpoint_to_source;

			node_endpoint_stack m_stack;
			map_node_endpoint_to_source m_map_endpoint_to_source;
	};
}


#endif /*INTEGRA_REENTRANCE_CHECKER_H*/
