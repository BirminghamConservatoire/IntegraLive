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

/** \file trace.h
 *  \brief Defines tracing macros and class CTrace for configuration of tracing
 *
 * libIntegra tracing writes to stdout.
 *
 * The main entrypoint for libIntegra tracing functionality are the macros
 * INTEGRA_TRACE_ERROR, INTEGRA_TRACE_PROGRESS and INTEGRA_TRACE_VERBOSE.
 * 
 * These macros are exposed in libIntegra's api in order to allow users of the api 
 * to utilize the tracing system themselves, if they wish to.
 */


#ifndef INTEGRA_TRACING_PRIVATE
#define INTEGRA_TRACING_PRIVATE

#include "common_typedefs.h"
#include <ostream>
#include <fstream>


/** Used internally by subsequent macros */
#define STRINGIFY(x) #x
/** Used internally by subsequent macros */
#define TOSTRING(x) STRINGIFY(x)
#ifdef _WINDOWS
/** Used internally by subsequent macros */
#define INTEGRA_FUNCTION __FUNCTION__
#else 
/** Used internally by subsequent macros */
#define INTEGRA_FUNCTION __PRETTY_FUNCTION__
#endif /*_WINDOWS*/

/** Used internally by subsequent macros */
#define INTEGRA_LOCATION __FILE__ ": " TOSTRING(__LINE__)


/** \brief Main error tracing macro.  
 * Usage example: INTEGRA_TRACE_ERROR << "Something unexpected happened!  Details: " << some_details << of_mixed_type;
 *
 * Only traces anything when tracing of errors is enabled
 * Automatically traces time, location and thread ID (subject to configuration). 
 */
#define INTEGRA_TRACE_ERROR			integra_api::CTrace::error( INTEGRA_LOCATION, INTEGRA_FUNCTION )

/** \brief Main progress tracing macro.  
 * Usage example: INTEGRA_TRACE_PROGRESS << "A normal (not unexpected) thing happened.  Details: " << some_details << of_mixed_type;
 *
 * Only traces anything when tracing of progress is enabled
 * Automatically traces time, location and thread ID (subject to configuration). 
 */
#define INTEGRA_TRACE_PROGRESS		integra_api::CTrace::progress( INTEGRA_LOCATION, INTEGRA_FUNCTION )

/** \brief Main verbose progress tracing macro.  
 *
 * The distinction between progress and verbose tracing allows very commonly-occuring actions to be only included
 * when verbose tracing is enabled, preventing excessive tracing during normal operation.
 *
 * Usage example: INTEGRA_TRACE_VERBOSE << "A normal (not unexpected) and frequently occurring thing happened.  Details: " << some_details << of_mixed_type;
 *
 * Only traces anything when verbose tracing is enabled
 * Automatically traces time, location and thread ID (subject to configuration). 
 */
#define INTEGRA_TRACE_VERBOSE		integra_api::CTrace::verbose( INTEGRA_LOCATION, INTEGRA_FUNCTION )



namespace integra_api
{
	/** \class CTrace trace.h "api/trace.h"
	 *  \brief Handles console output
	 *
	 * libIntegra handles errors and reports progress by writing to the console.  This is done
	 * by the macros INTEGRA_TRACE_ERROR, INTEGRA_TRACE_PROGRESS and INTEGRA_TRACE_VERBOSE,
	 * which in turn call methods in CTrace
	 * 
	 * CTrace is exposed in libIntegra's api in order to allow users of the api to customise 
	 * what is traced.
	 *
	 * \note CTrace need never be instantiated - all its methods are static and stateless.
	 */	

	class INTEGRA_API CTrace
	{
		public:

			/** \brief Customise the types of message which should be traced 
			 *
			 * By default, errors and progress are traced, verbose messages are not
			 */
			static void set_categories_to_trace( bool errors, bool progress, bool verbose );

			/** \brief Customise the additional information which should be written with each message
			 *
			 * By default, messages are stamped with time and location, but not thread ID.
			 *
			 * \param timestamp Write the date/time into each message
			 * \param location Write the source file, line number and function name into each message
			 * \param thread Write id of the currently executing thread into each message
			 */
			static void set_details_to_trace( bool timestamp, bool location, bool thread );

			/** Internal use only */
			static std::ostream &error( const char *location, const char *function );

			/** Internal use only */
			static std::ostream &progress( const char *location, const char *function );

			/** Internal use only */
			static std::ostream &verbose( const char *location, const char *function );

		private:

			static void do_trace( const char *category, const char *location, const char *function ); 

			static bool s_trace_errors;
			static bool s_trace_progress;
			static bool s_trace_verbose;

			static bool s_trace_timestamp;
			static bool s_trace_location;
			static bool s_trace_thread;

			static std::ostream &s_trace_stream;
			static std::ofstream s_null_stream;

			static const int max_timestamp_length;
	};
}


#endif /*INTEGRA_TRACING_PRIVATE*/
