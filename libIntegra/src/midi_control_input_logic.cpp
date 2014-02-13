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

#include "midi_control_input_logic.h"
#include "api/command.h"
#include "server.h"


namespace integra_internal
{
	const string CMidiControlInputLogic::endpoint_device = "device";
	const string CMidiControlInputLogic::endpoint_channel = "channel";
	const string CMidiControlInputLogic::endpoint_message_type = "messageType";
	const string CMidiControlInputLogic::endpoint_note_or_controller = "noteOrController";
	const string CMidiControlInputLogic::endpoint_value = "value";
	const string CMidiControlInputLogic::endpoint_auto_learn = "autoLearn";

	const string CMidiControlInputLogic::note_on = "noteon";
	const string CMidiControlInputLogic::control_change = "cc";


	CMidiControlInputLogic::CMidiControlInputLogic( const CNode &node )
		:	CLogic( node )
	{
	}


	CMidiControlInputLogic::~CMidiControlInputLogic()
	{
	}


	void CMidiControlInputLogic::handle_new( CServer &server, CCommandSource source )
	{
		CLogic::handle_new( server, source );

		server.get_midi_input_dispatcher().register_input_receiver( this );
	}


	void CMidiControlInputLogic::handle_delete( CServer &server, CCommandSource source )
	{
		CLogic::handle_delete( server, source );

		server.get_midi_input_dispatcher().unregister_input_receiver( this );
	}


	void CMidiControlInputLogic::receive_midi_input( CServer &server, const midi_message_list &midi_messages )
	{
		const CNode &node = get_node();

		const INodeEndpoint *active = node.get_node_endpoint( endpoint_active );
		assert( active );
		if( ( int ) *active->get_value() == 0 )
		{
			return;
		}

		const INodeEndpoint *device_endpoint = node.get_node_endpoint( endpoint_device );
		const INodeEndpoint *channel_endpoint = node.get_node_endpoint( endpoint_channel );
		const INodeEndpoint *message_type_endpoint = node.get_node_endpoint( endpoint_message_type );
		const INodeEndpoint *note_or_controller_endpoint = node.get_node_endpoint( endpoint_note_or_controller );
		const INodeEndpoint *value_endpoint = node.get_node_endpoint( endpoint_value );
		const INodeEndpoint *auto_learn_endpoint = node.get_node_endpoint( endpoint_auto_learn );

		assert( device_endpoint && channel_endpoint && message_type_endpoint && note_or_controller_endpoint && value_endpoint && auto_learn_endpoint );

		for( midi_message_list::const_iterator message_iterator = midi_messages.begin(); message_iterator != midi_messages.end(); message_iterator++ )
		{
			const string &device_name = message_iterator->device;
			unsigned int message = message_iterator->message;

			unsigned int status = ( message & 0xF0 ) >> 4;
			assert( status >= 0x8 && status << 0xF );

			unsigned int channel = ( message & 0xF ) + 1;
			assert( channel >= 1 && channel <= 16 );

			unsigned int value1 = ( message & 0xFF00 ) >> 8;
			unsigned int value2 = ( message & 0xFF0000 ) >> 16;
			assert( value1 < 128 && value2 < 128 );

			const string *message_type = NULL;
			switch( status )
			{
				case 0x9:	/* note on */
					if( value2 == 0 )
					{
						//note-off due to zero velocity - skip
						continue;
					}
					message_type = &note_on;
					break;
					
				case 0xB:	/* control change */
					message_type = &control_change;
					break;

				default:
					continue;
			}

			assert( message_type );

			if( ( int ) *auto_learn_endpoint->get_value() == 1 )
			{
				//do autolearn
				server.process_command( ISetCommand::create( device_endpoint->get_path(), CStringValue( device_name ) ), CCommandSource::SYSTEM );
				server.process_command( ISetCommand::create( channel_endpoint->get_path(), CIntegerValue( channel ) ), CCommandSource::SYSTEM );
				server.process_command( ISetCommand::create( message_type_endpoint->get_path(), CStringValue( *message_type ) ), CCommandSource::SYSTEM );
				server.process_command( ISetCommand::create( note_or_controller_endpoint->get_path(), CIntegerValue( value1 ) ), CCommandSource::SYSTEM );

				//end autolearn mode
				server.process_command( ISetCommand::create( auto_learn_endpoint->get_path(), CIntegerValue( 0 ) ), CCommandSource::SYSTEM );
			}

			/* now skip message if it's not the type we're interested in */
			if( ( const string & ) *device_endpoint->get_value() != device_name )
			{
				continue;
			}

			if( ( int ) *channel_endpoint->get_value() != channel )
			{
				continue;
			}

			if( (const string &) *message_type_endpoint->get_value() != *message_type )
			{
				continue;
			}

			if( ( int ) *note_or_controller_endpoint->get_value() != value1 )
			{
				continue;
			}

			/* if we get here, it _is_ the type of message we're interested in */
			server.process_command( ISetCommand::create( value_endpoint->get_path(), CIntegerValue( value2 ) ), CCommandSource::SYSTEM );

		}

	}


}
