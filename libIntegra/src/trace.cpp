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


#include "platform_specifics.h"

#include "api/trace.h"

#include <pthread.h>
#include <iostream>



namespace integra_api
{
	bool CTrace::s_trace_errors = true;
	bool CTrace::s_trace_progress = true;
	bool CTrace::s_trace_verbose = false;

	bool CTrace::s_trace_timestamp = true;
	bool CTrace::s_trace_location = true;
	bool CTrace::s_trace_thread = false;

	std::ofstream CTrace::s_null_stream;
	std::ostream &CTrace::s_trace_stream = std::cout;

	const int CTrace::max_timestamp_length = 32;


	std::ostream &CTrace::error( const char *location, const char *function )
	{
		if( !s_trace_errors ) 
		{
			return s_null_stream;
		}

		do_trace( "Error", location, function );
		return s_trace_stream;
	}


	std::ostream &CTrace::progress( const char *location, const char *function )
	{
		if( !s_trace_progress )
		{
			return s_null_stream;
		}

		do_trace( "Progress", location, function );
		return s_trace_stream;
	}


	std::ostream &CTrace::verbose( const char *location, const char *function )
	{
		if( !s_trace_verbose )
		{
			return s_null_stream;
		}

		do_trace( "Verbose", location, function );
		return s_trace_stream;
	}


	void CTrace::set_categories_to_trace( bool errors, bool progress, bool verbose )
	{
		s_trace_errors = errors;
		s_trace_progress = progress;
		s_trace_verbose = verbose;
	}


	void CTrace::set_details_to_trace( bool timestamp, bool location, bool thread )
	{
		s_trace_timestamp = timestamp;
		s_trace_location = location;
		s_trace_thread = thread;
	}


	void CTrace::do_trace( const char *category, const char *location, const char *function )
	{
		s_trace_stream << std::unitbuf << std::endl;
		s_trace_stream << category;

		if( s_trace_timestamp )
		{
			time_t rawtime;
			char timestamp_string[ max_timestamp_length ];
			time( &rawtime );
			strftime( timestamp_string, max_timestamp_length, "%X %x", localtime( &rawtime ) );
			s_trace_stream << " [" << timestamp_string << "]";
		}

		if( s_trace_thread )
		{
			pthread_t thread_id = pthread_self();
			const unsigned char *thread_id_bytes = (const unsigned char *) ( &thread_id );

			s_trace_stream << " threadID: 0x" << std::hex;

			for( int i = 0; i < sizeof( thread_id ); i++ )
			{
				s_trace_stream << ( int ) ( thread_id_bytes[ i ] );
			}

			s_trace_stream << std::dec;
		}

		if( s_trace_location )
		{
			s_trace_stream << " " << location << "(" << function << ")";
		}

		s_trace_stream << "     ";
	}
}


