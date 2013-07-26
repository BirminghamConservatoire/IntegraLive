/** libIntegra multimedia module interface
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

#include <stdio.h>
#include <string.h>

#include "globals.h"

#define VALUE_SEPARATOR ": "
#define MAX_NUMBER_LENGTH 32
#define MAX_TIMESTAMP_LENGTH 32


LIBINTEGRA_API void ntg_trace(ntg_trace_category_bits trace_category, const char *location, const char *message)
{
	time_t rawtime;
	char timestamp_string[ MAX_TIMESTAMP_LENGTH ];

	pthread_t thread_id;
	const unsigned char *thread_id_bytes;
	int i;

	if( (trace_category_bits & trace_category) == 0)
	{
		return;
	}

	switch( trace_category )
	{
		case TRACE_ERROR_BITS:
			printf("Error");
			break;

		case TRACE_PROGRESS_BITS:
			printf("Progress");
			break;

		case TRACE_VERBOSE_BITS:
			printf("Verbose");
			break;

		default:
			printf("<unknown trace category>");
			break;
	}

	if(trace_option_bits & TRACE_TIMESTAMP_BITS)
	{
		time(&rawtime);
		strftime(timestamp_string, MAX_TIMESTAMP_LENGTH, "%X %x", localtime(&rawtime));
		printf(" [%s]", timestamp_string);
	}

	if(trace_option_bits & TRACE_LOCATION_BITS)
	{
		printf(" %s", location);
	}

	if(trace_option_bits & TRACE_THREADSTAMP_BITS)
	{
		printf(" threadID: 0x");

		thread_id = pthread_self();
		thread_id_bytes = (const unsigned char *)(&thread_id);

		for(i=0; i<sizeof(thread_id); i++)
		{
			printf("%02x", thread_id_bytes[ i ] );
		}
	}

	printf("     %s\n", message);

	fflush(stdout);
}


LIBINTEGRA_API void ntg_trace_with_int(ntg_trace_category_bits trace_category, const char *location, const char *message, int int_value)
{
	char *trace_string = NULL;
	int max_length = 0;

	if( (trace_category_bits & trace_category) == 0)
	{
		return;
	}

	max_length = strlen( message ) + strlen( VALUE_SEPARATOR ) + MAX_NUMBER_LENGTH;
	trace_string = new char[ max_length ];
	snprintf( trace_string, max_length, "%s%s%i", message, VALUE_SEPARATOR, int_value );

	ntg_trace( trace_category, location, trace_string );

	delete[] trace_string;
}


LIBINTEGRA_API void ntg_trace_with_float(ntg_trace_category_bits trace_category, const char *location, const char *message, float float_value)
{
	char *trace_string = NULL;
	int max_length = 0;

	if( (trace_category_bits & trace_category) == 0)
	{
		return;
	}

	max_length = strlen( message ) + strlen( VALUE_SEPARATOR ) + MAX_NUMBER_LENGTH;
	trace_string = new char[ max_length ];
	snprintf( trace_string, max_length, "%s%s%.3f", message, VALUE_SEPARATOR, float_value );

	ntg_trace( trace_category, location, trace_string );

	delete[] trace_string;
}


LIBINTEGRA_API void ntg_trace_with_string(ntg_trace_category_bits trace_category, const char *location, const char *message, const char *string_value)
{
	char *trace_string = NULL;
	int max_length = 0;

	if( (trace_category_bits & trace_category) == 0)
	{
		return;
	}

	max_length = strlen( message ) + strlen( VALUE_SEPARATOR ) + strlen( string_value ) + 1;
	trace_string = new char[ max_length ];
	snprintf( trace_string, max_length, "%s%s%s", message, VALUE_SEPARATOR, string_value );

	ntg_trace( trace_category, location, trace_string );

	delete [] trace_string;
}


LIBINTEGRA_API void ntg_set_trace_options(ntg_trace_category_bits categories_to_trace, ntg_trace_options_bits trace_options)
{
	trace_category_bits = categories_to_trace;
	trace_option_bits = trace_options;
}



