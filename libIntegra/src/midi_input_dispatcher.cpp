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

#include "midi_input_dispatcher.h"
#include "server.h"


namespace integra_internal
{
	CMidiInputDispatcher::CMidiInputDispatcher( CServer &server )
		:	m_server( server )
	{
		m_message_queue = new CThreadedQueue<CMidiMessage>( *this );

	}


	CMidiInputDispatcher::~CMidiInputDispatcher()
	{
		delete m_message_queue;
	}


	CError CMidiInputDispatcher::register_input_receiver( IMidiInputReceiver *receiver )
	{
		if( m_midi_receivers.count( receiver ) > 0 )
		{
			INTEGRA_TRACE_ERROR << "Attempting to register same midi input receiver twice!";
			return CError::FAILED;
		}

		m_midi_receivers.insert( receiver );
		return CError::SUCCESS;
	}


	CError CMidiInputDispatcher::unregister_input_receiver( IMidiInputReceiver *receiver )
	{
		if( m_midi_receivers.count( receiver ) == 0 )
		{
			INTEGRA_TRACE_ERROR << "midi input receiver not registered - can't unregister!";
			return CError::FAILED;
		}

		m_midi_receivers.erase( receiver );
		return CError::SUCCESS;
	}

	void CMidiInputDispatcher::dispatch_midi( const midi_message_list &items )
	{
		m_message_queue->push( items );
	}


	void CMidiInputDispatcher::handle_queue_items( const midi_message_list &items )
	{
		m_server.lock();

		for( midi_input_receiver_set::iterator i = m_midi_receivers.begin(); i != m_midi_receivers.end(); i++ )
		{
			IMidiInputReceiver *receiver = *i;
			receiver->receive_midi_input( m_server, items );
		}

		m_server.unlock();
	}
}

