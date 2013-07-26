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

#include "validate.h"
#include "helper.h"
#include "globals.h"

using namespace ntg_api;


void schemaErrorCallback(void *none, const char *message, ...)
{
	char trace[ NTG_LONG_STRLEN ];
    va_list varArgs;
    va_start(varArgs, message);
    vsnprintf( trace, NTG_LONG_STRLEN, message, varArgs);
    va_end(varArgs);

	NTG_TRACE_ERROR( trace );
}

void schemaWarningCallback(void *callbackData, const char *message, ...)
{
	char trace[ NTG_LONG_STRLEN ];
    va_list varArgs;
    va_start(varArgs, message);
    vsnprintf( trace, NTG_LONG_STRLEN, message, varArgs);
    va_end(varArgs);

	NTG_TRACE_ERROR( trace );
}


ntg_xml_sac *ntg_xml_get_sac(const char *schema_path)
{

    ntg_xml_sac *sac;

    sac = new ntg_xml_sac;

    sac->schema_parser_context = NULL;
    sac->schema = NULL;
    sac->validity_context = NULL;

    sac->schema_parser_context = xmlSchemaNewParserCtxt(schema_path);

    if (sac->schema_parser_context != NULL)
        sac->schema = xmlSchemaParse(sac->schema_parser_context);
    else {
        NTG_TRACE_ERROR("Unable to get schema parser context");
        return NULL;
    }

    if (sac->schema != NULL)
        sac->validity_context = xmlSchemaNewValidCtxt(sac->schema);
    else {
        NTG_TRACE_ERROR("Unable to get schema from schema parser context");
        return NULL;
    }

    return sac;

}

error_code ntg_xml_destroy_sac(ntg_xml_sac * sac)
{

    xmlSchemaFree(sac->schema);
    xmlSchemaFreeParserCtxt(sac->schema_parser_context);
    xmlSchemaFreeValidCtxt(sac->validity_context);

    delete sac;

    return NTG_NO_ERROR;

}

xmlDocPtr ntg_xml_document_read( const char *xml_buffer, unsigned int buffer_length )
{
    xmlDocPtr doc = NULL;
    xmlNodePtr cur = NULL;

	assert( xml_buffer );

	doc = xmlParseMemory( xml_buffer, buffer_length );

	cur = xmlDocGetRootElement(doc);

    if (cur == NULL) {
        NTG_TRACE_ERROR("XML document is empty");
        xmlFreeDoc(doc);
        return NULL;
    }

    return doc;
}


error_code ntg_xml_docptr_free(xmlDocPtr doc)
{

    if (doc != NULL) {
        xmlFreeDoc(doc);
        /* FIX: we need to check the return value of xmlFreeDoc() */
        return NTG_NO_ERROR;
    } else {
        NTG_TRACE_ERROR("XML document pointer is NULL, no resource freed.");
        return NTG_FAILED;
    }
}

error_code ntg_xml_validate_against_schema(const xmlDocPtr doc, const ntg_xml_sac * sac)
{
    int validation_code;

    if (sac == NULL) {
        NTG_TRACE_ERROR("sac pointer is NULL");
        return NTG_FAILED;
    }

    if (sac->validity_context != NULL) {

        xmlSchemaSetValidErrors(sac->validity_context,
                                schemaErrorCallback, schemaWarningCallback,
                                /* callback data */ 0);

        validation_code = xmlSchemaValidateDoc(sac->validity_context, doc);
    } else {
        NTG_TRACE_ERROR("XML validity context is NULL");
        return NTG_FAILED;
    }

	if( validation_code > 0 ) return NTG_ERROR;
	if( validation_code < 0 ) return NTG_FAILED;
	return NTG_NO_ERROR;
}

FILE *ntg_xml_dump_schema(const ntg_xml_sac * sac, const char *file_path)
{
    FILE *fp;

    if ((fp = fopen(file_path, "w")) == NULL) {
        NTG_TRACE_ERROR_WITH_STRING("Could not open the file at", file_path);
        return NULL;
    } else {
        xmlSchemaDump(fp, sac->schema);
    }
    return fp;
}


error_code ntg_xml_validate( const char *xml_buffer, unsigned int buffer_length )
{
    char *schema_path = NULL;
    int validation_code;
    xmlDocPtr doc;
    ntg_xml_sac *sac;

	assert( xml_buffer );

    schema_path = NTG_SCHEMA_FILE;

    doc = ntg_xml_document_read(xml_buffer, buffer_length);
    sac = ntg_xml_get_sac(schema_path);

    validation_code = ntg_xml_validate_against_schema(doc, sac);

    ntg_xml_docptr_free(doc);
    ntg_xml_destroy_sac(sac);

    if (validation_code) 
	{
        NTG_TRACE_ERROR_WITH_INT("validation failed, error code", validation_code);
        return NTG_FILE_VALIDATION_ERROR;
    }

    return NTG_NO_ERROR;
}
