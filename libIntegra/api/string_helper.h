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

#ifndef INTEGRA_STRING_HELPER_H
#define INTEGRA_STRING_HELPER_H


#include <stdio.h>

#include "common_typedefs.h"
#include "error.h"

namespace integra_api
{
	class INTEGRA_API CStringHelper
	{
		public:

			/* converts date/time to ISO 8601 string */
			static string date_to_string( const struct tm &date );

			/* converts string to date/time.  expects string in ISO 8601 form eg 2012-07-20T14:42 */
			static CError string_to_date( const string &string, struct tm &output );

			/* does the node name consist entirely of valid characters? */
			static bool validate_node_name( const string &name );

			static const string node_name_character_set;

			static const int string_buffer_length = 1024;
	};
}





#endif
