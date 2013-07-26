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


/*! \addtogroup serialize 
 * @{
 */

/**
 * \file integra_validate.h 
 * \brief Declares functions for XML validation
 */

#include <libxml/parser.h>
#include <libxml/xmlschemas.h>

#include "error.h"

#define NTG_SCHEMA_FILE "CollectionSchema.xsd"

/** 
 * \brief Struct to hold XML schema, schema validity context and 
 * schema parser context
 *
 * sac is an acronym for 'schema and contexts'
 *
 * */
typedef struct ntg_xml_sac_ {
    
    xmlSchemaParserCtxtPtr schema_parser_context;
    xmlSchemaPtr schema;
    xmlSchemaValidCtxtPtr validity_context;

    /* FIX: anything else in here? Schema ID, type code? */
} ntg_xml_sac;

/**
 * \brief Create a schema validity context from a given schema file
 *
 * This function returns a pointer to a schema validity context given the 
 * full path (or URI) to a schema info (XSD) file.
 *
 * \param char *schema_path A pointer to a NULL terminated string representing
 * the path to a schema info file.
 * \return a pointer to a schema validity context
 */
ntg_xml_sac *ntg_xml_get_sac(const char *schema_path);

/**
 * \brief Destroy an ntg_xml_sac
 *
 * \param a pointer to an ntg_xml_sac
 * \return an ntg error code as defined in integra_error.h
 *
 */
ntg_api::error_code ntg_xml_destroy_sac(ntg_xml_sac *sac);

/** \brief Read an XML document from file 
 *
 * \param *xml_buffer pointer to buffer containing xml data
 * \param buffer_length size of buffer in bytes
 * \return a valid xmlDocPtr
 *
 */
xmlDocPtr ntg_xml_document_read( const char *xml_buffer, unsigned int buffer_length );

/** \brief Free an XML document
 *
 * \param doc A pointer of type xmlDocPtr
 * \return An error code as defined in integra_error.h
 *
 */
ntg_api::error_code ntg_xml_docptr_free(xmlDocPtr doc);

/**
 * \brief Validate an XML document
 *
 * This function takes an xmlDocPtr, and an ntg_xml_sac and returns a 
 * validation code that indicates whether the document pointed to by the 
 * xmlDocPtr variable validates against the given schema.
 *
 * \param xmlDocPtr doc A pointer to an XML document
 * \param ntg_xml_sac A pointer to an ntg_xml_sac struct
 */
ntg_api::error_code ntg_xml_validate_against_schema(const xmlDocPtr doc,
                                    const ntg_xml_sac *sac);

/**
 * \brief Dump Schema file pointed to by the @sac.
 *
 * This simple function wraps the libxml2 xmlSchemaDump()
 * function. It simply writes a (even more) human readable
 * version of the XML Schema pointed to by the @sac structure.
 * The caller must make sure the file is properly closed after 
 * the call has been made and the output file is no longer 
 * referenced.
 * 
 * \param ntg_xml_sac A pointer to an ntg_xml_sac struct
 * \param FILE The file to dump the schema to.
 */
FILE *ntg_xml_dump_schema(const ntg_xml_sac *sac,
                          const char *file_path);


/* \brief high-level function to validate an IXD 
 *
 * \param *xml_buffer pointer to buffer containing xml data
 * \param buffer_length size of buffer in bytes
 */
ntg_api::error_code ntg_xml_validate( const char *xml_buffer, unsigned int buffer_length );

/*! @} */

#endif
