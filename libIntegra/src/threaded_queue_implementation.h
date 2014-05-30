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



#ifndef INTEGRA_THREADED_QUEUE_IMPLEMENTATION_PRIVATE
#define INTEGRA_THREADED_QUEUE_IMPLEMENTATION_PRIVATE


#include "assert.h"
#include "api/trace.h"
#include "api/error.h"

using namespace integra_api;

namespace integra_internal
{
	template<class T> CThreadedQueue<T>::CThreadedQueue( IThreadedQueueOutputSink<T> &output_sink )
		:	m_output_sink( output_sink )
	{
		m_content = new std::list<T>;

		m_finished = false;

		pthread_mutex_init( &m_queue_mutex, NULL );

        CError error = CError::SUCCESS;
#ifdef __APPLE__
        m_semaphore = sem_open("/semaphore", O_CREAT, 0777, 0);

        if (m_semaphore == SEM_FAILED )
        {
            error = CError::FAILED;
        }
#else
        m_semaphore = new sem_t;

        if (sem_init( m_semaphore, 0, 0 )==-1)
        {
            error = CError::FAILED;
        }
#endif
        if( error != CError::SUCCESS )
        {
            INTEGRA_TRACE_ERROR << "Semaphore open error: " << strerror(errno);
            return;
        }

		pthread_create( &m_output_thread, NULL, threaded_queue_thread_function<T>, this );
	}


	template<class T> CThreadedQueue<T>::~CThreadedQueue()
	{
		m_finished = true;

		send_signal_to_output_thread();

		pthread_join( m_output_thread, NULL);

		pthread_mutex_destroy( &m_queue_mutex );

        int sem_rv = 0;
        
#ifdef __APPLE__
        sem_rv = sem_close( m_semaphore );
#else
        sem_rv = sem_destroy( m_semaphore );
        delete m_semaphore;
#endif
        
        if (sem_rv == -1)
        {
            INTEGRA_TRACE_ERROR << "Semaphore close error: " << strerror(errno);
        }

		assert( m_content );
		assert( m_content->empty() );

		delete m_content;
	}


	template<class T> void CThreadedQueue<T>::push( const T &item )
	{
		pthread_mutex_lock( &m_queue_mutex );

		assert( m_content );
		m_content->push_back( item );

		pthread_mutex_unlock( &m_queue_mutex );

		send_signal_to_output_thread();
	}


	template<class T> void CThreadedQueue<T>::push( const std::list<T> &items )
	{
		pthread_mutex_lock( &m_queue_mutex );

		assert( m_content );
		m_content->insert( m_content->end(), items.begin(), items.end() );

		pthread_mutex_unlock( &m_queue_mutex );

		send_signal_to_output_thread();
	}


	template<class T> void CThreadedQueue<T>::send_signal_to_output_thread()
	{
		sem_post( m_semaphore );
	}


	template<class T> void CThreadedQueue<T>::output_thread()
	{
		bool finished( false );

		while( !finished )
		{
			sem_wait( m_semaphore );

			pthread_mutex_lock( &m_queue_mutex );

			std::list<T> *content_to_deliver = NULL;

			assert( m_content );
			if( !m_content->empty() )
			{
				content_to_deliver = m_content;
				m_content = new std::list<T>;
			}

			if( m_finished ) 
			{
				finished = true;
			}

			pthread_mutex_unlock( &m_queue_mutex );

			if( content_to_deliver )
			{
				m_output_sink.handle_queue_items( *content_to_deliver );
				delete content_to_deliver;
			}
		}
	}


	template <class T> void *threaded_queue_thread_function( void *context )
	{
		CThreadedQueue<T> *threaded_queue = static_cast< CThreadedQueue<T> * > ( context );
		threaded_queue->output_thread();

		return NULL;
	}


}



#endif /* INTEGRA_THREADED_QUEUE_IMPLEMENTATION_PRIVATE */