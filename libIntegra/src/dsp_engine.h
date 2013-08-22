/* libIntegra multimedia module interface
 *  
 * Copyright (C) 2012 Birmingham City University
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

#ifndef INTEGRA_DSP_ENGINE_H
#define INTEGRA_DSP_ENGINE_H

#include "api/common_typedefs.h"
#include "api/error.h"
#include "node.h"


namespace integra_internal
{
	class CDspEngine
	{
		public:

			CDspEngine();
			~CDspEngine();

			CError add_module( internal_id id, const string &patch_path );
			CError remove_module( internal_id id );
			CError connect_modules( const CNodeEndpoint &source, const CNodeEndpoint &target );
			CError disconnect_modules( const CNodeEndpoint &source, const CNodeEndpoint &target );
			CError send_value( const CNodeEndpoint &target );

		private:

			void test_libpd();


			string get_stream_connection_name( const IEndpointDefinition &endpoint_definition, const IInterfaceDefinition &interface_definition ) const;
	};
}



#endif /* INTEGRA_DSP_ENGINE_H */
