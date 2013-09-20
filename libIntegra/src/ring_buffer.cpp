/** libIntegra multimedia module interface
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


#include "platform_specifics.h"

#include "ring_buffer.h"
#include "api/trace.h"

#include <string.h>
#include <assert.h>


namespace integra_internal
{
	CRingBuffer::CRingBuffer()
	{
		m_buffer = NULL;
		m_buffer_frames = 0;
		m_number_of_channels = 0;

		m_read_pos = 0;
		m_frames_used = 0;

		pthread_mutex_init( &m_mutex, NULL );
	}


	CRingBuffer::~CRingBuffer()
	{
		pthread_mutex_lock( &m_mutex );

		if( m_buffer )
		{
			delete [] m_buffer;
		}

		pthread_mutex_unlock( &m_mutex );

		pthread_mutex_destroy( &m_mutex );
	}


	void CRingBuffer::recreate_buffer()
	{
		if( m_buffer )
		{
			delete [] m_buffer;
		}

		if( m_buffer_frames > 0 && m_number_of_channels > 0 )
		{
			m_buffer = new float[ m_buffer_frames * m_number_of_channels ];
			memset( m_buffer, 0, m_buffer_frames * m_number_of_channels * sizeof( float ) );
		}
		else
		{
			m_buffer = NULL;
		}

		m_read_pos = 0;
		m_frames_used = 0;
	}


	void CRingBuffer::set_number_of_channels( unsigned int number_of_channels )
	{
		pthread_mutex_lock( &m_mutex );

		if( number_of_channels != m_number_of_channels )
		{
			m_number_of_channels = number_of_channels;

			recreate_buffer();
		}

		pthread_mutex_unlock( &m_mutex );
	}


	void CRingBuffer::set_buffer_length( unsigned int buffer_frames )
	{
		pthread_mutex_lock( &m_mutex );

		if( buffer_frames != m_buffer_frames )
		{
			m_buffer_frames = buffer_frames;

			recreate_buffer();
		}

		pthread_mutex_unlock( &m_mutex );
	}


	void CRingBuffer::clear()
	{
		pthread_mutex_lock( &m_mutex );

		if( m_buffer )
		{
			memset( m_buffer, 0, m_buffer_frames * m_number_of_channels * sizeof( float ) );
			m_read_pos = 0;
			m_frames_used = 0;
		}

		pthread_mutex_unlock( &m_mutex );
	}


	void CRingBuffer::write( const float *buffer, unsigned int sample_frames )
	{
		pthread_mutex_lock( &m_mutex );

		if( m_buffer )
		{
			if( m_frames_used + sample_frames > m_buffer_frames )
			{
				int overrun = m_frames_used + sample_frames - m_buffer_frames;
				assert( overrun > 0 );

				INTEGRA_TRACE_ERROR << "Ringbuffer overrun - skipping " << overrun << " frames";
				sample_frames -= overrun;
			}

			int write_pos = m_read_pos + m_frames_used;
			if( write_pos >= m_buffer_frames )
			{
				write_pos -= m_buffer_frames;
			}

			assert( write_pos >= 0 && write_pos < m_buffer_frames );

			int unwrapped_frames = MIN( sample_frames, m_buffer_frames - write_pos );
			memcpy( m_buffer + write_pos * m_number_of_channels, buffer, unwrapped_frames * m_number_of_channels * sizeof( float ) );

			if( unwrapped_frames < sample_frames )
			{
				int wrapped_frames = sample_frames - unwrapped_frames;
				memcpy( m_buffer, buffer + unwrapped_frames * m_number_of_channels, wrapped_frames * m_number_of_channels * sizeof( float ) );
			}

			m_frames_used += sample_frames;
		}
		else
		{
			INTEGRA_TRACE_ERROR << "Can't write to buffer - not initialised";
		}

		pthread_mutex_unlock( &m_mutex );
	}


	void CRingBuffer::read( float *buffer, unsigned int sample_frames )
	{
		pthread_mutex_lock( &m_mutex );

		if( buffer )
		{
			if( sample_frames > m_frames_used )
			{
				int underrun_frames = sample_frames - m_frames_used;

				INTEGRA_TRACE_ERROR << "Ringbuffer underrun - skipping " << underrun_frames << " frames";

				memset( buffer + m_frames_used * m_number_of_channels, 0, underrun_frames * m_number_of_channels * sizeof( float ) );

				sample_frames = m_frames_used;
			}

			int unwrapped_frames = MIN( sample_frames, m_buffer_frames - m_read_pos );
			memcpy( buffer, m_buffer + m_read_pos * m_number_of_channels, unwrapped_frames * m_number_of_channels * sizeof( float ) );

			if( unwrapped_frames < sample_frames )
			{
				int wrapped_frames = sample_frames - unwrapped_frames;
				memcpy( buffer + unwrapped_frames * m_number_of_channels, m_buffer, wrapped_frames * m_number_of_channels * sizeof( float ) );
			}

			m_frames_used -= sample_frames;
			m_read_pos += sample_frames;

			if( m_read_pos >= m_buffer_frames )
			{
				m_read_pos -= m_buffer_frames;
			}

			assert( m_read_pos >= 0 && m_read_pos < m_buffer_frames );
		}
		else
		{
			INTEGRA_TRACE_ERROR << "Can't read from buffer - not initialised";
		}

		pthread_mutex_unlock( &m_mutex );
	}
}

 