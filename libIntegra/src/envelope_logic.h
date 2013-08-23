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


#ifndef INTEGRA_ENVELOPE_LOGIC_PRIVATE
#define INTEGRA_ENVELOPE_LOGIC_PRIVATE

#include "logic.h"


namespace integra_internal
{
	class CEnvelopeLogic : public CLogic
	{
		friend class CControlPointLogic;

		public:
			CEnvelopeLogic( const CNode &node );
			~CEnvelopeLogic();

			void handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source );

		private:

			void update_on_activation( CServer &server );

			void update_value( CServer &server, const CNode *control_point_to_ignore = NULL );

			const static string endpoint_start_tick;
			const static string endpoint_current_tick;
			const static string endpoint_current_value;
	};
}



#endif /*INTEGRA_ENVELOPE_LOGIC_PRIVATE*/