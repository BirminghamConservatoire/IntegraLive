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

		m_new_active_midi_input_devices = NULL;
	}


	CMidiInputDispatcher::~CMidiInputDispatcher()
	{
		delete m_message_queue;

		if( m_new_active_midi_input_devices ) 
		{
			delete m_new_active_midi_input_devices;
		}

		for( midi_input_filter_map::iterator i = m_midi_input_filters.begin(); i != m_midi_input_filters.end(); i++ )
		{
			delete i->second;
		}

		m_midi_input_filters.clear();
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
		midi_message_list filtered_items;
		make_filtered_items( items, filtered_items );

		if( filtered_items.empty() )
		{
			return;
		}

		if( !m_server.lock() )
		{
			return;
		}

		for( midi_input_receiver_set::iterator i = m_midi_receivers.begin(); i != m_midi_receivers.end(); i++ )
		{
			IMidiInputReceiver *receiver = *i;
			receiver->receive_midi_input( m_server, filtered_items );
		}

		// if the set of active input devices has changed, we prune our filter map when we've got a server lock
		if( m_new_active_midi_input_devices )
		{
			for( midi_input_filter_map::iterator i = m_midi_input_filters.begin(); i != m_midi_input_filters.end(); )
			{
				bool device_still_active = ( std::find( m_new_active_midi_input_devices->begin(), m_new_active_midi_input_devices->end(), i->first ) != m_new_active_midi_input_devices->end() );

				if( device_still_active )
				{
					i++;
				}
				else
				{
					delete i->second;
					i = m_midi_input_filters.erase( i );
				}
			}

			delete m_new_active_midi_input_devices;
			m_new_active_midi_input_devices = NULL;
		}

		m_server.unlock();
	}


	void CMidiInputDispatcher::make_filtered_items( const midi_message_list &items, midi_message_list &filtered_items )
	{
		for( midi_input_filter_map::iterator i = m_midi_input_filters.begin(); i != m_midi_input_filters.end(); i++ )
		{
			i->second->reset();
		}

		for( midi_message_list::const_reverse_iterator i = items.rbegin(); i != items.rend(); i++ )
		{
			CMidiInputFilterer *filterer( NULL );
			if( m_midi_input_filters.count( i->device ) == 0 )
			{
				filterer = new CMidiInputFilterer();
				filterer->reset();
				m_midi_input_filters[ i->device ] = filterer;
			}
			else
			{
				filterer = m_midi_input_filters.at( i->device );
			}

			if( filterer->should_include( i->message ) )
			{
				filtered_items.push_front( *i );
			}
		}
	}


	void CMidiInputDispatcher::set_active_midi_input_devices( const string_vector &active_midi_input_devices )
	{
		if( !m_new_active_midi_input_devices )
		{
			m_new_active_midi_input_devices = new string_vector;
		}

		*m_new_active_midi_input_devices = active_midi_input_devices;
	}
}

