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

#include "api/error.h"
#include "api/trace.h"

namespace integra_api
{
	CError::CError()
	{
		m_error_code = SUCCESS;
	}


	CError::CError( code error_code )
	{
		m_error_code = error_code;
	}


	CError::operator code() const
	{
		return m_error_code;
	}


	string CError::get_text() const
	{
		switch( m_error_code ) 
		{
			case SUCCESS:					return "Success";
			case INPUT_ERROR:				return "Input error";
			case FAILED:					return "Function failure";
			case TYPE_ERROR:				return "Incorrect data type";
			case PATH_ERROR:				return "Erroneous or incorrect path";
			case CONSTRAINT_ERROR:			return "Failure to adhere to constraint";
			case REENTRANCE_ERROR:			return "Reentrance detected - aborting";
			case FILE_VALIDATION_ERROR:		return "File validation error";
			case FILE_MORE_RECENT_ERROR:	return "File was saved in a more recent version of Integra, and cannot be loaded in this version.\n\nPlease upgrade to the latest version of Integra.";
			case MODULE_ALREADY_INSTALLED:	return "Module already installed";

			default:						
				INTEGRA_TRACE_ERROR << "encountered unknown error code";
				return "Unknown error";
		}
	}
}