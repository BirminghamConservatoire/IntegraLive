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

#include "midi_settings_logic.h"
#include "node_endpoint.h"
#include "interface_definition.h"
#include "server.h"
#include "node.h"
#include "midi_engine.h"

#include "api/string_helper.h"
#include "api/command.h"
#include "api/trace.h"

#include "assert.h"


namespace integra_internal
{
	const string CMidiSettingsLogic::endpoint_available_input_devices = "availableInputDevices";
	const string CMidiSettingsLogic::endpoint_available_output_devices = "availableOutputDevices";
	const string CMidiSettingsLogic::endpoint_active_input_devices = "activeInputDevices";
	const string CMidiSettingsLogic::endpoint_active_output_devices = "activeOutputDevices";
	const string CMidiSettingsLogic::endpoint_restore_defaults = "restoreDefaults";

	CMidiSettingsLogic::midi_settings_logic_set CMidiSettingsLogic::s_all_midi_settings_logics;


	CMidiSettingsLogic::CMidiSettingsLogic( const CNode &node )
		:	CLogic( node )
	{
		s_all_midi_settings_logics.insert( this );
	}


	CMidiSettingsLogic::~CMidiSettingsLogic()
	{
		s_all_midi_settings_logics.erase( this );
	}

	
	void CMidiSettingsLogic::handle_new( CServer &server, CCommandSource source )
	{
		CLogic::handle_new( server, source );

		update_all_fields( server );

		if( source == CCommandSource::PUBLIC_API )
		{
			if( s_all_midi_settings_logics.size() == 1 )
			{
				//bang the 'restore defaults' endpoint if created by the public api (unless other settings objects already exist)
				CPath restore_endpoint( get_node().get_path() );
				restore_endpoint.append_element( endpoint_restore_defaults );
				server.process_command( ISetCommand::create( restore_endpoint ), CCommandSource::SYSTEM );
			}
		}
	}


	void CMidiSettingsLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source )
	{
		CLogic::handle_set( server, node_endpoint, previous_value, source );

		const string &endpoint_name = node_endpoint.get_endpoint_definition().get_name();
		IMidiEngine &midi_engine = server.get_midi_engine();

		if( endpoint_name == endpoint_restore_defaults )
		{
			midi_engine.restore_defaults();

			update_all_fields_for_all_midi_settings_nodes( server );
			return;
		}

		switch( source )
		{
			case CCommandSource::INITIALIZATION:
			case CCommandSource::SYSTEM:
				return;
		}

		if( endpoint_name == endpoint_active_input_devices )
		{
			const string &packed_devices = *node_endpoint.get_value();
			string_vector input_devices;
			if( !CStringHelper::string_to_string_vector( packed_devices, input_devices ) )
			{
				INTEGRA_TRACE_ERROR << "Misformatted packed string: " << packed_devices;
				return;
			}

			midi_engine.set_input_devices( input_devices );

			update_all_fields_for_all_midi_settings_nodes( server );
			return;
		}

		if( endpoint_name == endpoint_active_output_devices )
		{
			const string &packed_devices = *node_endpoint.get_value();
			string_vector output_devices;
			if( !CStringHelper::string_to_string_vector( packed_devices, output_devices ) )
			{
				INTEGRA_TRACE_ERROR << "Misformatted packed string: " << packed_devices;
				return;
			}

			midi_engine.set_output_devices( output_devices );

			update_all_fields_for_all_midi_settings_nodes( server );
			return;
		}
	}


	void CMidiSettingsLogic::update_all_fields( CServer &server )
	{
		const IMidiEngine &midi_engine = server.get_midi_engine();

		update_field( server, endpoint_available_input_devices, CStringHelper::string_vector_to_string( midi_engine.get_available_input_devices() ) );
		update_field( server, endpoint_available_output_devices, CStringHelper::string_vector_to_string( midi_engine.get_available_output_devices() ) );

		update_field( server, endpoint_active_input_devices, CStringHelper::string_vector_to_string( midi_engine.get_active_input_devices() ) );
		update_field( server, endpoint_active_output_devices, CStringHelper::string_vector_to_string( midi_engine.get_active_output_devices() ) );
	}


	void CMidiSettingsLogic::update_field( CServer &server, const string &endpoint_name, const string &new_value )
	{
		const CNode &node = get_node();

		const INodeEndpoint *endpoint = node.get_node_endpoint( endpoint_name );
		assert( endpoint );
		if( new_value != ( const string & ) *endpoint->get_value() )
		{
			server.process_command( ISetCommand::create( endpoint->get_path(), CStringValue( new_value ) ), CCommandSource::SYSTEM );
		}
	}


	void CMidiSettingsLogic::update_all_fields_for_all_midi_settings_nodes( CServer &server )
	{
		for( midi_settings_logic_set::iterator i = s_all_midi_settings_logics.begin(); i != s_all_midi_settings_logics.end(); i++ )
		{
			( *i )->update_all_fields( server );
		}
	}
}
