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


#ifndef INTEGRA_MIDI_INPUT_DISPATCHER_H
#define INTEGRA_MIDI_INPUT_DISPATCHER_H

#include "api/common_typedefs.h"
#include "api/error.h"
#include "threaded_queue.h"

using namespace integra_api;



namespace integra_internal
{
	class CServer;

	/* Stores a single midi message, together with the device it came from */
	class CMidiMessage
	{
		public:
			CMidiMessage() { message = 0; } 
		
			string device;
			unsigned int message;
	};

	typedef std::list<CMidiMessage> midi_message_list;

	/* Interface for callbacks from MidiInputDispatcher.  Subclassed by logic classes for midi */
	class IMidiInputReceiver
	{
		public:
			virtual void receive_midi_input( CServer &server, const midi_message_list &midi_messages ) = 0;
	};



	/* 
	 The Input Dispatcher.  Can receive midi in a low-latency dsp thread, dispatches to subclasses of
	 IMidiInputReceiver in a less time-critical thread with a locked server.
	*/

	class CMidiInputDispatcher : public IThreadedQueueOutputSink<CMidiMessage>
	{
		public:

			CMidiInputDispatcher( CServer &server );
			~CMidiInputDispatcher();

			CError register_input_receiver( IMidiInputReceiver *receiver );
			CError unregister_input_receiver( IMidiInputReceiver *receiver );


			/* called by CDspEngine */
			void dispatch_midi( const midi_message_list &items );


		private:

			void handle_queue_items( const midi_message_list &items );

			CServer &m_server;
			CThreadedQueue<CMidiMessage> *m_message_queue;

			typedef std::unordered_set<IMidiInputReceiver *> midi_input_receiver_set;
			midi_input_receiver_set m_midi_receivers;
	};
}



#endif /* INTEGRA_MIDI_INPUT_DISPATCHER */
