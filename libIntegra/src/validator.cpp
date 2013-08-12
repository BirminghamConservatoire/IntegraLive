/** libIntegra multimedia module interface
 *  
 * Copyright (C) 2007 Birmingham City University
 *
 * This program is free software  you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation  either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY  without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program  if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, 
 * USA.
 */

#include "platform_specifics.h"

#include <assert.h>

#include "validator.h"
#include "trace.h"
#include "string_helper.h"


namespace integra_internal
{
	const char *CValidator::schema_file = "CollectionSchema.xsd";

	static void schemaErrorCallback( void *none, const char *message, ...)
	{
		char trace[ CStringHelper::string_buffer_length ];
		va_list varArgs;
		va_start(varArgs, message);
		vsnprintf( trace, CStringHelper::string_buffer_length, message, varArgs);
		va_end(varArgs);

		NTG_TRACE_ERROR << trace;
	}


	static void schemaWarningCallback( void *callbackData, const char *message, ...)
	{
		char trace[ CStringHelper::string_buffer_length ];
		va_list varArgs;
		va_start(varArgs, message);
		vsnprintf( trace, CStringHelper::string_buffer_length, message, varArgs);
		va_end(varArgs);

		NTG_TRACE_ERROR << trace;
	}


	CValidator::CValidator()
	{
		m_schema_parser_context = NULL;
		m_schema = NULL;
		m_validity_context = NULL;

		m_schema_parser_context = xmlSchemaNewParserCtxt( schema_file );

		if( m_schema_parser_context )
		{
			m_schema = xmlSchemaParse( m_schema_parser_context );
		}
		else 
		{
			NTG_TRACE_ERROR << "Unable to get schema parser context";
			return;
		}

		if( m_schema)
		{
			m_validity_context = xmlSchemaNewValidCtxt( m_schema );
		}
		else 
		{
			NTG_TRACE_ERROR << "Unable to get schema from schema parser context";
			return;
		}
	}


	CValidator::~CValidator()
	{
		if( m_schema ) 
		{
			xmlSchemaFree( m_schema );
		}

		if( m_schema_parser_context ) 
		{
			xmlSchemaFreeParserCtxt( m_schema_parser_context );
		}

		if( m_validity_context ) 
		{
			xmlSchemaFreeValidCtxt( m_validity_context );
		}
	}


	
	CError CValidator::validate_ixd( const char *xml_buffer, unsigned int buffer_length )
	{
		assert( xml_buffer );

		xmlDocPtr doc = document_read( xml_buffer, buffer_length );

		CError validation_code = validate_against_schema( doc );

		document_free( doc );

		if( validation_code != CError::SUCCESS ) 
		{
			NTG_TRACE_ERROR << "validation failed: " << validation_code.get_text();
			return CError::FILE_VALIDATION_ERROR;
		}

		return CError::SUCCESS;	
	}


	xmlDocPtr CValidator::document_read( const char *xml_buffer, unsigned int buffer_length )
	{
		assert( xml_buffer );

		xmlDocPtr doc = xmlParseMemory( xml_buffer, buffer_length );

		xmlNodePtr cur = xmlDocGetRootElement(doc);

		if( !cur ) 
		{
			NTG_TRACE_ERROR << "XML document is empty";
			document_free( doc );
			return NULL;
		}

		return doc;
	}


	CError CValidator::document_free( xmlDocPtr doc )
	{
		if( doc ) 
		{
			xmlFreeDoc( doc );
			return CError::SUCCESS;
		} 
		else 
		{
			NTG_TRACE_ERROR << "XML document pointer is NULL, no resource freed.";
			return CError::INPUT_ERROR;
		}
	}


	CError CValidator::validate_against_schema( const xmlDocPtr doc )
	{
		int validation_code;

		if( !m_validity_context ) 
		{
			NTG_TRACE_ERROR << "XML validity context is NULL";
			return CError::FAILED;
		}

		xmlSchemaSetValidErrors( m_validity_context, schemaErrorCallback, schemaWarningCallback,
								/* callback data */ 0 );

		validation_code = xmlSchemaValidateDoc( m_validity_context, doc );

		if( validation_code > 0 ) return CError::INPUT_ERROR;
		if( validation_code < 0 ) return CError::FAILED;
		return CError::SUCCESS;
	}
}

