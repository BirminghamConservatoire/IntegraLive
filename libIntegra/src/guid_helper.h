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

#ifndef INTEGRA_GUID_HELPER_H
#define INTEGRA_GUID_HELPER_H


#include <stdio.h>

#include "../externals/guiddef.h"
#include "api/common_typedefs.h"
#include "error.h"


namespace integra_api
{
	class CGuidHelper
	{
		public:

			/* guid hash function */
			static size_t guid_to_hash( const GUID &guid );

			/* converts guid to string in lowercase hexadecimal form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" */
			static string guid_to_string( const GUID &guid );

			/* converts string to guid.  expects string in hexadecimal form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" */
			static CError string_to_guid( const string &string, GUID &output );

			static const GUID null_guid;

		private:

			static unsigned long read_hex_chars( const string &input, unsigned int number_of_bytes, CError &error );
			static CError read_hex_char( char input, unsigned char &output );
	};


	/* Guids */ 
	struct GuidHash 
	{
		size_t operator()( const GUID &guid ) const { return CGuidHelper::guid_to_hash( guid ); }
	};


	typedef std::unordered_set<GUID, GuidHash> guid_set;
	typedef std::vector<GUID> guid_array;
}





#endif
