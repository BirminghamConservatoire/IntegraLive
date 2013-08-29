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
		public:

			CPortAudioEngine();
			~CPortAudioEngine();

			CError set_driver( const string &driver );
			CError set_output_device( const string &output_device );
			CError set_input_device( const string &input_device );

			CError set_sample_rate( int sample_rate );
			CError set_number_of_input_channels( int input_channels );
			CError set_number_of_output_channels( int output_channels );

			CError restore_defaults();

			string_vector get_available_drivers() const;
			string_vector get_available_input_devices() const;
			string_vector get_available_output_devices() const;

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

			string_vector get_available_devices( const device_map &device_map ) const;

			void close_all_streams();

			PaHostApiTypeId api_none() const;

			PaHostApiIndex get_selected_api_index() const;

			bool m_initialized_ok;

			api_map m_available_apis;
			device_map m_available_input_devices;
			device_map m_available_output_devices;

			PaHostApiTypeId m_selected_api;
			PaDeviceIndex m_selected_input_device;
			PaDeviceIndex m_selected_output_device;

			static const string none;

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