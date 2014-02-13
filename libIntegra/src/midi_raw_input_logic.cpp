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

#include "midi_raw_input_logic.h"
#include "api/command.h"
#include "server.h"


namespace integra_internal
{
	const string CMidiRawInputLogic::endpoint_midi_message = "midiMessage";


	CMidiRawInputLogic::CMidiRawInputLogic( const CNode &node )
		:	CLogic( node )
	{
	}


	CMidiRawInputLogic::~CMidiRawInputLogic()
	{
	}


	void CMidiRawInputLogic::handle_new( CServer &server, CCommandSource source )
	{
		CLogic::handle_new( server, source );

		server.get_midi_input_dispatcher().register_input_receiver( this );
	}


	void CMidiRawInputLogic::handle_delete( CServer &server, CCommandSource source )
	{
		CLogic::handle_delete( server, source );

		server.get_midi_input_dispatcher().unregister_input_receiver( this );
	}


	void CMidiRawInputLogic::receive_midi_input( CServer &server, const midi_message_list &midi_messages )
	{
		const CNode &node = get_node();

		const INodeEndpoint *active = node.get_node_endpoint( endpoint_active );
		assert( active );
		if( ( int ) *active->get_value() == 0 )
		{
			return;
		}

		const INodeEndpoint *midi_message_endpoint = node.get_node_endpoint( endpoint_midi_message );
		assert( midi_message_endpoint );

		for( midi_message_list::const_iterator i = midi_messages.begin(); i != midi_messages.end(); i++ )
		{
			server.process_command( ISetCommand::create( midi_message_endpoint->get_path(), CIntegerValue( i->message ) ), CCommandSource::SYSTEM );
		}
	}
}
