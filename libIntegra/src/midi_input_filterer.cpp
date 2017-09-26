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

#include "midi_input_filterer.h"


namespace integra_internal
{
	CMidiInputFilterer::CMidiInputFilterer()
	{
		m_created_buffers = false;

		m_got_poly_pressure = NULL;
		m_got_control_change = NULL;
		m_got_channel_pressure = NULL;
		m_got_pitchbend = NULL;
	}


	CMidiInputFilterer::~CMidiInputFilterer()
	{
		if( m_created_buffers )
		{
			destroy_buffers();
		}
	}


	void CMidiInputFilterer::create_buffers()
	{
		assert( !m_created_buffers );

		m_got_poly_pressure = new bool[ number_of_midi_channels * number_of_notes ];
		m_got_control_change = new bool[ number_of_midi_channels * number_of_notes ];
		m_got_channel_pressure = new bool[ number_of_midi_channels ];
		m_got_pitchbend = new bool[ number_of_midi_channels ];

		m_created_buffers = true;
	}


	void CMidiInputFilterer::destroy_buffers()
	{
		assert( m_created_buffers );

		delete [] m_got_poly_pressure;
		delete [] m_got_control_change;
		delete [] m_got_channel_pressure;
		delete [] m_got_pitchbend;

		m_created_buffers = false;
	}


	void CMidiInputFilterer::filter_input( midi_input_buffer_array &input_buffers )
	{
		for( midi_input_buffer_array::iterator device_iterator = input_buffers.begin(); device_iterator != input_buffers.end(); device_iterator++ )
		{
			if( device_iterator->number_of_messages == 0 )
			{
				continue;
			}

			//clear caches
			reset();

			//iterate backwards through messages, setting them to 0 if they are replaced by a later message
			for( int message_iterator = device_iterator->number_of_messages - 1; message_iterator >= 0; message_iterator -- )
			{
				unsigned int &message = device_iterator->messages[ message_iterator ];

				if( !should_include( message ) )
				{
					//mark the message as 'filtered'
					message = 0;
				}
			}
		}
	}


	void CMidiInputFilterer::reset()
	{
		if( !m_created_buffers )
		{
			create_buffers();
		}

		memset( m_got_poly_pressure, 0, number_of_midi_channels * number_of_notes * sizeof( bool ) );
		memset( m_got_control_change, 0, number_of_midi_channels * number_of_notes * sizeof( bool ) );
		memset( m_got_channel_pressure, 0, number_of_midi_channels * sizeof( bool ) );
		memset( m_got_pitchbend, 0, number_of_midi_channels * sizeof( bool ) );
	}


	bool CMidiInputFilterer::should_include( unsigned int message )
	{
		assert( m_created_buffers );

		unsigned int status_nibble = ( message & 0xF0 ) >> 4;
		assert( status_nibble >= 0 && status_nibble << 0xF );
		if( status_nibble < 0x8 )
		{
			INTEGRA_TRACE_ERROR << "Unexpected status nibble - should begin with 1: " << std::hex << message;
			return false;
		}

		unsigned int channel_nibble = message & 0xF;
		assert( channel_nibble >= 0 && channel_nibble <= 0xF );

		unsigned int value1 = ( message & 0xFF00 ) >> 8;
		unsigned int value2 = ( message & 0xFF0000 ) >> 16;

		if( value1 >= 0x80 )
		{
			INTEGRA_TRACE_ERROR << "Unexpected value 1 - should begin with 0: " << std::hex << message;
			return false;
		}

		if( value2 >= 0x80 )
		{
			INTEGRA_TRACE_ERROR << "Unexpected value 2 - should begin with 0: " << std::hex << message;
			return false;

		}

		bool *got_it_already_flag = NULL;

		switch( status_nibble )
		{
			case 0xA:	/* polyphonic key pressure */
				got_it_already_flag = &( m_got_poly_pressure[ channel_nibble * number_of_notes + value1 ] );
				break;

			case 0xB:	/* control change */
				got_it_already_flag = &( m_got_control_change[ channel_nibble * number_of_notes + value1 ] );
				break;

			case 0xD:	/* channel pressure */
				got_it_already_flag = &( m_got_channel_pressure[ channel_nibble ] );
				break;

			case 0xE:	/* pitchbend */
				got_it_already_flag = &( m_got_pitchbend[ channel_nibble ] );
				break;

			case 0x8:	/* note off */
			case 0x9:	/* note on */
			case 0xC:	/* program change */
				//don't ever filter these messages
				return true;							

			case 0xF:
				INTEGRA_TRACE_ERROR << "Unexpected system common / realtime message: " << std::hex << message;
				return false;
		}

		assert( got_it_already_flag );

		//if we've encountered one of these already (ie later, since this method must be called with a backwards series)
		if( *got_it_already_flag )
		{
			return false;
		}
		else
		{
			*got_it_already_flag = true;
			return true;
		}
	}
}

