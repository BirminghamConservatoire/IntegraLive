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

#ifndef INTEGRA_HELPER_H
#define INTEGRA_HELPER_H


#include <stdio.h>

#include "api/common_typedefs.h"
#include "error.h"


/* test guids for equality*/
bool ntg_guids_are_equal( const GUID *guid1, const GUID *guid2 );


/* nullify guid */
void ntg_guid_set_null( GUID *guid );

/* test guid for nullness */
bool ntg_guid_is_null( const GUID *guid );


/* converts guid to string in lowercase hexadecimal form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".  Caller must free */
char *ntg_guid_to_string( const GUID *guid );

/* converts string to guid.  expects string in hexadecimal form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" */
ntg_api::CError ntg_string_to_guid( const char *string, GUID *output );


/* converts date/time to ISO 8601 string.  Caller must free */
char *ntg_date_to_string( const struct tm *date );

/* converts string to date/time.  expects string in ISO 8601 form eg 2012-07-20T14:42 */
ntg_api::CError ntg_string_to_date( const char *input, struct tm &output );


/* does the node name consist entirely of valid characters? */
bool ntg_validate_node_name( const char *name );


/** \brief Get the current version of libIntegra 
 * \param *destination: a pointer to a string into which the 
 * version number is written
 * \param *destination_size: the maximum number of characters 
 * which may be written to destination
 */
ntg_api::string ntg_version();




#endif
