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
 *  \brief Defines class CGuidHelper, and guid containers
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

			/** \brief Guid hash function 
			 * \param guid a guid to hash
			 * \return a 32-bit hash of the guid
			 */
			static size_t guid_to_hash( const GUID &guid );

			/** \brief Convert guid to string
			 * \param guid guid to convert
			 * \return lowercase hexadecimal string representation of the guid, in the form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
			 */
			static string guid_to_string( const GUID &guid );

			/** \brief Convert string to guid
			 * \param string.  Must be hexadecimal in form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
			 * \param[out] output.  On success, converted guid is stored here.
			 * \return CError::INPUT_ERROR if input was incorrectly formatted.  Otherwise CError::SUCCESS
			 */
			static CError string_to_guid( const string &string, GUID &output );

			/** \brief Compare guids
			 * \param guid1 first guid to compare
			 * \param guid2 second guid to compare
			 * \return true if guids are equal, false if they are not equal
			 */
            static bool guids_are_equal( const GUID &guid1, const GUID &guid2 );
        
			/** \brief Test guid for nullness
			 * \param guid guid to test for nullness
			 * \return true if guids is null, false if it is not null
			 */
            static bool guid_is_null( const GUID &guid );
        
			/** \brief Null guid.  
			 * Assign guids to this value to mark them as null.
			 */
			static const GUID null_guid;

		private:

			static unsigned long read_hex_chars( const string &input, unsigned int number_of_bytes, CError &error );
			static CError read_hex_char( char input, unsigned char &output );
	};


	/** \brief Defines a hash operator so that guids can be keys of standard library maps and sets.  Internal use only */
	struct GuidHash 
	{
		size_t operator()( const GUID &guid ) const { return CGuidHelper::guid_to_hash( guid ); }
	};

	/** \brief Defines a comparison operator so that guids can be keys of standard library maps and sets.  Internal use only */
    struct GuidCompare
    {
        bool operator()( const GUID &guid1, const GUID &guid2 ) const { return CGuidHelper::guids_are_equal( guid1, guid2 ); }
    };

	/** Unordered set of guids */
	typedef std::unordered_set<GUID, GuidHash, GuidCompare> guid_set;

	/** Variable-length array guids */
	typedef std::vector<GUID> guid_array;
}





#endif
