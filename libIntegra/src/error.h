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


#ifndef INTEGRA_ERROR
#define INTEGRA_ERROR

#include "api/common_typedefs.h"

namespace integra_api
{
	class INTEGRA_API CError
	{
		public:

			enum code 
			{
				INPUT_ERROR = -1,
				SUCCESS = 0,
				FAILED = 1,
				TYPE_ERROR = 2,
				PATH_ERROR = 3,
				CONSTRAINT_ERROR = 4,
				REENTRANCE_ERROR = 5,
				FILE_VALIDATION_ERROR = 6,
				FILE_MORE_RECENT_ERROR = 7,
				MODULE_ALREADY_INSTALLED = 8
			};

			CError();
			CError( code error_code );

			operator code() const;
			string get_text() const;

		private:

			code m_error_code;
	};
}



#endif /*INTEGRA_ERROR*/