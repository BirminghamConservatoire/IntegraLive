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


/*
 * Tracing System
 */

typedef enum ntg_trace_category_bits_ {
	/* no trace category bits */
	NO_TRACE_CATEGORY_BITS = 0,

	/* Something unexpected happened, indicating a likely bug */
	TRACE_ERROR_BITS = 1,
	/* nothing unexpected happened, just useful information */
	TRACE_PROGRESS_BITS = 2,
	/* nothing unexpected happened, useful information which is expected to occur in large quantities*/
	TRACE_VERBOSE_BITS = 4,

	/*all trace category bits */
	ALL_TRACE_CATEGORY_BITS = TRACE_ERROR_BITS | TRACE_PROGRESS_BITS | TRACE_VERBOSE_BITS
} ntg_trace_category_bits;


typedef enum ntg_trace_options_bits_ {
	/* no trace options bits */
	NO_TRACE_OPTIONS_BITS = 0,

	/* trace the system time at which the trace occurred*/
	TRACE_TIMESTAMP_BITS = 1,
	/* trace the filename, line number, and function in which the trace occurred*/
	TRACE_LOCATION_BITS = 2,
	/* trace the id of the thread in which the trace occurred*/
	TRACE_THREADSTAMP_BITS = 4,

	/*all trace option bits */
	ALL_TRACE_OPTION_BITS = TRACE_TIMESTAMP_BITS | TRACE_LOCATION_BITS | TRACE_THREADSTAMP_BITS
} ntg_trace_options_bits;





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

/*these tracing functions should not be called directly - use the tracing macros below*/

LIBINTEGRA_API void ntg_trace(ntg_trace_category_bits trace_category, const char *location, const char *message);
LIBINTEGRA_API void ntg_trace_with_int(ntg_trace_category_bits trace_category, const char *location, const char *message, int int_value);
LIBINTEGRA_API void ntg_trace_with_float(ntg_trace_category_bits trace_category, const char *location, const char *message, float float_value);
LIBINTEGRA_API void ntg_trace_with_string(ntg_trace_category_bits trace_category, const char *location, const char *message, const char *string_value);

/*
 * use ntg_set_trace_options at during startup to specify what should be traced, and how it should be traced.  
 * NOTE! ntg_set_trace_options is not thread-safe!  It should only be called before ntg_server_run is called, and the trace macros should 
 * not be used until after ntg_set_trace_options has been called.
 */

LIBINTEGRA_API void ntg_set_trace_options(ntg_trace_category_bits categories_to_trace, ntg_trace_options_bits trace_options);

/*these are the set of tracing macros used to report erros or progress*/
#define NTG_TRACE_ERROR(message) ntg_trace(TRACE_ERROR_BITS, NTG_LOCATION, message);
#define NTG_TRACE_ERROR_WITH_INT(message, int_value) ntg_trace_with_int(TRACE_ERROR_BITS, NTG_LOCATION, message, int_value);
#define NTG_TRACE_ERROR_WITH_FLOAT(message, float_value) ntg_trace_with_string(TRACE_ERROR_BITS, NTG_LOCATION, message, float_value);
#define NTG_TRACE_ERROR_WITH_STRING(message, string_value) ntg_trace_with_string(TRACE_ERROR_BITS, NTG_LOCATION, message, string_value);
#define NTG_TRACE_ERROR_WITH_ERRNO(message) ntg_trace_with_string(TRACE_ERROR_BITS, NTG_LOCATION, message, strerror(errno) );

#define NTG_TRACE_PROGRESS(message) ntg_trace(TRACE_PROGRESS_BITS, NTG_LOCATION, message);
#define NTG_TRACE_PROGRESS_WITH_INT(message, int_value) ntg_trace_with_int(TRACE_PROGRESS_BITS, NTG_LOCATION, message, int_value);
#define NTG_TRACE_PROGRESS_WITH_FLOAT(message, float_value) ntg_trace_with_float(TRACE_PROGRESS_BITS, NTG_LOCATION, message, float_value);
#define NTG_TRACE_PROGRESS_WITH_STRING(message, string_value) ntg_trace_with_string(TRACE_PROGRESS_BITS, NTG_LOCATION, message, string_value);

#define NTG_TRACE_VERBOSE(message) ntg_trace(TRACE_VERBOSE_BITS, NTG_LOCATION, message);
#define NTG_TRACE_VERBOSE_WITH_INT(message, int_value) ntg_trace_with_int(TRACE_VERBOSE_BITS, NTG_LOCATION, message, int_value);
#define NTG_TRACE_VERBOSE_WITH_FLOAT(message, float_value) ntg_trace_with_float(TRACE_VERBOSE_BITS, NTG_LOCATION, message, float_value);
#define NTG_TRACE_VERBOSE_WITH_STRING(message, string_value) ntg_trace_with_string(TRACE_VERBOSE_BITS, NTG_LOCATION, message, string_value);



#endif /*INTEGRA_TRACING_PRIVATE*/