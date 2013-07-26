/** libIntegra multimedia module interface
 *
 * Copyright (C) 2012 Birmingham City University
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
#include <dirent.h>
#include <sys/stat.h>

#include <libxml/xmlreader.h>

#include "../externals/minizip/zip.h"
#include "../externals/minizip/unzip.h"
#include <libxml/xmlreader.h>
#include <libxml/xmlwriter.h>

#include "file_io.h"
#include "globals.h"
#include "helper.h"
#include "data_directory.h"
#include "module_manager.h"
#include "interface.h"
#include "validate.h"
#include "server_commands.h"

#define NTG_STR_INTEGRA_COLLECTION "IntegraCollection"
#define NTG_STR_INTEGRA_VERSION "integraVersion"
#define NTG_STR_OBJECT "object"
#define NTG_STR_ATTRIBUTE "attribute"
#define NTG_STR_MODULEID "moduleId"
#define NTG_STR_ORIGINID "originId"
#define NTG_STR_NAME "name"
#define NTG_STR_TYPECODE "typeCode"

//used in older versions
#define NTG_STR_INSTANCEID "instanceId"
#define NTG_STR_CLASSID "classId"



#ifndef _WINDOWS
#define _S_IFMT S_IFMT
#endif

using namespace ntg_api;
using namespace ntg_internal;



void ntg_init_zip_file_info( zip_fileinfo *info )
{
	time_t raw_time;
	struct tm *current_time;

	time( &raw_time );
	current_time = localtime( &raw_time );

	info->tmz_date.tm_year = current_time->tm_year;
	info->tmz_date.tm_mon = current_time->tm_mon;
	info->tmz_date.tm_mday = current_time->tm_mday;
	info->tmz_date.tm_hour = current_time->tm_hour;
	info->tmz_date.tm_min = current_time->tm_min;
	info->tmz_date.tm_sec = current_time->tm_sec;

	info->dosDate = 0;
	info->internal_fa = 0;
	info->external_fa = 0;
}


error_code ntg_delete_file( const char *file_name )
{
	if( remove( file_name ) != 0 )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Failed to remove file", file_name );
		return NTG_FAILED;
	}

	return NTG_NO_ERROR;
}


error_code ntg_copy_file( const char *source_path, const char *target_path )
{
	FILE *source_file = NULL;
	FILE *target_file = NULL;
	unsigned char *copy_buffer = NULL;
	unsigned long bytes_to_copy = 0;
	unsigned long bytes_read = 0;
	error_code error_code = NTG_FAILED;

	assert( source_path && target_path );

	source_file = fopen( source_path, "rb" );
	if( !source_file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "failed to open", source_path );
		return NTG_FAILED;
	}

	fseek( source_file, 0, SEEK_END );
	bytes_to_copy = ftell( source_file );
	fseek( source_file, 0, SEEK_SET );

	target_file = fopen( target_path, "wb" );
	if( !target_file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "couldn't open for writing", target_path );
		goto CLEANUP;
	}

	copy_buffer = new unsigned char[ NTG_DATA_COPY_BUFFER_SIZE ];

	while( bytes_to_copy > 0 )
	{
		bytes_read = fread( copy_buffer, 1, MIN( bytes_to_copy, NTG_DATA_COPY_BUFFER_SIZE ), source_file );
		if( bytes_read <= 0 )
		{
			NTG_TRACE_ERROR_WITH_STRING( "error reading", source_path );
			goto CLEANUP;
		}

		fwrite( copy_buffer, 1, bytes_read, target_file );
		bytes_to_copy -= bytes_read;
	}

	error_code = NTG_NO_ERROR;

CLEANUP:

	if( copy_buffer )	delete[] copy_buffer;
	if( target_file )	fclose( target_file );
	if( source_file )	fclose( source_file );

	return error_code;
}


void ntg_copy_file_to_zip( zipFile zip_file, const char *target_path, const char *source_path )
{
	zip_fileinfo zip_file_info;
	FILE *input_file;
	unsigned char *buffer;
	size_t bytes_read;

	ntg_init_zip_file_info( &zip_file_info );

	input_file = fopen( source_path, "rb" );
	if( !input_file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "couldn't open", source_path );
		return;
	}

	buffer = new unsigned char[ NTG_DATA_COPY_BUFFER_SIZE ];

	zipOpenNewFileInZip( zip_file, target_path, &zip_file_info, NULL, 0, NULL, 0, NULL, Z_DEFLATED, Z_DEFAULT_COMPRESSION );

	while( !feof( input_file ) )
	{
		bytes_read = fread( buffer, 1, NTG_DATA_COPY_BUFFER_SIZE, input_file );
		if( bytes_read > 0 )
		{
			zipWriteInFileInZip( zip_file, buffer, bytes_read );
		}
		else
		{
			if( ferror( input_file ) )
			{
				NTG_TRACE_ERROR_WITH_STRING( "Error reading file", source_path );
				break;
			}
		}
	}
	
	zipCloseFileInZip( zip_file );

	delete[] buffer;

	fclose( input_file );
}


void ntg_copy_directory_contents_to_zip( zipFile zip_file, const char *target_path, const char *source_path )
{
	DIR *directory_stream;
	struct dirent *directory_entry;
	const char *file_name;
	char *full_source_path;
	char *full_target_path;
	struct stat entry_data;

	directory_stream = opendir( source_path );
	if( !directory_stream )
	{
		NTG_TRACE_ERROR_WITH_STRING( "unable to open directory", source_path );
		return;
	}

	while( true )
	{
		directory_entry = readdir( directory_stream );
		if( !directory_entry )
		{
			break;
		}

		file_name = directory_entry->d_name;

		if( strcmp( file_name, ".." ) == 0 || strcmp( file_name, "." ) == 0 )
		{
			continue;
		}

		full_source_path = ntg_strdup( source_path );
		full_source_path = ntg_string_append( full_source_path, file_name );

		if( stat( full_source_path, &entry_data ) != 0 )
		{
			NTG_TRACE_ERROR_WITH_ERRNO( "couldn't read directory entry data" );
			delete[] full_source_path;
			continue;
		}

		full_target_path = new char[ strlen( NTG_INTEGRA_DATA_DIRECTORY_NAME ) + strlen( target_path ) + strlen( NTG_PATH_SEPARATOR ) + strlen( file_name ) + 1 ];
		sprintf( full_target_path, "%s%s%s%s", NTG_INTEGRA_DATA_DIRECTORY_NAME, target_path, NTG_PATH_SEPARATOR, file_name );

		switch( entry_data.st_mode & _S_IFMT )
		{
			case S_IFDIR:	/* directory */
				full_source_path = ntg_string_append( full_source_path, NTG_PATH_SEPARATOR );
				ntg_copy_directory_contents_to_zip( zip_file, full_target_path, full_source_path );
				break;

			default:
				ntg_copy_file_to_zip( zip_file, full_target_path, full_source_path );
				break;
		}

		delete[] full_target_path;
		delete[] full_source_path;
	}
	while( directory_entry != NULL );
}


void ntg_find_module_guids_to_embed( const CNode &node, guid_set &module_guids_to_embed )
{
	if( ntg_interface_should_embed_module( node.get_interface() ) )
	{
		module_guids_to_embed.insert( node.get_interface()->module_guid );
	}

	/* walk subtree */
	const node_map &children = node.get_children();
	for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
	{
		ntg_find_module_guids_to_embed( *i->second, module_guids_to_embed );
	}
}


/* taken from libxml2 examples */
xmlChar *ConvertInput(const char *in, const char *encoding)
{
    unsigned char *out;
    int ret;
    int size;
    int out_size;
    int temp;
    xmlCharEncodingHandlerPtr handler;

    if (in == 0)
        return 0;

    handler = xmlFindCharEncodingHandler(encoding);

    if (!handler) {
        NTG_TRACE_ERROR_WITH_STRING("ConvertInput: no encoding handler found for",
               encoding ? encoding : "");
        return NULL;
    }

    size = (int)strlen(in) + 1;
    out_size = size * 2 - 1;
    out = new unsigned char[ out_size ];

    if (out != 0) {
        temp = size - 1;
        ret = handler->input(out, &out_size, (const xmlChar *)in, &temp);
        if ((ret < 0) || (temp - size + 1)) {
            if (ret < 0) {
                NTG_TRACE_ERROR("ConvertInput: conversion wasn't successful.");
            } else {
                NTG_TRACE_ERROR_WITH_INT
                    ("ConvertInput: conversion wasn't successful. converted octets",
                     temp);
            }

            free(out);
            out = NULL;
        } else {
			unsigned char *new_buffer = new unsigned char[ out_size + 1 ];
			memcpy( new_buffer, out, out_size );
			new_buffer[ out_size ] = 0;	/* null terminating out */
			delete out;
			out = new_buffer;
        }
    } else {
        NTG_TRACE_ERROR("ConvertInput: no mem");
    }

    return out;
}

void ntg_copy_node_modules_to_zip( zipFile zip_file, const CNode &node, const CModuleManager &module_manager )
{
	const ntg_interface *interface;
	char *target_path;

	assert( zip_file );

	guid_set module_guids_to_embed;
	ntg_find_module_guids_to_embed( node, module_guids_to_embed );

	for( guid_set::const_iterator i = module_guids_to_embed.begin(); i != module_guids_to_embed.end(); i++ )
	{
		interface = module_manager.get_interface_by_module_id( *i );
		if( !interface )
		{
			NTG_TRACE_ERROR( "Failed to retrieve interface" );
			continue;
		}

		if( !interface->file_path )
		{
			NTG_TRACE_ERROR( "Failed to locate module file" );
			continue;
		}

		string unique_interface_name = module_manager.get_unique_interface_name( *interface );

		target_path = new char[ strlen( NTG_INTEGRA_IMPLEMENTATION_DIRECTORY_NAME ) + unique_interface_name.length() + strlen( NTG_MODULE_SUFFIX ) + 2 ];
		sprintf( target_path, "%s%s.%s", NTG_INTEGRA_IMPLEMENTATION_DIRECTORY_NAME, unique_interface_name.c_str(), NTG_MODULE_SUFFIX );

		ntg_copy_file_to_zip( zip_file, target_path, interface->file_path );

		delete[] target_path;
	}
}


error_code ntg_load_ixd_buffer_directly( const char *file_path, unsigned char **ixd_buffer, unsigned int *ixd_buffer_length )
{
	FILE *file;
	size_t bytes_loaded;

	assert( file_path && ixd_buffer && ixd_buffer_length );
	
	file = fopen( file_path, "rb" );
	if( !file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Couldn't open file", file_path );
		return NTG_FAILED;
	}

	/* find size of the file */
	fseek( file, 0, SEEK_END );
	*ixd_buffer_length = ftell( file );
	fseek( file, 0, SEEK_SET );

	*ixd_buffer = new unsigned char[ *ixd_buffer_length ];
	bytes_loaded = fread( *ixd_buffer, 1, *ixd_buffer_length, file );
	fclose( file );

	if( bytes_loaded != *ixd_buffer_length )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Error reading from file", file_path );
		return NTG_FAILED;
	}

	return NTG_NO_ERROR;
}


error_code ntg_load_ixd_buffer( const char *file_path, unsigned char **ixd_buffer, unsigned int *ixd_buffer_length, bool *is_zip_file )
{
	unzFile unzip_file;
	unz_file_info file_info;

	assert( file_path && ixd_buffer && ixd_buffer_length );

	unzip_file = unzOpen( file_path );
	if( !unzip_file )
	{
		/* maybe file_path itself is an xml file saved before introduction of data directories */

		*is_zip_file = false;
		return ntg_load_ixd_buffer_directly( file_path, ixd_buffer, ixd_buffer_length );
	}
	else
	{
		*is_zip_file = true;
	}	

	if( unzLocateFile( unzip_file, NTG_INTERNAL_IXD_FILE_NAME, 0 ) != UNZ_OK )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Unable to locate " NTG_INTERNAL_IXD_FILE_NAME, file_path );
		unzClose( unzip_file );
		return NTG_FAILED;
	}

	if( unzGetCurrentFileInfo( unzip_file, &file_info, NULL, 0, NULL, 0, NULL, 0 ) != UNZ_OK )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Couldn't get info for " NTG_INTERNAL_IXD_FILE_NAME, file_path );
		unzClose( unzip_file );
		return NTG_FAILED;
	}

	if( unzOpenCurrentFile( unzip_file ) != UNZ_OK )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Unable to open " NTG_INTERNAL_IXD_FILE_NAME, file_path );
		unzClose( unzip_file );
		return NTG_FAILED;
	}

	*ixd_buffer_length = file_info.uncompressed_size;
	*ixd_buffer = new unsigned char[ *ixd_buffer_length ];

	if( unzReadCurrentFile( unzip_file, *ixd_buffer, *ixd_buffer_length ) != *ixd_buffer_length )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Unable to read " NTG_INTERNAL_IXD_FILE_NAME, file_path );
		unzClose( unzip_file );
		delete[] *ixd_buffer;
		return NTG_FAILED;
	}

	unzClose( unzip_file );

	return NTG_NO_ERROR;
}


char *ntg_get_top_level_node_name( const char *filename )
{
	const char *last_slash, *last_backslash;
	int index_after_last_slash = 0;
	int index_after_last_backslash = 0;
	int index_of_extension = 0;
	int i, length;
	char *name;
	
	assert( filename );

	/* strip path from filename */
	last_slash = strrchr( filename, '/' );
	last_backslash = strrchr( filename, '\\' );

	if( last_slash ) index_after_last_slash = ( last_slash + 1 - filename );
	if( last_backslash ) index_after_last_backslash = ( last_backslash + 1 - filename );

	name = ntg_strdup( filename + MAX( index_after_last_slash, index_after_last_backslash ) );

	/* strip extension */
	index_of_extension = strlen( name ) - strlen( NTG_FILE_SUFFIX ) - 1;
	if( index_of_extension > 0 && strcmp( name + index_of_extension, "."NTG_FILE_SUFFIX ) == 0 )
	{
		name[ index_of_extension ] = 0;
	}

	/* remove illegal characters */
	length = strlen( name );
	for( i = 0; i < length; i++ )
	{
		if( !strchr( NTG_NODE_NAME_CHARACTER_SET, name[ i ] ) )
		{
			name[ i ] = '_';
		}
	}
	
	return name;
}


error_code ntg_save_node_tree( const CNode &node, xmlTextWriterPtr writer)
{
    xmlChar *tmp;

    xmlTextWriterStartElement( writer, BAD_CAST NTG_STR_OBJECT );

    /* write out node->interface->module_guid */
	char *guid_string = ntg_guid_to_string( &node.get_interface()->module_guid );
    tmp = ConvertInput( guid_string, XML_ENCODING);
	xmlTextWriterWriteFormatAttribute(writer, BAD_CAST NTG_STR_MODULEID, (char * ) tmp );
	free( tmp );
	delete[] guid_string;

    /* write out node->interface->origin_guid */
	guid_string = ntg_guid_to_string( &node.get_interface()->origin_guid );
    tmp = ConvertInput(guid_string, XML_ENCODING);
	xmlTextWriterWriteFormatAttribute(writer, BAD_CAST NTG_STR_ORIGINID, (char * ) tmp );
	free( tmp );
	delete[] guid_string;

    /* write out node->name */
    tmp = ConvertInput( node.get_name().c_str(), XML_ENCODING);
    xmlTextWriterWriteAttribute(writer, BAD_CAST NTG_STR_NAME, BAD_CAST tmp);
	free( tmp );

	const node_endpoint_map &node_endpoints = node.get_node_endpoints();
	for( node_endpoint_map::const_iterator node_endpoint_iterator = node_endpoints.begin(); node_endpoint_iterator != node_endpoints.end(); node_endpoint_iterator++ )
	{
		const CNodeEndpoint *node_endpoint = node_endpoint_iterator->second;
		const CValue *value = node_endpoint->get_value();
		const ntg_endpoint *endpoint = node_endpoint->get_endpoint();
		if( !value || !endpoint->control_info->state_info->is_saved_to_file ) 
		{
			continue;
		}

        /* write attribute->name */
		CValue::type type = value->get_type();

		tmp = ConvertInput( endpoint->name, XML_ENCODING);
        xmlTextWriterStartElement(writer, BAD_CAST NTG_STR_ATTRIBUTE);
        xmlTextWriterWriteAttribute(writer, BAD_CAST NTG_STR_NAME,
                                    BAD_CAST tmp);
		free( tmp );

        /* write type */
        xmlTextWriterWriteFormatAttribute(writer, BAD_CAST NTG_STR_TYPECODE, "%d", CValue::type_to_ixd_code( type ) );

        /* write attribute->value */
		string value_string = value->get_as_string();
        tmp = ConvertInput( value_string.c_str(), XML_ENCODING );
        xmlTextWriterWriteString( writer, BAD_CAST tmp );
        xmlTextWriterEndElement( writer );
		free( tmp );
    }

    /* traverse children */
	const node_map &children = node.get_children();
	for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
	{
		ntg_save_node_tree( *i->second, writer);
	}

    xmlTextWriterEndElement(writer);
    return NTG_NO_ERROR;
}


error_code ntg_save_nodes( const CNode &node, unsigned char **buffer, unsigned int *buffer_length )
{
    xmlTextWriterPtr writer;
	xmlBufferPtr write_buffer;
    int rc;

	assert( buffer && buffer_length );

	xmlInitParser();

	xmlSetBufferAllocationScheme( XML_BUFFER_ALLOC_DOUBLEIT );
	write_buffer = xmlBufferCreate();
    if( !write_buffer ) 
	{
		NTG_TRACE_ERROR( "error creating xml write buffer" );
        return NTG_FAILED;
    }

    writer = xmlNewTextWriterMemory( write_buffer, 0 );

    if( writer == NULL ) 
	{
        NTG_TRACE_ERROR("Error creating the xml writer");
        return NTG_FAILED;
    }

    xmlTextWriterSetIndent( writer, true );
    rc = xmlTextWriterStartDocument( writer, NULL, XML_ENCODING, NULL );
    if (rc < 0) 
	{
        NTG_TRACE_ERROR("Error at xmlTextWriterStartDocument");
        return NTG_FAILED;
    }

    /* write header */
    xmlTextWriterStartElement(writer, BAD_CAST NTG_STR_INTEGRA_COLLECTION );
    xmlTextWriterWriteAttribute(writer, BAD_CAST "xmlns:xsi", BAD_CAST "http://www.w3.org/2001/XMLSchema-node");

	string version_string = ntg_version();
	xmlTextWriterWriteFormatAttribute(writer, BAD_CAST NTG_STR_INTEGRA_VERSION, "%s", version_string.c_str() );

    if( ntg_save_node_tree( node, writer ) != NTG_NO_ERROR )
	{
		NTG_TRACE_ERROR( "Failed to save node" );
        return NTG_FAILED;
	}

    /* we don't strictly need this as xmlTextWriterEndDocument() tidies up */
    xmlTextWriterEndElement(writer);
    rc = xmlTextWriterEndDocument(writer);

    if (rc < 0) 
	{
        NTG_TRACE_ERROR("Error at xmlTextWriterEndDocument");
        return NTG_FAILED;
    }
    xmlFreeTextWriter(writer);

	*buffer = new unsigned char[ write_buffer->use ];
	memcpy( *buffer, write_buffer->content, write_buffer->use );
	*buffer_length = write_buffer->use;
	xmlBufferFree( write_buffer );

    return NTG_NO_ERROR;
}


const ntg_interface *ntg_find_interface( xmlTextReaderPtr reader, const CModuleManager &module_manager )
{
	/*
	 this method needs to deal with various permutations, due to the need to load modules by module id, origin id, and 
	 various old versions of integra files.

	 it's logic is as follows:

	 if element has a NTG_STR_MODULEID attribute, interpret this as the interface's module guid
	 
	 if element has a NTG_STR_ORIGINID attribute, interpret this as the interface's origin guid
	 else if element has a NTG_STR_INSTANCEID attribute, interpret this as the interface's origin guid
	 else if element has a NTG_STR_CLASSID attribute, interpret this attribute as a legacy numerical class id, from which 
										we can lookup the module's origin id using the ntg_interpret_legacy_module_id

	 if we have a module guid, and can find a matching module, use this module

	 else
		lookup the module using the origin guid
	*/

	GUID module_guid;
	GUID origin_guid;
	char *valuestr = NULL;
	const ntg_interface *interface = NULL;

	assert( reader );

	ntg_guid_set_null( &module_guid );
	ntg_guid_set_null( &origin_guid );

	valuestr = (char *)xmlTextReaderGetAttribute(reader, BAD_CAST NTG_STR_MODULEID );
	if( valuestr )
	{
		ntg_string_to_guid( valuestr, &module_guid );
        xmlFree( valuestr );
	}

	valuestr = (char *)xmlTextReaderGetAttribute(reader, BAD_CAST NTG_STR_ORIGINID );
	if( valuestr )
	{
		ntg_string_to_guid( valuestr, &origin_guid );
        xmlFree( valuestr );
	}
	else
	{
		valuestr = (char *)xmlTextReaderGetAttribute(reader, BAD_CAST NTG_STR_INSTANCEID );
		if( valuestr )
		{
			ntg_string_to_guid( valuestr, &origin_guid );
			xmlFree( valuestr );
		}
		else
		{
		    valuestr = (char *) xmlTextReaderGetAttribute(reader, BAD_CAST NTG_STR_CLASSID );
			if( valuestr )
			{
				if( module_manager.interpret_legacy_module_id( atoi( valuestr ), origin_guid ) != NTG_NO_ERROR )
				{
					NTG_TRACE_ERROR_WITH_STRING( "Failed to interpret legacy class id", valuestr );
				}

				xmlFree( valuestr );
			}
		}
	}

	if( !ntg_guid_is_null( &module_guid ) )
	{
		interface = module_manager.get_interface_by_module_id( module_guid );
		if( interface )
		{
			return interface;
		}
	}

	if( !ntg_guid_is_null( &origin_guid ) )
	{
		interface = module_manager.get_interface_by_origin_id( origin_guid );
		return interface;
	}

	return NULL;
}


bool ntg_is_saved_version_newer_than_current( const string &saved_version )
{
	string current_version = ntg_version();

	size_t last_dot_in_saved_version = saved_version.find_last_of( '.' );
	size_t last_dot_in_current_version = current_version.find_last_of( '.' );

	if( last_dot_in_saved_version == string::npos )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Can't parse version string", saved_version.c_str() );
		return false;
	}

	if( last_dot_in_current_version == string::npos )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Can't parse version string", current_version.c_str() );
		return false;
	}

	string saved_build_number = saved_version.substr( last_dot_in_saved_version + 1 );
	string current_build_number = current_version.substr( last_dot_in_current_version + 1 );

	return ( atoi( saved_build_number.c_str() ) > atoi( current_build_number.c_str() ) );
}


error_code ntg_load_nodes( const CNode *node, xmlTextReaderPtr reader, node_list &loaded_nodes )
{
    xmlNodePtr          xml_node;
    xmlChar             *name;
    const xmlChar       *element;
    xmlChar             *content = NULL;
    unsigned int        depth;
    unsigned int        type;
    unsigned int        prev_depth;
    int                 rv;
	const ntg_interface *interface;
	char				*saved_version;
	bool				saved_version_is_more_recent;
	const CNode *		parent = NULL;

    prev_depth      = 0;
    rv              = xmlTextReaderRead(reader);
	
	value_map loaded_values;

    if (!rv) 
	{
        return NTG_ERROR;
    }

    NTG_TRACE_VERBOSE("loading... ");
    while( rv == 1 ) 
	{
        element = xmlTextReaderConstName(reader);
        depth = xmlTextReaderDepth(reader);
        type = xmlTextReaderNodeType(reader);

		if( strncmp( (char *) element, NTG_STR_INTEGRA_COLLECTION, strlen( NTG_STR_INTEGRA_COLLECTION ) ) == 0 )
		{
			saved_version = ( char * ) xmlTextReaderGetAttribute( reader, BAD_CAST NTG_STR_INTEGRA_VERSION );
			if( saved_version )
			{
				saved_version_is_more_recent = ntg_is_saved_version_newer_than_current( saved_version );
				xmlFree( saved_version );
				if( saved_version_is_more_recent )
				{
					return NTG_FILE_MORE_RECENT_ERROR;
				}
			}
		}

        if (!strncmp((char *)element, NTG_STR_OBJECT, strlen(NTG_STR_OBJECT))) 
		{
            if (depth > prev_depth) {
                /* step down the node graph */
                parent = node;
            } else if (depth < prev_depth) {
                /* step back up the node graph */
				assert( node->get_parent() );
                node = node->get_parent();
                parent = node->get_parent();
            } else {
                /* nesting level hasn't changed since last object */
                parent = node->get_parent();
            }

            if (type == XML_READER_TYPE_ELEMENT) 
			{
				interface = ntg_find_interface( reader, server_->get_module_manager() );
				if( interface )
				{
					name = xmlTextReaderGetAttribute(reader, BAD_CAST NTG_STR_NAME);

					CPath empty_path;
					const CPath &parent_path = parent ? parent->get_path() : empty_path;
					/* add the new node */
					node = (CNode *)
						ntg_new_( *server_, NTG_SOURCE_LOAD, &interface->module_guid, (char * ) name, parent_path ).data;

					xmlFree(name);

					loaded_nodes.push_back( node );
				}
				else
				{
					NTG_TRACE_ERROR( "Can't find interface - skipping element" );
				}
            }

            prev_depth = depth;
        }

        if(!strncmp( (char * ) element, NTG_STR_ATTRIBUTE, strlen( NTG_STR_ATTRIBUTE ) ) ) 
		{
            if (type == XML_READER_TYPE_ELEMENT) 
			{
                xml_node = xmlTextReaderExpand(reader);
                content = xmlNodeGetContent(xml_node);
                name = xmlTextReaderGetAttribute(reader, BAD_CAST NTG_STR_NAME);
                char *type_code_string = (char *)xmlTextReaderGetAttribute( reader, BAD_CAST NTG_STR_TYPECODE );
                int type_code = atoi( type_code_string );
                xmlFree( type_code_string );

				CValue *value = CValue::factory( CValue::ixd_code_to_type( type_code ) );
				assert( value );

				if( content )
				{
					value->set_from_string( ( char * ) content );
                    xmlFree( content );
					content = NULL;
				}

				const CNodeEndpoint *existing_node_endpoint = node->get_node_endpoint( ( char * ) name );
				if( existing_node_endpoint && ntg_endpoint_should_load_from_ixd( existing_node_endpoint->get_endpoint(), value->get_type() ) )
				{
					/* 
					only store attribute if it exists and is of reasonable type 
					(could've been removed or changed from interface since ixd was written) 
					*/

					CPath path( node->get_path() );
					path.append_element( existing_node_endpoint->get_endpoint()->name );

					loaded_values[ path.get_string() ] = value;
				}
				else
				{
	                delete value;
				}

                xmlFree( name );
            }
        }

        rv = xmlTextReaderRead(reader);
    }

	NTG_TRACE_VERBOSE( "done!" );

    NTG_TRACE_VERBOSE( "Setting values..." );

	for( value_map::iterator value_iterator = loaded_values.begin(); value_iterator != loaded_values.end(); value_iterator++ )
	{
		CPath path( value_iterator->first );
		ntg_set_( *server_, NTG_SOURCE_LOAD, path, value_iterator->second );
		delete value_iterator->second;
	}

    NTG_TRACE_VERBOSE("done!");

    return NTG_NO_ERROR;
}


error_code ntg_send_loaded_values_to_host( const CNode &node, ntg_bridge_interface *bridge )
{
	const ntg_interface *interface = node.get_interface();

	if( !ntg_interface_has_implementation( interface ) )
	{
		return NTG_NO_ERROR;
	}

	for( const ntg_endpoint *endpoint = interface->endpoint_list; endpoint; endpoint = endpoint->next )
	{
		if( !ntg_endpoint_should_send_to_host( endpoint ) || endpoint->control_info->type != NTG_STATE )
		{
			continue;
		}

		const CNodeEndpoint *node_endpoint = node.get_node_endpoint( endpoint->name );
		assert( node_endpoint );

		bridge->send_value( node_endpoint );
	}

	return NTG_NO_ERROR;
}


command_status ntg_file_load( const char *filename, const CNode *parent, CModuleManager &module_manager )
{
    command_status command_status;
	unsigned char *ixd_buffer = NULL;
	bool is_zip_file;
	unsigned int ixd_buffer_length;
    xmlTextReaderPtr reader = NULL;
	node_list new_nodes;
	node_list::const_iterator new_node_iterator;

	NTG_COMMAND_STATUS_INIT;

    LIBXML_TEST_VERSION;

	guid_set *new_embedded_modules = new guid_set;
	command_status.error_code = module_manager.load_from_integra_file( filename, *new_embedded_modules );
	if( command_status.error_code != NTG_NO_ERROR ) 
	{
		NTG_TRACE_ERROR_WITH_STRING("couldn't load modules", filename );
		goto CLEANUP;
	}

	/* pull ixd data out of file */
	command_status.error_code = ntg_load_ixd_buffer( filename, &ixd_buffer, &ixd_buffer_length, &is_zip_file );
	if( command_status.error_code != NTG_NO_ERROR ) 
	{
		NTG_TRACE_ERROR_WITH_STRING("couldn't load ixd", filename);
		goto CLEANUP;
	}

	xmlInitParser();

    /* validate candidate IXD file against schema */
    command_status.error_code = ntg_xml_validate( (char *)ixd_buffer, ixd_buffer_length );
    if( command_status.error_code != NTG_NO_ERROR ) 
	{
		NTG_TRACE_ERROR_WITH_STRING( "ixd validation failed", filename );
		goto CLEANUP;
    }

	/* create ixd reader */
	reader = xmlReaderForMemory( (char *)ixd_buffer, ixd_buffer_length, NULL, NULL, 0 );
    if( reader == NULL )
	{
		NTG_TRACE_ERROR_WITH_STRING("unable to read ixd", filename );
		command_status.error_code = NTG_FAILED;
		goto CLEANUP;
	}

    /* stop DSP in the host */
	server_->get_bridge()->host_dsp( 0 );

    /* actually load the data */
    command_status.error_code = ntg_load_nodes( parent, reader, new_nodes );
	if( command_status.error_code != NTG_NO_ERROR )
	{
		NTG_TRACE_ERROR_WITH_STRING( "failed to load nodes", filename );
		goto CLEANUP;
	}

	/* load the data directories */
	if( is_zip_file )
	{
		if( CDataDirectory::extract_from_zip( filename, parent ) != NTG_NO_ERROR )
		{
			NTG_TRACE_ERROR_WITH_STRING( "failed to load data directories", filename );
		}
	}

	/* send the loaded attributes to the host */
	for( new_node_iterator = new_nodes.begin(); new_node_iterator != new_nodes.end(); new_node_iterator++ )
	{
		if( ntg_send_loaded_values_to_host( **new_node_iterator, server_->get_bridge() ) != NTG_NO_ERROR)
		{
			NTG_TRACE_ERROR_WITH_STRING( "failed to send loaded attributes to host", filename );
			continue;
		}
	}

	/* rename top-level node to filename */
	if( !new_nodes.empty() )
	{
		string top_level_node_name = ntg_get_top_level_node_name( filename );
		const CNode *top_level_node = *new_nodes.begin();

		if( top_level_node->get_name() != top_level_node_name )
		{
			ntg_rename_( *server_, NTG_SOURCE_SYSTEM, top_level_node->get_path(), top_level_node_name.c_str() );
		}
	}


CLEANUP:

	if( reader )
	{
		xmlFreeTextReader( reader );
	}

	if( ixd_buffer )
	{
		delete[] ixd_buffer;
	}

	if( command_status.error_code == NTG_NO_ERROR )
	{
		command_status.data = new_embedded_modules;
	}
	else
	{
		/* load failed - unload modules */
		if( new_embedded_modules )
		{
			module_manager.unload_modules( *new_embedded_modules );
			delete new_embedded_modules;
		}
	}

	/* restart DSP in the host */
	server_->get_bridge()->host_dsp( 1 );

	return command_status;
}


error_code ntg_file_save( const char *filename, const CNode &node, const CModuleManager &module_manager )
{
	zipFile zip_file;
	zip_fileinfo zip_file_info;
	unsigned char *ixd_buffer;
	unsigned int ixd_buffer_length;

	assert( filename );

	zip_file = zipOpen( filename, APPEND_STATUS_CREATE );
	if( !zip_file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Failed to create zipfile", filename );
		return NTG_FAILED;
	}

	if( ntg_save_nodes( node, &ixd_buffer, &ixd_buffer_length ) != NTG_NO_ERROR )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Failed to save node tree", filename );
		return NTG_FAILED;
	}

	ntg_init_zip_file_info( &zip_file_info );

	zipOpenNewFileInZip( zip_file, NTG_INTERNAL_IXD_FILE_NAME, &zip_file_info, NULL, 0, NULL, 0, NULL, Z_DEFLATED, Z_DEFAULT_COMPRESSION );
	zipWriteInFileInZip( zip_file, ixd_buffer, ixd_buffer_length );
	zipCloseFileInZip( zip_file );

	delete[] ixd_buffer;

	CDataDirectory::copy_to_zip( zip_file, node, node.get_parent_path() );

	ntg_copy_node_modules_to_zip( zip_file, node, module_manager );

	zipClose( zip_file, NULL );

	return NTG_NO_ERROR;
}


