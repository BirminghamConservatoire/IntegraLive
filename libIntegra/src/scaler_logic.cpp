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


#include "platform_specifics.h"

#include "scaler_logic.h"
#include "node_endpoint.h"
#include "node.h"
#include "assert.h"
#include "server.h"
#include "interface_definition.h"
#include "api/command.h"
#include "api/trace.h"

#include <float.h>
#include <assert.h>


namespace integra_internal
{
	const string CScalerLogic::endpoint_in_value = "inValue";
	const string CScalerLogic::endpoint_out_value = "outValue";

	const string CScalerLogic::endpoint_in_range_min = "inRangeMin";
	const string CScalerLogic::endpoint_in_range_max = "inRangeMax";
	const string CScalerLogic::endpoint_in_mode = "inMode";
	const string CScalerLogic::endpoint_in_scale = "inScale";
	const string CScalerLogic::endpoint_out_range_min = "outRangeMin";
	const string CScalerLogic::endpoint_out_range_max = "outRangeMax";
	const string CScalerLogic::endpoint_out_scale = "outScale";

	const string CScalerLogic::mode_snap = "snap";
	const string CScalerLogic::mode_ignore = "ignore";

	const string CScalerLogic::scale_linear = "linear";
	const string CScalerLogic::scale_exponential = "exponential";
	const string CScalerLogic::scale_decibel = "decibel";


	CScalerLogic::CScalerLogic( const CNode &node )
		:	CLogic( node )
	{
	}


	CScalerLogic::~CScalerLogic()
	{
	}


	void CScalerLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source )
	{
		CLogic::handle_set( server, node_endpoint, previous_value, source );

		const string &endpoint_name = node_endpoint.get_endpoint_definition().get_name();
	
		if( endpoint_name == endpoint_in_value )
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

		const INodeEndpoint *in_range_min_endpoint = scaler_node.get_node_endpoint( endpoint_in_range_min );
		const INodeEndpoint *in_range_max_endpoint = scaler_node.get_node_endpoint( endpoint_in_range_max );
		const INodeEndpoint *in_mode_endpoint = scaler_node.get_node_endpoint( endpoint_in_mode );
		const INodeEndpoint *in_scale_endpoint = scaler_node.get_node_endpoint( endpoint_in_scale );
		const INodeEndpoint *out_range_min_endpoint = scaler_node.get_node_endpoint( endpoint_out_range_min );
		const INodeEndpoint *out_range_max_endpoint = scaler_node.get_node_endpoint( endpoint_out_range_max );
		const INodeEndpoint *out_scale_endpoint = scaler_node.get_node_endpoint( endpoint_out_scale );
		const INodeEndpoint *out_value_endpoint = scaler_node.get_node_endpoint( endpoint_out_value );
		assert( in_range_min_endpoint && in_range_max_endpoint && in_mode_endpoint && in_scale_endpoint && out_range_min_endpoint && out_range_max_endpoint && out_scale_endpoint && out_value_endpoint);

		assert( value.get_type() == CValue::FLOAT );
		assert( in_range_min_endpoint->get_value() && in_range_min_endpoint->get_value()->get_type() == CValue::FLOAT );
		assert( in_range_max_endpoint->get_value() && in_range_max_endpoint->get_value()->get_type() == CValue::FLOAT );
		assert( in_mode_endpoint->get_value() && in_mode_endpoint->get_value()->get_type() == CValue::STRING );
		assert( in_scale_endpoint->get_value() && in_scale_endpoint->get_value()->get_type() == CValue::STRING );
		assert( out_range_min_endpoint->get_value() && out_range_min_endpoint->get_value()->get_type() == CValue::FLOAT );
		assert( out_range_max_endpoint->get_value() && out_range_max_endpoint->get_value()->get_type() == CValue::FLOAT );
		assert( out_scale_endpoint->get_value() && out_scale_endpoint->get_value()->get_type() == CValue::STRING );
		assert( out_value_endpoint->get_value() && out_value_endpoint->get_value()->get_type() == CValue::FLOAT );

		float in_range_min = *in_range_min_endpoint->get_value();
		float in_range_max = *in_range_max_endpoint->get_value();
		float out_range_min = *out_range_min_endpoint->get_value();
		float out_range_max = *out_range_max_endpoint->get_value();

		float in_range_total = in_range_max - in_range_min;
		float out_range_total = out_range_max - out_range_min;

		if( fabs( in_range_total ) < FLT_EPSILON)
		{
			/*
			Special case for input range ~= 0, to prevent division by zero errors or unusual behaviour arising from 
			floating point inaccuracy when dividing by a very tiny number.
		
			In this case setting the in_range_total to 1 will result in predictable and acceptable behaviour
			*/
			in_range_total = 1;
		}

		/*restrict to input range*/
		float input_value = value;
		const string &input_mode = *in_mode_endpoint->get_value();
		if( input_mode == mode_snap )
		{
			input_value = MAX( input_value, MIN( in_range_min, in_range_max ) );
			input_value = MIN( input_value, MAX( in_range_min, in_range_max ) );
		}
		else
		{
			assert( input_mode == mode_ignore );
			if( input_value < in_range_min || input_value > in_range_max )
			{
				return;
			}
		}

		/* perform input scaling */
		float unit_value( 0 );
		const string &input_scale = *in_scale_endpoint->get_value();
		if( input_scale == scale_linear )
		{
			unit_value = linearInputToUnit( input_value, in_range_min, in_range_total );
		}
		else
		{
			if( input_scale == scale_exponential )
			{
				unit_value = exponentialInputToUnit( input_value, in_range_min, in_range_total );
			}
			else
			{
				assert( input_scale == scale_decibel );
				unit_value = decibelInputToUnit( input_value, in_range_min, in_range_total );
			}
		}

		/* 
		 scaling functions might return slightly out-of-range outputs due to floating point rounding errors.  
		 put them back into range here
		*/

		if( unit_value < 0 ) 
		{
			unit_value = 0;
		}

		if( unit_value > 1 ) 
		{
			unit_value = 1;
		}

		/* perform output scaling */
		float output_value( 0 );
		const string &output_scale = *out_scale_endpoint->get_value();
		if( output_scale == scale_linear )
		{
			output_value = unitToLinearOutput( unit_value, out_range_min, out_range_total );
		}
		else
		{
			if( output_scale == scale_exponential )
			{
				output_value = unitToExponentialOutput( unit_value, out_range_min, out_range_total );
			}
			else
			{
				assert( output_scale == scale_decibel );
				output_value = unitToDecibelOutput( unit_value, out_range_min, out_range_total );
			}
		}

		/* 
		 scaling functions might return slightly out-of-range outputs due to floating point rounding errors.  
		 put them back into range here
		*/

		float output_minimum = MIN( out_range_min, out_range_max );
		if( output_value < output_minimum ) 
		{
			output_value = output_minimum;
		}

		float output_maximum = MAX( out_range_min, out_range_max );
		if( output_value > output_maximum ) 
		{
			output_value = output_maximum;
		}

		/*store result*/
		server.process_command( ISetCommand::create( out_value_endpoint->get_path(), CFloatValue( output_value ) ), CCommandSource::SYSTEM );
	}


	float CScalerLogic::linearInputToUnit( float input, float input_minimum, float input_range ) const
	{
		assert( ( input >= input_minimum && input <= input_minimum + input_range ) || 
			    (input <= input_minimum && input >= input_minimum + input_range ) );

		assert( fabs( input_range ) >= FLT_EPSILON );

		return ( input - input_minimum ) / input_range;
	}


	float CScalerLogic::exponentialInputToUnit( float input, float input_minimum, float input_range ) const
	{
		assert( ( input >= input_minimum && input <= input_minimum + input_range ) || 
			    (input <= input_minimum && input >= input_minimum + input_range ) );

		const float ln2_inverse = 1.4426950408889634073599246810019f;

		float input_maximum( input_minimum + input_range );
		bool invert( false );
		if( input_maximum < input_minimum )
		{
			invert = true;
			input_minimum = input_maximum;
			input_maximum -= input_range;
		}

		if( input_minimum <= 0 )
		{
			INTEGRA_TRACE_ERROR << "Can't perform exponential scaling on non-positive range";
			return 0;
		}

		float log_minimum = log( input_minimum ) * ln2_inverse;
		float log_maximum = log( input_maximum ) * ln2_inverse;
			
		assert( log_maximum > log_minimum );
			
		float unit = ( log( input ) * ln2_inverse - log_minimum ) / ( log_maximum - log_minimum );

		if( invert )
		{
			unit = 1 - unit;
		}

		return unit;
	}


	float CScalerLogic::decibelInputToUnit( float input, float input_minimum, float input_range ) const
	{
		assert( ( input >= input_minimum && input <= input_minimum + input_range ) || 
			    (input <= input_minimum && input >= input_minimum + input_range ) );

		float minimum = decibel_to_amplitude( input_minimum );
		float maximum = decibel_to_amplitude( input_minimum + input_range );
			
		assert( maximum != minimum );
			
		return ( decibel_to_amplitude( input ) - minimum ) / ( maximum - minimum ); 
	}


	float CScalerLogic::unitToLinearOutput( float unit, float output_minimum, float output_range ) const
	{
		assert( unit >= 0 && unit <= 1 );
		
		return unit * output_range + output_minimum;
	}


	float CScalerLogic::unitToExponentialOutput( float unit, float output_minimum, float output_range ) const
	{
		assert( unit >= 0 && unit <= 1 );

		const float root = 2.f;
		const float ln2_inverse = 1.4426950408889634073599246810019f;
			
		float output_maximum( output_minimum + output_range );
		if( output_maximum < output_minimum )
		{
			//invert
			unit = 1 - unit;
			output_minimum = output_maximum;
			output_maximum -= output_range;
		}

		if( output_maximum <= 0 )
		{
			INTEGRA_TRACE_ERROR << "Can't perform exponential scaling on non-positive range";
			return output_minimum;
		}			

		float log_minimum = log( output_minimum ) * ln2_inverse;
		float log_maximum = log( output_maximum ) * ln2_inverse;

		assert( log_maximum > log_minimum );
			
		return pow( root, unit * ( log_maximum - log_minimum ) + log_minimum );
	}


	float CScalerLogic::unitToDecibelOutput( float unit, float output_minimum, float output_range ) const
	{
		assert( unit >= 0 && unit <= 1 );

		float minimum_amplitude = decibel_to_amplitude( output_minimum );
		float maximum_amplitude = decibel_to_amplitude( output_minimum + output_range );

		return amplitude_to_decibel( unit * ( maximum_amplitude - minimum_amplitude ) + minimum_amplitude );
	}


	float CScalerLogic::decibel_to_amplitude( float decibel ) const
	{
		return pow( 10.f, decibel * 0.1f );
	}


	float CScalerLogic::amplitude_to_decibel( float amplitude ) const
	{
		const float ln10_inverse = 0.43429448190325182765112891891661f;

		assert( amplitude > 0 );

		return 10.f * log( amplitude ) * ln10_inverse;
	}

}
