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


#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "platform_specifics.h"

#include <assert.h>
#include <dirent.h>
#include <sys/stat.h>

#include <libxml/xmlreader.h>

#include "../externals/minizip/zip.h"
#include "../externals/minizip/unzip.h"

#include "file_io.h"
#include "globals.h"
#include "helper.h"
#include "list.h"
#include "data_directory.h"
#include "module_manager.h"
#include "interface.h"
#include "validate.h"
#include "node_list.h"

#ifndef _WINDOWS
#define _S_IFMT S_IFMT
#endif


#define NTG_DATA_COPY_BUFFER_SIZE 16384


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


ntg_error_code ntg_delete_file( const char *file_name )
{
	if( remove( file_name ) != 0 )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Failed to remove file", file_name );
		return NTG_FAILED;
	}

	return NTG_NO_ERROR;
}


ntg_error_code ntg_copy_file( const char *source_path, const char *target_path )
{
	FILE *source_file = NULL;
	FILE *target_file = NULL;
	unsigned char *copy_buffer = NULL;
	unsigned long bytes_to_copy = 0;
	unsigned long bytes_read = 0;
	ntg_error_code error_code = NTG_FAILED;

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

	copy_buffer = ntg_malloc( NTG_DATA_COPY_BUFFER_SIZE );

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

	if( copy_buffer )	ntg_free( copy_buffer );
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

	buffer = ntg_malloc( NTG_DATA_COPY_BUFFER_SIZE );

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

	ntg_free( buffer );

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
			ntg_free( full_source_path );
			continue;
		}

		full_target_path = ntg_malloc( strlen( NTG_INTEGRA_DATA_DIRECTORY_NAME ) + strlen( target_path ) + strlen( NTG_PATH_SEPARATOR ) + strlen( file_name ) + 1 );
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

		ntg_free( full_target_path );
		ntg_free( full_source_path );
	}
	while( directory_entry != NULL );
}


void ntg_find_module_guids_to_embed( ntg_list *module_guids_to_embed, const ntg_node *node )
{
	int i;
	bool already_found;
	GUID *guids;
	const ntg_node *child_iterator;

	assert( module_guids_to_embed && node );

	if( ntg_interface_should_embed_module( node->interface ) )
	{
		already_found = false;
		guids = ( GUID * ) module_guids_to_embed->elems;

		for( i = 0; i < module_guids_to_embed->n_elems; i++ )
		{
			if( ntg_guids_are_equal( &guids[ i ], &node->interface->module_guid ) )
			{
				already_found = true;
				break;
			}
		}

		if( !already_found )
		{
			module_guids_to_embed->n_elems++;
			guids = ntg_realloc( module_guids_to_embed->elems, module_guids_to_embed->n_elems * sizeof( GUID ) );
			guids[ module_guids_to_embed->n_elems - 1 ] = node->interface->module_guid;
			module_guids_to_embed->elems = guids;
		}
	}

	/* walk subtree */
    child_iterator = node->nodes;
	if( child_iterator )
	{
		do 
		{
			ntg_find_module_guids_to_embed( module_guids_to_embed, child_iterator );
			child_iterator = child_iterator->next;

		} 
		while (child_iterator != node->nodes);
	}
}


void ntg_copy_node_modules_to_zip( zipFile zip_file, const ntg_node *node, const ntg_module_manager *module_manager )
{
	ntg_list *module_guids_to_embed;
	int i;
	const GUID *guids;
	const ntg_interface *interface;
	char *unique_interface_name;
	char *target_path;

	assert( zip_file && node );

	module_guids_to_embed = ntg_list_new( NTG_LIST_GUIDS );

	ntg_find_module_guids_to_embed( module_guids_to_embed, node );
	guids = (const GUID *) module_guids_to_embed->elems;

	for( i = 0; i < module_guids_to_embed->n_elems; i++ )
	{
		interface = ntg_get_interface_by_module_id( module_manager, &guids[ i ] );
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

		unique_interface_name = ntg_module_manager_get_unique_interface_name( interface );

		target_path = ntg_malloc( strlen( NTG_INTEGRA_IMPLEMENTATION_DIRECTORY_NAME ) + strlen( unique_interface_name ) + strlen( NTG_MODULE_SUFFIX ) + 2 );
		sprintf( target_path, "%s%s.%s", NTG_INTEGRA_IMPLEMENTATION_DIRECTORY_NAME, unique_interface_name, NTG_MODULE_SUFFIX );

		ntg_copy_file_to_zip( zip_file, target_path, interface->file_path );

		ntg_free( target_path );
		ntg_free( unique_interface_name );
	}

	ntg_list_free( module_guids_to_embed );
}


ntg_error_code ntg_load_ixd_buffer_directly( const char *file_path, unsigned char **ixd_buffer, unsigned int *ixd_buffer_length )
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

	*ixd_buffer = ntg_malloc( *ixd_buffer_length );
	bytes_loaded = fread( *ixd_buffer, 1, *ixd_buffer_length, file );
	fclose( file );

	if( bytes_loaded != *ixd_buffer_length )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Error reading from file", file_path );
		return NTG_FAILED;
	}

	return NTG_NO_ERROR;
}


ntg_error_code ntg_load_ixd_buffer( const char *file_path, unsigned char **ixd_buffer, unsigned int *ixd_buffer_length, bool *is_zip_file )
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
	*ixd_buffer = ntg_malloc( *ixd_buffer_length );

	if( unzReadCurrentFile( unzip_file, *ixd_buffer, *ixd_buffer_length ) != *ixd_buffer_length )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Unable to read " NTG_INTERNAL_IXD_FILE_NAME, file_path );
		unzClose( unzip_file );
		ntg_free( *ixd_buffer );
		return NTG_FAILED;
	}

	unzClose( unzip_file );

	return NTG_NO_ERROR;
}


ntg_command_status ntg_file_load( const char *filename, const ntg_node *parent, ntg_module_manager *module_manager )
{
    ntg_command_status command_status;
	unsigned char *ixd_buffer = NULL;
	bool is_zip_file;
	unsigned int ixd_buffer_length;
    xmlTextReaderPtr reader = NULL;
	ntg_node_list *new_nodes_list = NULL;
	ntg_node_list *new_node_iterator = NULL;
	ntg_list *loaded_module_ids = NULL;

	NTG_COMMAND_STATUS_INIT;

    LIBXML_TEST_VERSION;

    server_->loading = true;

	loaded_module_ids = ntg_module_manager_load_from_integra_file( module_manager, filename );


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
    ntg_server_set_host_dsp( server_, 0);

    /* actually load the data */
    command_status.error_code = ntg_node_load( parent, reader, &new_nodes_list );
	if( command_status.error_code != NTG_NO_ERROR )
	{
		NTG_TRACE_ERROR_WITH_STRING( "failed to load nodes", filename );
		goto CLEANUP;
	}

	/* load the data directories */
	if( is_zip_file )
	{
		if( ntg_load_data_directories( filename, parent ) != NTG_NO_ERROR )
		{
			NTG_TRACE_ERROR_WITH_STRING( "failed to load data directories", filename );
		}
	}

	/* send the loaded attributes to the host */
	for( new_node_iterator = new_nodes_list; new_node_iterator; new_node_iterator = new_node_iterator->next )
	{
		if( ntg_node_send_loaded_attributes_to_host( new_node_iterator->node, server_->bridge ) != NTG_NO_ERROR)
		{
			NTG_TRACE_ERROR_WITH_STRING( "failed to send loaded attributes to host", filename );
			continue;
		}
	}

CLEANUP:

	if( reader )
	{
		xmlFreeTextReader( reader );
	}

	if( ixd_buffer )
	{
		ntg_free( ixd_buffer );
	}

	ntg_node_list_free( new_nodes_list );

	if( command_status.error_code == NTG_NO_ERROR )
	{
		command_status.data = loaded_module_ids;
	}
	else
	{
		/* load failed - unload modules */
		if( loaded_module_ids )
		{
			ntg_module_manager_unload_modules( module_manager, loaded_module_ids );
			ntg_list_free( loaded_module_ids );
		}
	}

	/* restart DSP in the host */
    ntg_server_set_host_dsp(server_, 1);

    server_->loading = false;

	return command_status;
}


ntg_error_code ntg_file_save( const char *filename, const ntg_node *node, const ntg_module_manager *module_manager )
{
	zipFile zip_file;
	zip_fileinfo zip_file_info;
	unsigned char *ixd_buffer;
	unsigned int ixd_buffer_length;

	assert( filename && node );

	zip_file = zipOpen( filename, APPEND_STATUS_CREATE );
	if( !zip_file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Failed to create zipfile", filename );
		return NTG_FAILED;
	}

	if( ntg_node_save( node, &ixd_buffer, &ixd_buffer_length ) != NTG_NO_ERROR )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Failed to save node tree", filename );
		return NTG_FAILED;
	}

	ntg_init_zip_file_info( &zip_file_info );

	zipOpenNewFileInZip( zip_file, NTG_INTERNAL_IXD_FILE_NAME, &zip_file_info, NULL, 0, NULL, 0, NULL, Z_DEFLATED, Z_DEFAULT_COMPRESSION );
	zipWriteInFileInZip( zip_file, ixd_buffer, ixd_buffer_length );
	zipCloseFileInZip( zip_file );

	ntg_free( ixd_buffer );

	ntg_copy_node_data_directories_to_zip( zip_file, node, node->parent );

	ntg_copy_node_modules_to_zip( zip_file, node, module_manager );

	zipClose( zip_file, NULL );

	return NTG_NO_ERROR;
}


