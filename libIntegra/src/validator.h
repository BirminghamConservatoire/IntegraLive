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

#ifndef INTEGRA_VALIDATE_H
#define INTEGRA_VALIDATE_H


#include <libxml/parser.h>
#include <libxml/xmlschemas.h>

#include "error.h"

using namespace integra_api;


namespace integra_internal
{
	class CValidator
	{
		public:

			CValidator();
			~CValidator();

			/* \brief high-level function to validate an IXD 
			 *
			 * \param *xml_buffer pointer to buffer containing xml data
			 * \param buffer_length size of buffer in bytes
			 */
			CError validate_ixd( const char *xml_buffer, unsigned int buffer_length );

		private:


			xmlDocPtr document_read( const char *xml_buffer, unsigned int buffer_length );
			CError document_free( xmlDocPtr doc );

			CError validate_against_schema( const xmlDocPtr doc );

			xmlSchemaParserCtxtPtr m_schema_parser_context;
			xmlSchemaPtr m_schema;
			xmlSchemaValidCtxtPtr m_validity_context;

			static const char *schema_file;
	};


}


#endif
