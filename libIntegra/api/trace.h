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
 *  \brief defines tracing macros and class CTrace for configuration of tracing
 */


#ifndef INTEGRA_TRACING_PRIVATE
#define INTEGRA_TRACING_PRIVATE

#include "common_typedefs.h"
#include <ostream>
#include <fstream>


/*! \def TOSTRING(x)
 * Macro to convert an integer to a string at compile time
 */
#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)
#ifdef _WINDOWS
#define INTEGRA_FUNCTION __FUNCTION__
#else 
#define INTEGRA_FUNCTION TOSTRING(__FUNCTION__)
#endif /*_WINDOWS*/

#define INTEGRA_LOCATION __FILE__ ": " TOSTRING(__LINE__) "(" INTEGRA_FUNCTION ")"


#define INTEGRA_TRACE_ERROR			integra_api::CTrace::error( INTEGRA_LOCATION )
#define INTEGRA_TRACE_PROGRESS		integra_api::CTrace::progress( INTEGRA_LOCATION )
#define INTEGRA_TRACE_VERBOSE		integra_api::CTrace::verbose( INTEGRA_LOCATION )



namespace integra_api
{
	/** \class CTrace trace.h "api/trace.h"
	 *  \brief handles console output
	 *
	 * libIntegra handles errors and reports progress by writing to the console.  This is done
	 * by the macros INTEGRA_TRACE_ERROR, INTEGRA_TRACE_PROGRESS and INTEGRA_TRACE_VERBOSE,
	 * which in turn call methods in CTrace
	 * 
	 * CTrace is exposed in libIntegra's api in order to allow users of the api to customise 
	 * what is traced, and to allow users of the api to utilize the tracing system themselves,
	 * if they wish to.
	 *
	 * \note CTrace need never be instantiated - all its methods are static and stateless.
	 */	

	class INTEGRA_API CTrace
	{
		public:

			static void set_categories_to_trace( bool errors, bool progress, bool verbose );
			static void set_details_to_trace( bool timestamp, bool location, bool thread );

			static std::ostream &error( const char *location );
			static std::ostream &progress( const char *location );
			static std::ostream &verbose( const char *location );

		private:

			static void do_trace( const char *category, const char *location ); 

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
