 /* libIntegra multimedia module interface
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


#ifndef INTEGRA_THREADED_QUEUE_PRIVATE
#define INTEGRA_THREADED_QUEUE_PRIVATE


#include <pthread.h>
#include <semaphore.h>

#include <list>

namespace integra_internal
{
	template<class T> class IThreadedQueueOutputSink
	{
		public:

			virtual void handle_queue_items( const std::list<T> &items ) = 0;
	};


	template <class T> void *threaded_queue_thread_function( void *context );


	template<class T> class CThreadedQueue
	{
		public:

			CThreadedQueue( IThreadedQueueOutputSink<T> &output_sink );
			~CThreadedQueue();

			void push( const T&item );
			void push( const std::list<T> &items );

			friend void *threaded_queue_thread_function<T>( void *context );

		private:

			void send_signal_to_output_thread();

			void output_thread();

			IThreadedQueueOutputSink<T> &m_output_sink;

			std::list<T> *m_content;

			pthread_mutex_t m_queue_mutex;
			sem_t m_semaphore;

			pthread_t m_output_thread;

			bool m_finished;
	};

}


#include "threaded_queue_implementation.h"


#endif /*INTEGRA_THREADED_QUEUE_PRIVATE*/