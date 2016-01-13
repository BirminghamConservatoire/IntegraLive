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


#include "platform_specifics.h"

#include <assert.h>

#include "validator.h"
#include "api/trace.h"
#include "api/string_helper.h"


namespace integra_internal
{
	static void schemaErrorCallback( void *none, const char *message, ...)
	{
		char trace[ CStringHelper::string_buffer_length ];
		va_list varArgs;
		va_start(varArgs, message);
		vsnprintf( trace, CStringHelper::string_buffer_length, message, varArgs);
		va_end(varArgs);

		INTEGRA_TRACE_ERROR << trace;
	}


	static void schemaWarningCallback( void *callbackData, const char *message, ...)
	{
		char trace[ CStringHelper::string_buffer_length ];
		va_list varArgs;
		va_start(varArgs, message);
		vsnprintf( trace, CStringHelper::string_buffer_length, message, varArgs);
		va_end(varArgs);

		INTEGRA_TRACE_ERROR << trace;
	}

	CValidator::CValidator(char *schema_file)
	{
		INTEGRA_TRACE_VERBOSE << "Initialising validator for primary schema " << schema_file;

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
			INTEGRA_TRACE_ERROR << "Unable to get schema parser context";
			return;
		}

		if( m_schema)
		{
			m_validity_context = xmlSchemaNewValidCtxt( m_schema );
		}
		else 
		{
			INTEGRA_TRACE_ERROR << "Unable to get schema from schema parser context";
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

		m_transform_validators.clear();
	}

	CError CValidator::validate( const char *xml_buffer, unsigned int buffer_length )
	{
		INTEGRA_TRACE_VERBOSE << "Validating raw XML data against primary schema";

		assert( xml_buffer );

		xmlDocPtr src_cur = document_read( xml_buffer, buffer_length );

		CError validation_code = validate_against_schema( src_cur );

		xmlSubstituteEntitiesDefault(1);

		// iterate over any registered transform validators
		for( transform_validator_map::iterator i = m_transform_validators.begin(); i != m_transform_validators.end() && validation_code == CError::SUCCESS; i++ )
		{
			INTEGRA_TRACE_PROGRESS << "Validating transformed XML data against secondary schema";
			INTEGRA_TRACE_PROGRESS << ""; // output a blank trace header for any messages produced during validation

			// transform xml_buffer by transform_file
			xsltStylesheetPtr xsl_cur = xsltParseStylesheetFile((xmlChar*)i->first);
			if(!xsl_cur)
			{
				validation_code = CError::FAILED;
				break;
			}

			xmlDocPtr tgt_cur = xsltApplyStylesheet(xsl_cur, src_cur, NULL);
			if(!tgt_cur)
			{
				validation_code = CError::FAILED;
				break;
			}

			// dump to buffer (debugging option)
			xmlChar *output_buffer = NULL;
			int output_buffer_size = NULL;
			xmlDocDumpMemory(tgt_cur, &output_buffer, &output_buffer_size);
			xmlFree(output_buffer);

			// dump to stdout (debugging option)
			//xsltSaveResultToFile(stdout, tgt_cur, xsl_cur);

			// dump to file (debugging option)
			//xsltSaveResultToFilename(strcat(i->first,".out"), tgt_cur, xsl_cur,0);

			// validate output
			CValidator *transform_validator = i->second;
			validation_code = transform_validator->validate_against_schema(tgt_cur);

			// tidy up
			document_free(tgt_cur);
			xsltFreeStylesheet(xsl_cur);

			// NB: do not call xmlCleanupParser here, or further use of libxml will likely be compromised
		}

		document_free( src_cur );

		if( validation_code != CError::SUCCESS ) 
		{
			INTEGRA_TRACE_ERROR << "validation failed: " << validation_code.get_text();
			return CError::FILE_VALIDATION_ERROR;
		}

		INTEGRA_TRACE_VERBOSE << "validation succeeded";

		return CError::SUCCESS;
	}

	CError CValidator::register_transform(char *transform_file,char *transform_schema_file)
	{
		INTEGRA_TRACE_VERBOSE << "Registering secondary schema " << transform_schema_file << " for output of transform " << transform_file;

		if(m_transform_validators.find(transform_file) == m_transform_validators.end()) 
		{
			m_transform_validators[transform_file] = new CValidator(transform_schema_file);

			return CError::SUCCESS;	
		}
		else
		{
			INTEGRA_TRACE_ERROR << "Transform " << transform_file << " has already been registered";

			return CError::FAILED;
		}
	}

	xmlDocPtr CValidator::document_read( const char *xml_buffer, unsigned int buffer_length )
	{
		assert( xml_buffer );

		xmlDocPtr doc = xmlParseMemory( xml_buffer, buffer_length );

		xmlNodePtr cur = xmlDocGetRootElement(doc);

		if( !cur ) 
		{
			INTEGRA_TRACE_ERROR << "XML document is empty";
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
			INTEGRA_TRACE_ERROR << "XML document pointer is NULL, no resource freed.";
			return CError::INPUT_ERROR;
		}
	}


	CError CValidator::validate_against_schema( const xmlDocPtr doc )
	{
		int validation_code;

		if( !m_validity_context ) 
		{
			INTEGRA_TRACE_ERROR << "XML validity context is NULL";
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

