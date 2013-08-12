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


#ifndef INTEGRA_TRACING_PRIVATE
#define INTEGRA_TRACING_PRIVATE

#include "api/common_typedefs.h"
#include <ostream>
#include <fstream>


/*! \def TOSTRING(x)
 * Macro to convert an integer to a string at compile time
 */
#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)
#ifdef _WINDOWS
#define NTG_FUNCTION __FUNCTION__
#else 
#define NTG_FUNCTION TOSTRING(__FUNCTION__)
#endif /*_WINDOWS*/

#define NTG_LOCATION __FILE__ ": " TOSTRING(__LINE__) "(" NTG_FUNCTION ")"


#define NTG_TRACE_ERROR				ntg_api::CTrace::error( NTG_LOCATION )
#define NTG_TRACE_PROGRESS			ntg_api::CTrace::progress( NTG_LOCATION )
#define NTG_TRACE_VERBOSE			ntg_api::CTrace::verbose( NTG_LOCATION )



namespace ntg_api
{
	class LIBINTEGRA_API CTrace
	{
		public:

			static std::ostream &error( const char *location );
			static std::ostream &progress( const char *location );
			static std::ostream &verbose( const char *location );

			static void set_categories_to_trace( bool errors, bool progress, bool verbose );
			static void set_details_to_trace( bool timestamp, bool location, bool thread );

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
