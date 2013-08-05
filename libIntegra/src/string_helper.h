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

#include "api/common_typedefs.h"
#include "error.h"


namespace ntg_api
{
	class CStringHelper
	{
		public:

			/* converts guid to string in lowercase hexadecimal form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" */
			static string guid_to_string( const GUID &guid );

			/* converts string to guid.  expects string in hexadecimal form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" */
			static CError string_to_guid( const string &string, GUID &output );

			/* converts date/time to ISO 8601 string */
			static string date_to_string( const struct tm &date );

			/* converts string to date/time.  expects string in ISO 8601 form eg 2012-07-20T14:42 */
			static CError string_to_date( const string &string, struct tm &output );

			/* does the node name consist entirely of valid characters? */
			static bool validate_node_name( const string &name );

		private:

			static unsigned long read_hex_chars( const string &input, unsigned int number_of_bytes, CError &error );
			static CError read_hex_char( char input, unsigned char &output );
	};
}





#endif
