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

#include "audio_settings_logic.h"
#include "node_endpoint.h"
#include "interface_definition.h"
#include "server.h"
#include "node.h"
#include "audio_engine.h"

#include "api/string_helper.h"
#include "api/command.h"

#include "assert.h"


namespace integra_internal
{
	const string CAudioSettingsLogic::endpoint_available_drivers = "availableDrivers";
	const string CAudioSettingsLogic::endpoint_available_input_devices = "availableInputDevices";
	const string CAudioSettingsLogic::endpoint_available_output_devices = "availableOutputDevices";
	const string CAudioSettingsLogic::endpoint_available_sample_rates = "availableSampleRates";
	const string CAudioSettingsLogic::endpoint_selected_driver = "selectedDriver";
	const string CAudioSettingsLogic::endpoint_selected_input_device = "selectedInputDevice";
	const string CAudioSettingsLogic::endpoint_selected_output_device = "selectedOutputDevice";
	const string CAudioSettingsLogic::endpoint_sample_rate = "sampleRate";
	const string CAudioSettingsLogic::endpoint_input_channels = "inputChannels";
	const string CAudioSettingsLogic::endpoint_output_channels = "outputChannels";
	const string CAudioSettingsLogic::endpoint_restore_defaults = "restoreDefaults";

	CAudioSettingsLogic::audio_settings_logic_set CAudioSettingsLogic::s_all_audio_settings_logics;


	CAudioSettingsLogic::CAudioSettingsLogic( const CNode &node )
		:	CLogic( node )
	{
		s_all_audio_settings_logics.insert( this );
	}


	CAudioSettingsLogic::~CAudioSettingsLogic()
	{
		s_all_audio_settings_logics.erase( this );
	}

	
	void CAudioSettingsLogic::handle_new( CServer &server, CCommandSource source )
	{
		CLogic::handle_new( server, source );

		update_all_fields( server );

		if( source == CCommandSource::PUBLIC_API )
		{
			CPath restore_endpoint( get_node().get_path() );
			restore_endpoint.append_element( endpoint_restore_defaults );
			server.process_command( ISetCommand::create( restore_endpoint, NULL ), CCommandSource::SYSTEM );
		}
	}


	void CAudioSettingsLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source )
	{
		CLogic::handle_set( server, node_endpoint, previous_value, source );

		const string &endpoint_name = node_endpoint.get_endpoint_definition().get_name();
		IAudioEngine &audio_engine = server.get_audio_engine();

		if( endpoint_name == endpoint_restore_defaults )
		{
			audio_engine.restore_defaults();

			update_all_fields_for_all_audio_settings_nodes( server );
			return;
		}

		switch( source )
		{
			case CCommandSource::INITIALIZATION:
			case CCommandSource::SYSTEM:
				return;
		}

		if( endpoint_name == endpoint_selected_driver )
		{
			audio_engine.set_driver( *node_endpoint.get_value() );

			update_all_fields_for_all_audio_settings_nodes( server );
			return;
		}

		if( endpoint_name == endpoint_selected_input_device )
		{
			audio_engine.set_input_device( *node_endpoint.get_value() );

			update_all_fields_for_all_audio_settings_nodes( server );
			return;
		}

		if( endpoint_name == endpoint_selected_output_device )
		{
			audio_engine.set_output_device( *node_endpoint.get_value() );

			update_all_fields_for_all_audio_settings_nodes( server );
			return;
		}

		if( endpoint_name == endpoint_sample_rate )
		{
			audio_engine.set_sample_rate( *node_endpoint.get_value() );

			//todo - set sample rate in dsp engine too!

			update_all_fields_for_all_audio_settings_nodes( server );
			return;
		}

		if( endpoint_name == endpoint_input_channels )
		{
			audio_engine.set_number_of_input_channels( *node_endpoint.get_value() );

			//todo - set number of input channels in dsp engine too!

			update_all_fields_for_all_audio_settings_nodes( server );
			return;
		}

		if( endpoint_name == endpoint_output_channels )
		{
			audio_engine.set_number_of_output_channels( *node_endpoint.get_value() );

			//todo - set number of input channels in dsp engine too!

			update_all_fields_for_all_audio_settings_nodes( server );
			return;
		}
	}


	void CAudioSettingsLogic::update_all_fields( CServer &server )
	{
		const IAudioEngine &audio_engine = server.get_audio_engine();

		update_string_field( server, endpoint_available_drivers, CStringHelper::string_vector_to_string( audio_engine.get_available_drivers() ) );
		update_string_field( server, endpoint_available_input_devices, CStringHelper::string_vector_to_string( audio_engine.get_available_input_devices() ) );
		update_string_field( server, endpoint_available_output_devices, CStringHelper::string_vector_to_string( audio_engine.get_available_output_devices() ) );
		update_string_field( server, endpoint_available_sample_rates, CStringHelper::string_vector_to_string( int_vector_to_string_vector( audio_engine.get_available_sample_rates() ) ) );

		update_string_field( server, endpoint_selected_driver, audio_engine.get_selected_driver() );
		update_string_field( server, endpoint_selected_input_device, audio_engine.get_selected_input_device() );
		update_string_field( server, endpoint_selected_output_device, audio_engine.get_selected_output_device() );

		update_integer_field( server, endpoint_sample_rate, audio_engine.get_sample_rate() );
		update_integer_field( server, endpoint_input_channels, audio_engine.get_number_of_input_channels() );
		update_integer_field( server, endpoint_output_channels, audio_engine.get_number_of_output_channels() );
	}


	void CAudioSettingsLogic::update_string_field( CServer &server, const string &endpoint_name, const string &new_value )
	{
		const CNode &node = get_node();

		const INodeEndpoint *endpoint = node.get_node_endpoint( endpoint_name );
		assert( endpoint );
		if( new_value != ( const string & ) *endpoint->get_value() )
		{
			server.process_command( ISetCommand::create( endpoint->get_path(), &CStringValue( new_value ) ), CCommandSource::SYSTEM );
		}
	}


	void CAudioSettingsLogic::update_integer_field( CServer &server, const string &endpoint_name, int new_value )
	{
		const CNode &node = get_node();

		const INodeEndpoint *endpoint = node.get_node_endpoint( endpoint_name );
		assert( endpoint );
		if( new_value != ( int ) *endpoint->get_value() )
		{
			server.process_command( ISetCommand::create( endpoint->get_path(), &CIntegerValue( new_value ) ), CCommandSource::SYSTEM );
		}
	}


	string_vector CAudioSettingsLogic::int_vector_to_string_vector( const int_vector &input )
	{
		string_vector result;

		for( int_vector::const_iterator i = input.begin(); i != input.end(); i++ )
		{
			ostringstream stream;
			stream << *i;
			result.push_back( stream.str() );
		}

		return result;
	}


	void CAudioSettingsLogic::update_all_fields_for_all_audio_settings_nodes( CServer &server )
	{
		for( audio_settings_logic_set::iterator i = s_all_audio_settings_logics.begin(); i != s_all_audio_settings_logics.end(); i++ )
		{
			( *i )->update_all_fields( server );
		}
	}
}
