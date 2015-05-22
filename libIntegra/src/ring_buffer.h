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


#ifndef INTEGRA_RING_BUFFER_H
#define INTEGRA_RING_BUFFER_H

#include <pthread.h>


namespace integra_internal
{
	class CRingBuffer
	{
		public:

			CRingBuffer();
			~CRingBuffer();

			void set_number_of_channels( unsigned int number_of_channels );
			void set_buffer_length( unsigned int buffer_frames );

			void clear();

			void write( const float *buffer, unsigned int sample_frames );
			void read( float *buffer, unsigned int sample_frames );

		private:

			void recreate_buffer();

			float *m_buffer;
			unsigned int m_buffer_frames;
			unsigned int m_number_of_channels;

			unsigned int m_read_pos;
			unsigned int m_frames_used;

			pthread_mutex_t m_mutex;
	};
}



#endif /* INTEGRA_PORT_AUDIO_ENGINE_H */