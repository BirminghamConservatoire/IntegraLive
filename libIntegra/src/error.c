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

#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "Integra/integra.h"

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif


char *ntg_error_text( ntg_error_code error_code )
{
    switch( error_code ) 
	{
		case NTG_NO_ERROR:
            return "No error";
		case NTG_ERROR:
            return "Input error";
		case NTG_FAILED:
            return "Function failure";
		case NTG_MEMORY_ALLOCATION_ERROR:
            return "Memory allocation error";
		case NTG_MEMORY_FREE_ERROR:
            return "Memory free error";
		case NTG_TYPE_ERROR:
            return "Incorrect data type";
		case NTG_PATH_ERROR:
            return "Erroneous or incorrect path";
		case NTG_CONSTRAINT_ERROR:
            return "Failure to adhere to constraint";
		case NTG_REENTRANCE_ERROR:
            return "Reentrance detected - aborting";
		case NTG_FILE_VALIDATION_ERROR:
            return "File validation error";
		case NTG_FILE_MORE_RECENT_ERROR:
            return "File was saved in a more recent version of Integra, and cannot be loaded in this version.\n\nPlease upgrade to the latest version of Integra.";

        default:
            return "Unknown error";
    }
}
