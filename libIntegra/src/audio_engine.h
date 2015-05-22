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


#ifndef INTEGRA_AUDIO_ENGINE_INTERFACE_H
#define INTEGRA_AUDIO_ENGINE_INTERFACE_H

#include "api/common_typedefs.h"
#include "api/error.h"


using namespace integra_api;

namespace integra_internal
{
	class CDspEngine;

	class IAudioEngine
	{
		protected:

			IAudioEngine() {}

		public:

			static IAudioEngine *create_audio_engine( CDspEngine &dsp_engine );
			virtual ~IAudioEngine() {}

			virtual CError set_driver( const string &driver ) = 0;
			virtual CError set_input_device( const string &input_device ) = 0;
			virtual CError set_output_device( const string &output_device ) = 0;

			virtual CError set_sample_rate( int sample_rate ) = 0;
			virtual CError set_number_of_input_channels( int input_channels ) = 0;
			virtual CError set_number_of_output_channels( int output_channels ) = 0;

			virtual CError restore_defaults() = 0;

			virtual string_vector get_available_drivers() const = 0;
			virtual string_vector get_available_input_devices() const = 0;
			virtual string_vector get_available_output_devices() const = 0;
			virtual int_vector get_available_sample_rates() const = 0;

			virtual string get_selected_driver() const = 0;
			virtual string get_selected_input_device() const = 0;
			virtual string get_selected_output_device() const = 0;

			virtual int get_sample_rate() const = 0;
			virtual int get_number_of_input_channels() const = 0;
			virtual int get_number_of_output_channels() const = 0;

		protected:

			CDspEngine &get_dsp_engine() { return *m_dsp_engine; }

		private:

			CDspEngine *m_dsp_engine;
	};
}



#endif /* INTEGRA_AUDIO_ENGINE_INTERFACE_H */
