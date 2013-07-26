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


#ifndef INTEGRA_ERRORS_PRIVATE
#define INTEGRA_ERRORS_PRIVATE

#include "api/common_typedefs.h"


/*
 * Error handling
 */
namespace ntg_api
{
	typedef enum error_code_ {
		NTG_ERROR = -1,
		NTG_NO_ERROR = 0,
		NTG_FAILED = 1,
		NTG_MEMORY_ALLOCATION_ERROR = 2,
		NTG_MEMORY_FREE_ERROR = 3,
		NTG_TYPE_ERROR = 4,
		NTG_PATH_ERROR = 5,
		NTG_CONSTRAINT_ERROR = 6,
		NTG_REENTRANCE_ERROR = 7,
		NTG_FILE_VALIDATION_ERROR = 8,
		NTG_FILE_MORE_RECENT_ERROR = 9,
		NTG_MODULE_ALREADY_INSTALLED = 10
	} error_code;



	/** \brief returns a textual description of a given error code */
	LIBINTEGRA_API const char *ntg_error_text( error_code error_code );


	/** \brief Definition of the type ntg_command_status @see
	 * Integra/integra_Server.h */
	typedef struct command_status_ 
	{
		void *data; /* arbitrary data passed back to the caller */
		error_code error_code;
	} command_status;
}



#endif /*INTEGRA_ERRORS_PRIVATE*/