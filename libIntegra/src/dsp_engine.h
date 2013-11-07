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

#ifndef INTEGRA_DSP_ENGINE_H
#define INTEGRA_DSP_ENGINE_H

#include "api/common_typedefs.h"
#include "api/error.h"
#include "node.h"
#include "threaded_queue.h"

#include <pthread.h>

extern "C"	//test
{
	void expr_setup();		
}

namespace pd
{
	class PdBase;
	class List;
	struct Message;
}

namespace integra_api
{
	class ISetCommand;
}


namespace integra_internal
{
	class CServer;

	class CDspEngine : public IThreadedQueueOutputSink<pd::Message>
	{
		public:

			CDspEngine( CServer &server );
			~CDspEngine();

			CError add_module( internal_id id, const string &patch_path );
			CError remove_module( internal_id id );
			CError connect_modules( const CNodeEndpoint &source, const CNodeEndpoint &target );
			CError disconnect_modules( const CNodeEndpoint &source, const CNodeEndpoint &target );
			CError send_value( const CNodeEndpoint &target );

			void process_buffer( const float *input, float *output, int input_channels, int output_channels, int sample_rate );

			void dump_patch_to_file( const string &path );

			static const int samples_per_buffer;

		private:

			typedef std::list<pd::Message> pd_message_list;

			void setup_libpd();

			string get_patch_file_path() const;


			bool has_configuration_changed( int input_channels, int output_channels, int sample_rate ) const;

			bool is_configuration_valid() const;
			void initialize_audio_configuration( int input_channels, int output_channels, int sample_rate );

			void poll_for_messages();

			void create_host_patch();
			void delete_host_patch();

			void register_externals();

			CError connect_or_disconnect( const CNodeEndpoint &source, const CNodeEndpoint &target, const string &command );

			int get_patch_id( internal_id id ) const;
			int get_stream_connection_index( const CNodeEndpoint &node_endpoint ) const;

			void handle_queue_items( const pd_message_list &messages );
			void handle_feedback( const pd::Message &message );

			ISetCommand *make_set_command( const pd::List &feedback_arguments ) const;

			void test_map_sanity();

			pd::PdBase *m_pd;

			CServer &m_server;

			bool m_initialised;
			int m_input_channels;
			int m_output_channels;
			int m_sample_rate;

			pthread_mutex_t m_mutex;

			int m_next_module_y_slot;

			int_map m_map_id_to_patch_id;

			CThreadedQueue<pd::Message> *m_message_queue;

			static const int max_channels;
			static const string patch_file_name;
			static const string host_patch_name;
			static const string patch_message_target;

			static const string feedback_source;

			static const int module_x_margin;
			static const int module_y_spacing;
	};
}



#endif /* INTEGRA_DSP_ENGINE_H */
