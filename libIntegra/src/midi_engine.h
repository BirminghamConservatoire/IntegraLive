/* libIntegra multimedia module interface
 *  
 * Copyright (C) 2012 Birmingham City University
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


using namespace integra_api;

namespace integra_internal
{
	class CDspEngine;

	class IMidiEngine
	{
		protected:

			IMidiEngine() {}

		public:

			static IMidiEngine *create_midi_engine();
			virtual ~IMidiEngine() {}

			virtual CError set_input_device( const string &input_device ) = 0;
			virtual CError set_output_device( const string &output_device ) = 0;

			virtual CError restore_defaults() = 0;

			virtual string_vector get_available_input_devices() const = 0;
			virtual string_vector get_available_output_devices() const = 0;

			virtual string get_selected_input_device() const = 0;
			virtual string get_selected_output_device() const = 0;

			/*
			 Implementations should only return the following message types:
			 Note On, Note Off, Channel Aftertouch, Poly Aftertouch, Program Change, Control Change, Pitchbend.
			*/

			virtual CError get_incoming_midi_messages( unsigned int *&messages, int &number_of_messages ) = 0;

			virtual CError send_midi_message( unsigned int message ) = 0;


	};
}



#endif /* INTEGRA_MIDI_ENGINE_INTERFACE_H */
