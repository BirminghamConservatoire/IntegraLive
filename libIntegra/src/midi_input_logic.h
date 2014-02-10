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



#ifndef INTEGRA_MIDI_INPUT_LOGIC_PRIVATE
#define INTEGRA_MIDI_INPUT_LOGIC_PRIVATE

#include "logic.h"
#include "midi_input_dispatcher.h"


namespace integra_internal
{
	class CMidiInputLogic : public CLogic, IMidiInputReceiver
	{
		public:
			CMidiInputLogic( const CNode &node );
			~CMidiInputLogic();

			void handle_new( CServer &server, CCommandSource source );
			void handle_delete( CServer &server, CCommandSource source );

			void receive_midi_input( CServer &server, const midi_message_list &midi_messages );

	private:

			const static string endpoint_device;
			const static string endpoint_channel;
			const static string endpoint_message_type;
			const static string endpoint_note_or_controller;
			const static string endpoint_value;
			const static string endpoint_auto_learn;

			const static string note_on;
			const static string control_change;
	};
}



#endif /*INTEGRA_MIDI_INPUT_LOGIC_PRIVATE*/