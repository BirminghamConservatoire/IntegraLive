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

/** \file guid_helper.h
 *  \brief defines class CGuidHelper, and guid containers
 */

#ifndef INTEGRA_GUID_HELPER_H
#define INTEGRA_GUID_HELPER_H


#include <stdio.h>

#include "../externals/guiddef.h"
#include "common_typedefs.h"
#include "error.h"


namespace integra_api
{
	/** \class CGuidHelper guid_helper.h "api/guid_helper.h"
	 *  \brief Common guid routines
	 * 
	 * libIntegra uses guids to identify modules, so that modules and module revisions can be uniquely 
	 * identified even though they may be developed offline, asynchromously by 3rd party developers.
	 *
	 * \note CGuidHelper need never be instantiated - all its methods are static and stateless.
	 */
	class INTEGRA_API CGuidHelper
	{
		public:

			/* guid hash function */
			static size_t guid_to_hash( const GUID &guid );

			/* converts guid to string in lowercase hexadecimal form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" */
			static string guid_to_string( const GUID &guid );

			/* converts string to guid.  expects string in hexadecimal form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" */
			static CError string_to_guid( const string &string, GUID &output );

            /* compares two guids. return true if they are equal, false if they are not equal */
            static bool guids_are_equal( const GUID &guid1, const GUID &guid2 );
        
            /* compares a guid to CGuidHelper::null_guid. return true if the guid is "null" */
            static bool guid_is_null( const GUID &guid );
        
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

    struct GuidCompare
    {
        bool operator()( const GUID &guid1, const GUID &guid2 ) const { return CGuidHelper::guids_are_equal( guid1, guid2 ); }
    };

	typedef std::unordered_set<GUID, GuidHash, GuidCompare> guid_set;
	typedef std::vector<GUID> guid_array;
}





#endif
