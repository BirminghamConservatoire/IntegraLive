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



#ifndef INTEGRA_MIDI_RAW_INPUT_LOGIC_PRIVATE
#define INTEGRA_MIDI_RAW_INPUT_LOGIC_PRIVATE

#include "logic.h"
#include "midi_input_dispatcher.h"


namespace integra_internal
{
	class CMidiRawInputLogic : public CLogic, IMidiInputReceiver
	{
		public:
			CMidiRawInputLogic( const CNode &node );
			~CMidiRawInputLogic();

			void handle_new( CServer &server, CCommandSource source );
			void handle_delete( CServer &server, CCommandSource source );

			void receive_midi_input( CServer &server, const midi_message_list &midi_messages );

	private:

			const static string endpoint_midi_message;
	};
}



#endif /*INTEGRA_MIDI_RAW_INPUT_LOGIC_PRIVATE*/