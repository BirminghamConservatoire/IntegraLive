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


#ifndef INTEGRA_VALIDATE_H
#define INTEGRA_VALIDATE_H

#include <unordered_map>

#include <libxml/parser.h>
#include <libxml/xmlschemas.h>

#include <string.h>
#include <libxml/xmlmemory.h>
#include <libxml/debugXML.h>
#include <libxml/HTMLtree.h>
#include <libxml/xmlIO.h>
#include <libxml/DOCBparser.h>
#include <libxml/xinclude.h>
#include <libxml/catalog.h>

#include <libxslt/xslt.h>
#include <libxslt/xsltInternals.h>
#include <libxslt/transform.h>
#include <libxslt/xsltutils.h>

#include "api/error.h"

using namespace integra_api;


namespace integra_internal
{
	class CValidator
	{
		public:

			CValidator(char *schema_file = "CollectionSchema.xsd");
			~CValidator();

			/* \brief high-level function to validate an XML document against the configured schema (renamed from "validate_ixd")
			 *
			 * \param *xml_buffer pointer to buffer containing xml data
			 * \param buffer_length size of buffer in bytes
			 */
			CError validate( const char *xml_buffer, unsigned int buffer_length );

			/* \brief registers an additional transform validation step, based on a transformed version of the source document and a secondary schema
			 * \param *transform_file filename of an XSL transform
			 * \param *transform_schema_file filename of the associated XSD schema file
			 */
			CError register_transform(char *transform_file,char *transform_schema_file);

		private:

			xmlDocPtr document_read( const char *xml_buffer, unsigned int buffer_length );
			CError document_free( xmlDocPtr doc );

			CError validate_against_schema( const xmlDocPtr doc );

			xmlSchemaParserCtxtPtr m_schema_parser_context;
			xmlSchemaPtr m_schema;
			xmlSchemaValidCtxtPtr m_validity_context;

			char *schema_file;

			typedef std::unordered_map<char*,CValidator*> transform_validator_map;

			transform_validator_map m_transform_validators;
	};


}


#endif
