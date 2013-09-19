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

#ifndef INTEGRA_PORT_AUDIO_ENGINE_H
#define INTEGRA_PORT_AUDIO_ENGINE_H

#include "audio_engine.h"
#include "portaudio.h"

#include <unordered_map>

namespace integra_internal
{
	class CPortAudioEngine : public IAudioEngine
	{
		friend int input_callback( const void *input_buffer, void *output_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags status_flags, void *user_data );
		friend int output_callback( const void *input_buffer, void *output_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags status_flags, void *user_data );
		friend int duplex_callback( const void *input_buffer, void *output_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags status_flags, void *user_data );

		public:

			CPortAudioEngine();
			~CPortAudioEngine();

			CError set_driver( const string &driver );
			CError set_input_device( const string &input_device );
			CError set_output_device( const string &output_device );

			CError set_sample_rate( int sample_rate );
			CError set_number_of_input_channels( int input_channels );
			CError set_number_of_output_channels( int output_channels );

			CError restore_defaults();

			string_vector get_available_drivers() const;
			string_vector get_available_input_devices() const;
			string_vector get_available_output_devices() const;
			int_vector get_available_sample_rates() const;

			string get_selected_driver() const;
			string get_selected_input_device() const;
			string get_selected_output_device() const;

			int get_sample_rate() const;
			int get_number_of_input_channels() const;
			int get_number_of_output_channels() const;

		private:

			typedef std::unordered_map<string, PaHostApiTypeId> api_map;
			typedef std::unordered_map<string, PaDeviceIndex> device_map;

			void update_available_apis();
			void update_available_devices();
			void update_available_sample_rates();

			string_vector get_available_devices( const device_map &device_map ) const;

			void open_streams();
			void close_streams();

			void initialize_stream_parameters( PaStreamParameters &parameters, int device_index, bool is_output );

			int get_default_sample_rate( int device_index ) const;

			void input_handler( const void *input_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags status_flags );
			void output_handler( void *output_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags status_flags );
			void duplex_handler( const void *input_buffer, void *output_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags status_flags );

			PaHostApiTypeId api_none() const;

			PaHostApiIndex get_selected_api_index() const;

			void set_input_device_to_default();
			void set_output_device_to_default();

			bool m_initialized_ok;

			api_map m_available_apis;
			device_map m_available_input_devices;
			device_map m_available_output_devices;
			int_vector m_available_sample_rates;

			PaHostApiTypeId m_selected_api;
			PaDeviceIndex m_selected_input_device;
			PaDeviceIndex m_selected_output_device;
			int m_sample_rate;

			int m_number_of_input_channels;
			int m_number_of_output_channels;

			PaStream *m_input_stream;
			PaStream *m_output_stream;
			PaStream *m_duplex_stream;

			static const string none;
			static const int potential_sample_rates[];

			class CCompareApiNames : public std::binary_function<string, string, bool>
			{
				public:
					CCompareApiNames( const api_map &context );
					bool operator()( const string &api_name_1, const string &api_name_2 ) const;

				private:
					const api_map &m_context;

			};

			class CCompareDeviceNames : public std::binary_function<string, string, bool>
			{
				public:
					CCompareDeviceNames( const device_map &context );
					bool operator()( const string &device_name_1, const string &device_name_2 ) const;

				private:
					const device_map &m_context;

			};
	};
}



#endif /* INTEGRA_PORT_AUDIO_ENGINE_H */