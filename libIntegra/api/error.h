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

/** \file error.h
 *  \brief Defines class CError
 */


#ifndef INTEGRA_ERROR_DEFINED
#define INTEGRA_ERROR_DEFINED

#include "common_typedefs.h"

namespace integra_api
{
	/** \class CError error.h "api/error.h"
	 *  \brief Represents an enumeration of error codes
	 * 
	 * These error codes are used internally and within libIntegra's api.
	 * The enumeration is implemented as a class to allow inline stringification where needed
	 */

	class INTEGRA_API CError
	{
		public:

			/** Error enumeration values */
			enum code 
			{
				/** Error caused by unexpected or illegal input values */
				INPUT_ERROR = -1,				

				/** No Error */
				SUCCESS = 0,					

				/** Generic function failure - anything not covered by other error codes */
				FAILED = 1,						

				/** Mismatching type, eg trying to set an integer endpoint by passing a CStringValue */
				TYPE_ERROR = 2,					

				/** Failed to lookup a node or node endpoint, for example by passing a path to an object which doesn't exist */
				PATH_ERROR = 3,					

				/** Failed to adhere to a stateful endpoint's constraint (see IConstraint) */
				CONSTRAINT_ERROR = 4,			

				/** Aborting a chain of set commands because reentrance has been detected, for example because of a circular chain of connections, or a circular interaction of connections and scripts */
				REENTRANCE_ERROR = 5,			

				/** Either the .ixd representation of a node tree within a .integra file fails to conform to the schema defined in CollectionSchema.xsd, or its reified transformation fails to conform to the schema defined in ReifiedCollectionSchema.xsd */
				FILE_VALIDATION_ERROR = 6,		

				/** A file can't be loaded because it was saved in a more recent version of libIntegra */
				FILE_MORE_RECENT_ERROR = 7,		

				/** A module can't be installed because it is already installed */
				MODULE_ALREADY_INSTALLED = 8	
			};

			CError();

			/** \brief Create a CError from an enumeration constant
			 */
			CError( code error_code );

			/** \brief Casting operator, allows direct comparison of CError and enumeration constants
			 */
			operator code() const;

			/** \conversion to string
			 * \return a string representation of the error
			 */
			string get_text() const;

		private:

			code m_error_code;
	};
}



#endif /*INTEGRA_ERROR_DEFINED*/