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



#ifndef INTEGRA_SCALER_LOGIC_PRIVATE
#define INTEGRA_SCALER_LOGIC_PRIVATE

#include "logic.h"


namespace integra_internal
{
	class CScalerLogic : public CLogic
	{
		public:
			CScalerLogic( const CNode &node );
			~CScalerLogic();

			void handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source );

		private:

			void value_handler( CServer &server, const CValue &value );

			float linearInputToUnit( float input, float input_minimum, float input_range ) const;
			float exponentialInputToUnit( float input, float input_minimum, float input_range ) const;
			float decibelInputToUnit( float input, float input_minimum, float input_range ) const;

			float unitToLinearOutput( float unit, float output_minimum, float output_range ) const;
			float unitToExponentialOutput( float unit, float output_minimum, float output_range ) const;
			float unitToDecibelOutput( float unit, float output_minimum, float output_range ) const;

			float decibel_to_amplitude( float decibel ) const;
			float amplitude_to_decibel( float amplitude ) const;

			const static string endpoint_in_value;
			const static string endpoint_out_value;
			const static string endpoint_in_range_min;
			const static string endpoint_in_range_max;
			const static string endpoint_in_mode;
			const static string endpoint_in_scale;
			const static string endpoint_out_range_min;
			const static string endpoint_out_range_max;
			const static string endpoint_out_scale;

			const static string mode_snap;
			const static string mode_ignore;

			const static string scale_linear;
			const static string scale_exponential;
			const static string scale_decibel;
	};
}



#endif /*INTEGRA_SCALER_LOGIC_PRIVATE*/