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


#ifndef INTEGRA_PORT_MIDI_ENGINE_H
#define INTEGRA_PORT_MIDI_ENGINE_H

#include "midi_engine.h"
#include "portmidi.h"

#include <pthread.h>

#include <map>


namespace integra_internal
{
	class CPortMidiEngine : public IMidiEngine
	{
		public:

			CPortMidiEngine();
			~CPortMidiEngine();

			CError set_input_device( const string &input_device );
			CError set_output_device( const string &output_device );

			CError restore_defaults();

			string_vector get_available_input_devices() const;
			string_vector get_available_output_devices() const;

			string get_selected_input_device() const;
			string get_selected_output_device() const;

			CError get_incoming_midi_messages( unsigned int *&messages, int &number_of_messages );

			CError send_midi_message( unsigned int message );

		private:

			typedef std::map<PmDeviceID, string> device_map;

			void find_available_devices();

			CError set_input_device_to_default();
			CError set_output_device_to_default();

			string_vector device_map_to_string_vector( const device_map &devices ) const;

			PmDeviceID get_device_id( const device_map &device_map, const string &device_name ) const;

			void open_input_device( PmDeviceID device_id );
			void open_output_device( PmDeviceID device_id );

			void close_input_device();
			void close_output_device();

			CError get_incoming_midi_messages_inner( unsigned int *&messages, int &number_of_messages );

			bool m_initialized_ok;

			device_map m_available_input_devices;
			device_map m_available_output_devices;

			PmDeviceID m_current_input_device_id;
			PmDeviceID m_current_output_device_id;

			PortMidiStream *m_input_stream;
			PortMidiStream *m_output_stream;

			pthread_mutex_t m_input_mutex;
			pthread_mutex_t m_output_mutex;

			PmEvent *m_input_event_buffer;
			unsigned int *m_input_message_buffer;



			static const string none;
			static const int input_buffer_size;
	};
}



#endif /* INTEGRA_PORT_MIDI_ENGINE_H */