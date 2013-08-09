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

#include "scaler_logic.h"
#include "node_endpoint.h"
#include "node.h"
#include "assert.h"
#include "server.h"
#include "interface_definition.h"
#include "api/command_api.h"


namespace ntg_internal
{
	const string CScalerLogic::s_endpoint_in_value = "inValue";
	const string CScalerLogic::s_endpoint_out_value = "outValue";
	const string CScalerLogic::s_endpoint_in_range_min = "inRangeMin";
	const string CScalerLogic::s_endpoint_in_range_max = "inRangeMax";
	const string CScalerLogic::s_endpoint_out_range_min = "outRangeMin";
	const string CScalerLogic::s_endpoint_out_range_max = "outRangeMax";


	CScalerLogic::CScalerLogic( const CNode &node )
		:	CLogic( node )
	{
	}


	CScalerLogic::~CScalerLogic()
	{
	}


	void CScalerLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, ntg_command_source source )
	{
		CLogic::handle_set( server, node_endpoint, previous_value, source );

		const string &endpoint_name = node_endpoint.get_endpoint_definition().get_name();
	
		if( endpoint_name == s_endpoint_in_value )
		{
			const CValue *value = node_endpoint.get_value();
			assert( value );

			value_handler( server, *value );
			return;
		}
	}


	void CScalerLogic::value_handler( CServer &server, const CValue &value )
	{
		if( !node_is_active() )
		{
			return;
		}

		const CNode &scaler_node = get_node();

		const CNodeEndpoint *in_range_min_endpoint = scaler_node.get_node_endpoint( s_endpoint_in_range_min );
		const CNodeEndpoint *in_range_max_endpoint = scaler_node.get_node_endpoint( s_endpoint_in_range_max );
		const CNodeEndpoint *out_range_min_endpoint = scaler_node.get_node_endpoint( s_endpoint_out_range_min );
		const CNodeEndpoint *out_range_max_endpoint = scaler_node.get_node_endpoint( s_endpoint_out_range_max );
		const CNodeEndpoint *out_value_endpoint = scaler_node.get_node_endpoint( s_endpoint_out_value );
		assert( in_range_min_endpoint && in_range_max_endpoint && out_range_min_endpoint && out_range_max_endpoint && out_value_endpoint);

		assert( value.get_type() == CValue::FLOAT );
		assert( in_range_min_endpoint->get_value() && in_range_min_endpoint->get_value()->get_type() == CValue::FLOAT );
		assert( in_range_max_endpoint->get_value() && in_range_max_endpoint->get_value()->get_type() == CValue::FLOAT );
		assert( out_range_min_endpoint->get_value() && out_range_min_endpoint->get_value()->get_type() == CValue::FLOAT );
		assert( out_range_max_endpoint->get_value() && out_range_max_endpoint->get_value()->get_type() == CValue::FLOAT );

		float in_range_min = *in_range_min_endpoint->get_value();
		float in_range_max = *in_range_max_endpoint->get_value();
		float out_range_min = *out_range_min_endpoint->get_value();
		float out_range_max = *out_range_max_endpoint->get_value();

		float in_range_total = in_range_max - in_range_min;
		float out_range_total = out_range_max - out_range_min;

		if( fabs(in_range_total) < FLT_EPSILON)
		{
			/*
			Special case for input range ~= 0, to prevent division by zero errors or unusual behaviour arising from 
			floating point inaccuracy when dividing by a very tiny number.
		
			In this case setting the in_range_total to 1 will result in predictable and acceptable behaviour
			*/
			in_range_total = 1;
		}

		/*restrict to input range*/
		float scaled_value = value;
		scaled_value = MAX( scaled_value, MIN( in_range_min, in_range_max ) );
		scaled_value = MIN( scaled_value, MAX( in_range_min, in_range_max ) );

		/*perform linear interpolation*/
		scaled_value = ( scaled_value - in_range_min ) * out_range_total / in_range_total + out_range_min;

		/*store result*/
		server.process_command( CSetCommandApi::create( out_value_endpoint->get_path(), &CFloatValue( scaled_value ) ), NTG_SOURCE_SYSTEM );
	}
}
