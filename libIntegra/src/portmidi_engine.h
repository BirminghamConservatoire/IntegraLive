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

			CError set_input_devices( const string_vector &input_devices );
			CError set_output_devices( const string_vector &output_devices );

			CError restore_defaults();

			string_vector get_available_input_devices() const;
			string_vector get_available_output_devices() const;

			string_vector get_active_input_devices() const;
			string_vector get_active_output_devices() const;

			CError poll_input( midi_input_buffer_array &input_buffers );

			CError send_midi_message( const string &device_name, unsigned int message );
			CError send_midi_message( int device_index, unsigned int message );

		private:

			class CMidiDevice
			{
				public:
					CMidiDevice() { id = pmNoDevice; stream = NULL; }

					PmDeviceID id;
					string name;
					PortMidiStream *stream;
			};

			typedef std::map<PmDeviceID, string> device_map;
			typedef std::vector<CMidiDevice> device_vector;

			void find_available_devices();

			CError set_input_devices_to_default();
			CError set_output_devices_to_default();

			string_vector device_map_to_string_vector( const device_map &devices ) const;

			PmDeviceID get_device_id( const device_map &device_map, const string &device_name ) const;
			bool is_device_open( const device_vector &devices, PmDeviceID device_id ) const;
			bool is_device_open( const device_vector &devices, const string &device_name ) const;

			CError open_input_device( PmDeviceID device_id );
			CError open_output_device( PmDeviceID device_id );

			void close_input_devices();
			void close_output_devices();

			bool m_initialized_ok;

			device_map m_available_input_devices;
			device_map m_available_output_devices;

			device_vector m_active_input_devices;
			device_vector m_active_output_devices;

			pthread_mutex_t m_input_mutex;
			pthread_mutex_t m_output_mutex;

			PmEvent *m_input_event_buffer;
	};
}



#endif /* INTEGRA_PORT_MIDI_ENGINE_H */