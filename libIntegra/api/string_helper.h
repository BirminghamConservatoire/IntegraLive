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

/** \file string_helper.h
 *  \brief Defines class CStringHelper
 */


#ifndef INTEGRA_STRING_HELPER_H
#define INTEGRA_STRING_HELPER_H


#include <stdio.h>

#include "common_typedefs.h"
#include "error.h"

namespace integra_api
{
	/** \class CStringHelper string_helper.h "api/string_helper.h"
	 *  \brief Common string routines
	 *
	 * \note CStringHelper need never be instantiated - all its methods are static and stateless.
	 */	
	class INTEGRA_API CStringHelper
	{
		public:

			/** \brief Convert date/time to string 
			 * \param date the date to convert
			 * \return ISO 8601 formatted string representation of the date/time
			 */
			static string date_to_string( const struct tm &date );

			/** \brief Convert string to date/time.  
			 * \param string the string to convert.  Expects string in ISO 8601 form eg 2012-07-20T14:42 
			 * \param[out] the converted date/time
			 * \return CError::SUCCESS or CError::INPUT_ERROR
			 */
			static CError string_to_date( const string &string, struct tm &output );

			/** \brief Test whether the node name is valid
			 * \param name the node name to test
			 * \return true if name contains no invalid characters, otherwise false
			 */
			static bool validate_node_name( const string &name );

			/** \brief Create string-representation of an array of strings
			 *
			 * These packed strings are used by the AudioSettings and MidiSettings interfaces, to encode lists of available drivers/devices.
			 * Each string in the array is prepended by its length and a colon, allowing unambiguous unpacking.
			 * Example: { "First Item", "Second Item" } becomes "10:First Item11:Second Item"
			 *
			 * \param strings array of strings to pack
			 * \return the single packed string
			*/
			static string string_vector_to_string( const string_vector &strings );

			/** \brief Trim whitespace from start and end of a string 
			 * \param input the string to trim
			 * \return trimmed version of the string
			 */
			static string trim( const string &input );

			/** \brief The set of characters which may be used in node names */
			static const string node_name_character_set;

			/** \brief A standard length for string buffers.  
			 * \note wherever possible libIntegra uses resizable std::string.  Fixed length string buffers are 
			 * when required by external libraries such as minizip
			 */
			static const int string_buffer_length = 1024;
	};
}





#endif
