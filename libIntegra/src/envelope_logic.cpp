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

#include "platform_specifics.h"

#include "envelope_logic.h"
#include "control_point_logic.h"
#include "node_endpoint.h"
#include "interface_definition.h"
#include "server.h"
#include "api/command_api.h"

#include <assert.h>


namespace ntg_internal
{
	const string CEnvelopeLogic::s_endpoint_start_tick = "startTick";
	const string CEnvelopeLogic::s_endpoint_current_tick = "currentTick";
	const string CEnvelopeLogic::s_endpoint_current_value = "currentValue";


	CEnvelopeLogic::CEnvelopeLogic( const CNode &node )
		:	CLogic( node )
	{
	}


	CEnvelopeLogic::~CEnvelopeLogic()
	{
	}

	
	void CEnvelopeLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, ntg_command_source source )
	{
		CLogic::handle_set( server, node_endpoint, previous_value, source );

		const string &endpoint_name = node_endpoint.get_endpoint_definition().get_name();
	
		if( endpoint_name == s_endpoint_start_tick || endpoint_name == s_endpoint_current_tick )
		{
			update_value( server );
			return;
		}	
	}


	void CEnvelopeLogic::update_on_activation( CServer &server )
	{
		update_value( server );
	}


	void CEnvelopeLogic::update_value( CServer &server, const CNode *control_point_to_ignore )
	{
		if( !node_is_active() )
		{
			return;
		}

		const CNode &envelope_node = get_node();
		const CNodeEndpoint *current_value_endpoint = envelope_node.get_node_endpoint( s_endpoint_current_value );
		assert( current_value_endpoint );

		/*
		lookup envelope current tick 
		*/

		const CNodeEndpoint *current_tick_endpoint = envelope_node.get_node_endpoint( s_endpoint_current_tick );
		assert( current_tick_endpoint );

		int envelope_current_tick = *current_tick_endpoint->get_value();


		/*
		lookup and apply envelope start tick
		*/

		const CNodeEndpoint *start_tick_endpoint = envelope_node.get_node_endpoint( s_endpoint_start_tick );
		assert( start_tick_endpoint );
		int envelope_start_tick = *start_tick_endpoint->get_value();

		envelope_current_tick -= envelope_start_tick;

		/*
		iterate over control points to find ticks and values of latest previous control point and earliest next control point
		*/

		bool found_previous_tick = false;
		bool found_next_tick = false;
		float previous_value = 0;
		float next_value = 0;
		int latest_previous_tick = 0;
		int earliest_next_tick = 0;
		float previous_control_point_curvature = 0;

		const node_map &control_points = envelope_node.get_children();
		for( node_map::const_iterator i = control_points.begin(); i != control_points.end(); i++ )
		{
			const CNode *control_point = i->second;
			if( control_point == control_point_to_ignore )
			{
				continue;
			}

			const CNodeEndpoint *control_point_tick_endpoint = control_point->get_node_endpoint( CControlPointLogic::s_endpoint_tick );
			const CNodeEndpoint *control_point_value_endpoint = control_point->get_node_endpoint( CControlPointLogic::s_endpoint_value );

			assert( control_point_tick_endpoint && control_point_value_endpoint );

			int control_point_tick = *control_point_tick_endpoint->get_value();
			float control_point_value = *control_point_value_endpoint->get_value();

			if( control_point_tick <= envelope_current_tick && ( !found_previous_tick || control_point_tick > latest_previous_tick ) )
			{
				latest_previous_tick = control_point_tick;
				previous_value = control_point_value;

				const CNodeEndpoint *control_point_curvature_endpoint = control_point->get_node_endpoint( CControlPointLogic::s_endpoint_curvature );
				assert( control_point_curvature_endpoint );

				previous_control_point_curvature = *control_point_curvature_endpoint->get_value();

				found_previous_tick = true;
			}

			if( control_point_tick > envelope_current_tick && ( !found_next_tick || control_point_tick < earliest_next_tick ) )
			{
				earliest_next_tick = control_point_tick;
				next_value = control_point_value;
				found_next_tick = true;
			}
		}

		/*
		find output value
		*/

		float output = 0;

		if( found_previous_tick )
		{
			if( found_next_tick )
			{
				/*
				between control points - perform interpolation
				*/
				int tick_range = earliest_next_tick - latest_previous_tick;
				assert( tick_range > 0 );

				float interpolation = (float) ( envelope_current_tick - latest_previous_tick ) / tick_range;

				/*
				apply curvature
				*/

				if( previous_control_point_curvature != 0 )
				{
					interpolation = pow( interpolation, pow( 2, -previous_control_point_curvature ) );
				}

				output = previous_value + interpolation * ( next_value - previous_value );
			}
			else
			{
				/*
				after last control point - use previous value
				*/
				output = previous_value;
			}
		}
		else
		{
			if( found_next_tick )
			{
				/*
				before first control point - use next value
				*/
				output = next_value;
			}
			else
			{
				/*
				no control points - can't find output value
				*/

				return;
			}
		}
	
		/*
		store output value if changed
		*/
		CFloatValue output_value( output );

		if( !current_value_endpoint->get_value()->is_equal( output_value ) )
		{
			server.process_command( CSetCommandApi::create( current_value_endpoint->get_path(), &output_value ), NTG_SOURCE_SYSTEM );
		}
	}

}
