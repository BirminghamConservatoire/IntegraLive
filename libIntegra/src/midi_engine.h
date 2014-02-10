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


#ifndef INTEGRA_MIDI_ENGINE_INTERFACE_H
#define INTEGRA_MIDI_ENGINE_INTERFACE_H

#include "api/common_typedefs.h"
#include "api/error.h"

#include <array>


using namespace integra_api;

namespace integra_internal
{
	class CDspEngine;
	class CMidiInputBuffer;

	typedef std::vector<CMidiInputBuffer> midi_input_buffer_array;



	class IMidiEngine
	{
		protected:

			IMidiEngine() {}

		public:

			static IMidiEngine *create_midi_engine();
			virtual ~IMidiEngine() {}

			/* the following methods must not be called simultaneously */

			virtual CError set_input_devices( const string_vector &input_devices ) = 0;
			virtual CError set_output_devices( const string_vector &output_devices ) = 0;

			virtual CError restore_defaults() = 0;

			virtual string_vector get_available_input_devices() const = 0;
			virtual string_vector get_available_output_devices() const = 0;

			virtual string_vector get_active_input_devices() const = 0;
			virtual string_vector get_active_output_devices() const = 0;

			/* the following methods can be called simultaneously to the methods above */

			/*
			 poll_input should only return the following message types:
			 Note On, Note Off, Channel Aftertouch, Poly Aftertouch, Program Change, Control Change, Pitchbend.
			*/

			virtual CError poll_input( midi_input_buffer_array &input_buffers ) = 0;

			virtual CError send_midi_message( const string &device_name, unsigned int message ) = 0;
			virtual CError send_midi_message( int device_index, unsigned int message ) = 0;
	};



	//helper to pass midi input out to customer of midi engine
	class CMidiInputBuffer
	{
		public:

			CMidiInputBuffer() { number_of_messages = 0; }

			static const int input_buffer_size = 1024;

			string device_name;

			/* messages set to '0' have been filtered by CMidiInputFilterer */
			std::array<unsigned int, input_buffer_size> messages;

			/* 
			 to avoid allocation/deallocation, the message array is of fixed size.  
			 number_of_messages specifies how many are actually used
			*/
			unsigned int number_of_messages;

	};
}



#endif /* INTEGRA_MIDI_ENGINE_INTERFACE_H */
