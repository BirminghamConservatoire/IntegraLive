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
#ifdef _WINDOWS
#include <direct.h>
#else
#include <sys/stat.h>
#define _S_IFMT S_IFMT
#define mkdir(x) mkdir(x, 0777)
#endif
#include <dirent.h>
#include <math.h>

#include "../externals/minizip/zip.h"
#include "../externals/minizip/unzip.h"

#include "data_directory.h"
#include "scratch_directory.h"
#include "file_io.h"
#include "helper.h"
#include "globals.h"
#include "system_class_handlers.h"


#define NTG_NODE_DIRECTORY "node_data"

#define NTG_DATA_COPY_BUFFER_SIZE 16384


char *ntg_make_up_node_data_directory_name( const ntg_node *node, const ntg_server *server )
{
	char *node_directory_name;
	int id_length, node_directory_length;

	id_length = (int) log10( node->id ) + 1;

	node_directory_length = strlen( server->scratch_directory_root ) + 
							strlen( NTG_NODE_DIRECTORY ) + 
							id_length + 
							strlen( NTG_PATH_SEPARATOR ) + 2;

	node_directory_name = ntg_malloc( node_directory_length );
	sprintf( node_directory_name, "%s%s_%lu%s", server->scratch_directory_root, NTG_NODE_DIRECTORY, node->id, NTG_PATH_SEPARATOR );

	return node_directory_name;
}


char *ntg_node_data_directory_create( const ntg_node *node, const ntg_server *server )
{
	char *node_directory_name = ntg_make_up_node_data_directory_name( node, server );

	mkdir( node_directory_name );

	return node_directory_name;
}


void ntg_node_data_directory_change( const char *previous_directory_name, const char *new_directory_name )
{
	assert( previous_directory_name && new_directory_name );

	ntg_delete_directory( previous_directory_name );

	mkdir( new_directory_name );
}


const char *ntg_get_relative_node_path( const ntg_node *node, const ntg_node *root ) 
{
	int node_path_length, root_path_length;
	const char *relative_node_path;

	assert( node && root );

	node_path_length = strlen( node->path->string );
	root_path_length = strlen( root->path->string );

	if( node_path_length <= root_path_length || memcmp( node->path->string, root->path->string, root_path_length ) != 0 )
	{
		NTG_TRACE_ERROR( "node is not a descendant of root" );
		return NULL;
	}

	relative_node_path = node->path->string + root_path_length;

	if( ntg_node_get_root( root ) != root )
	{
		/* if root is not the root of the entire tree */
		
		assert( *relative_node_path == '.' );
		relative_node_path++;	/* skip dot after root path */
	}

	return relative_node_path;
}


void ntg_copy_node_data_directories_to_zip( zipFile zip_file, const ntg_node *node, const ntg_node *path_root )
{
	const char *data_directory_name;
	const char *relative_node_path;
	char *target_path;
	const ntg_node *child_node;

	assert( zip_file && node && path_root );

	if( ntg_node_has_data_directory( node ) )
	{
		relative_node_path = ntg_get_relative_node_path( node, path_root );

		if( relative_node_path )
		{
			target_path = malloc( strlen( NTG_NODE_DIRECTORY ) + strlen( NTG_PATH_SEPARATOR ) + strlen( relative_node_path ) + 1 );
			sprintf( target_path, "%s%s%s", NTG_NODE_DIRECTORY, NTG_PATH_SEPARATOR, relative_node_path );
			
			data_directory_name = ntg_node_get_data_directory( node );
			if( data_directory_name )
			{
				ntg_copy_directory_contents_to_zip( zip_file, target_path, data_directory_name );
			}
			else
			{
				NTG_TRACE_ERROR_WITH_STRING( "Couldn't get data directory name", node->path->string );
			}

			ntg_free( target_path );
		}
		else
		{
			NTG_TRACE_ERROR_WITH_STRING( "Couldn't build relative node path to", node->path->string );
		}
	}

	/* walk tree of child nodes */
	child_node = node->nodes;
	if( child_node )
	{
		do
		{
			ntg_copy_node_data_directories_to_zip( zip_file, child_node, path_root );

			child_node = child_node->next;
		}
		while( child_node != node->nodes );
	}
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


void ntg_extract_to_data_directory( unzFile unzip_file, unz_file_info *file_info, const ntg_node *node, const char *relative_file_path )
{
	const char *data_directory;
	char *target_path;
	FILE *output_file;
	unsigned char *output_buffer;
	int bytes_read, total_bytes_read, bytes_remaining;

	assert( unzip_file && file_info && node && relative_file_path );

	data_directory = ntg_node_get_data_directory( node );
	assert( data_directory );

	ntg_construct_subdirectories( data_directory, relative_file_path );

	target_path = ntg_malloc( strlen( data_directory ) + strlen( relative_file_path ) + 1 );
	sprintf( target_path, "%s%s", data_directory, relative_file_path );

	output_file = fopen( target_path, "wb" );
	if( !output_file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Couldn't write to data directory", target_path );
		ntg_free( target_path );
		return;
	}

	ntg_free( target_path );

	output_buffer = ntg_malloc( NTG_DATA_COPY_BUFFER_SIZE );

	total_bytes_read = 0;
	while( total_bytes_read < file_info->uncompressed_size )
	{
		bytes_remaining = file_info->uncompressed_size - total_bytes_read;
		assert( bytes_remaining > 0 );

		bytes_read = unzReadCurrentFile( unzip_file, output_buffer, MIN( NTG_DATA_COPY_BUFFER_SIZE, bytes_remaining ) );
		if( bytes_read <= 0 )
		{
			NTG_TRACE_ERROR( "Error decompressing file" );
			break;
		}

		fwrite( output_buffer, 1, bytes_read, output_file );

		total_bytes_read += bytes_read;
	}

	ntg_free( output_buffer );

	fclose( output_file );
}


bool ntg_does_zip_contain_directory( unzFile unzip_file, const char *directory )
{
	int directory_length;
	unz_file_info file_info;
	char file_name[ NTG_LONG_STRLEN ];

	assert( unzip_file && directory );

	directory_length = strlen( directory );

	if( unzGoToFirstFile( unzip_file ) != UNZ_OK )
	{
		NTG_TRACE_ERROR( "Couldn't iterate contents" );
		return false;
	}

	do
	{
		if( unzGetCurrentFileInfo( unzip_file, &file_info, file_name, NTG_LONG_STRLEN, NULL, 0, NULL, 0 ) != UNZ_OK )
		{
			NTG_TRACE_ERROR( "Couldn't extract file info" );
			continue;
		}

		if( strlen( file_name ) >= directory_length && memcmp( file_name, directory, directory_length ) == 0 )
		{
			return true;
		}
	}
	while( unzGoToNextFile( unzip_file ) != UNZ_END_OF_LIST_OF_FILE );

	return false;
}


const char *ntg_get_node_directory_path( unzFile unzip_file )
{
	/* 
	 This method is needed because old versions of integra live stored directly in integra_data, instead 
	 of integra_data/node_data.
	*/

	const char *normal_node_directory_path = NTG_INTEGRA_DATA_DIRECTORY_NAME NTG_NODE_DIRECTORY NTG_PATH_SEPARATOR;
	const char *old_node_directory_path = NTG_INTEGRA_DATA_DIRECTORY_NAME;

	assert( unzip_file );

	if( ntg_does_zip_contain_directory( unzip_file, normal_node_directory_path ) )
	{
		return normal_node_directory_path;
	}

	if( ntg_does_zip_contain_directory( unzip_file, NTG_INTEGRA_IMPLEMENTATION_DIRECTORY_NAME ) )
	{
		return normal_node_directory_path;
	}

	return old_node_directory_path;
}


ntg_error_code ntg_load_data_directories( const char *file_path, ntg_node *parent_node )
{
	unzFile unzip_file;
	unz_file_info file_info;
	char file_name[ NTG_LONG_STRLEN ];
	const char *node_directory;
	char *relative_node_path_string;
	ntg_path *relative_node_path;
	const char *relative_file_path;
	ntg_node *node;
	int node_directory_length;

	assert( file_path && parent_node );

	unzip_file = unzOpen( file_path );
	if( !unzip_file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Couldn't open zip file", file_path );
		return NTG_FAILED;
	}

	node_directory = ntg_get_node_directory_path( unzip_file );

	node_directory_length = strlen( node_directory );

	if( unzGoToFirstFile( unzip_file ) != UNZ_OK )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Couldn't iterate contents", file_path );
		unzClose( unzip_file );
		return NTG_FAILED;
	}

	do
	{
		if( unzGetCurrentFileInfo( unzip_file, &file_info, file_name, NTG_LONG_STRLEN, NULL, 0, NULL, 0 ) != UNZ_OK )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Couldn't extract file info", file_path );
			continue;
		}

		if( strlen( file_name ) <= node_directory_length || memcmp( file_name, node_directory, node_directory_length ) != 0 )
		{
			/* skip file not in node directory */
			continue;
		}

		relative_node_path_string = ntg_extract_first_directory( file_name + node_directory_length );
		if( !relative_node_path_string )
		{
			NTG_TRACE_ERROR_WITH_STRING( "unexpected content - no relative path", file_name );
			continue;
		}

		relative_node_path = ntg_path_from_string( relative_node_path_string );
		node = ntg_node_find_by_path( relative_node_path, parent_node );
		ntg_path_free( relative_node_path );

		if( !node )
		{
			NTG_TRACE_ERROR_WITH_STRING( "couldn't resolve path", relative_node_path_string );
			ntg_free( relative_node_path_string );
			continue;
		}

		if( !ntg_node_has_data_directory( node ) )
		{
			NTG_TRACE_ERROR_WITH_STRING( "found data file for node which shouldn't have data directory", file_name );
			ntg_free( relative_node_path_string );
			continue;
		}

		relative_file_path = file_name + node_directory_length + strlen( relative_node_path_string ) + 1;
		ntg_free( relative_node_path_string );

		if( unzOpenCurrentFile( unzip_file ) == UNZ_OK )
		{
			ntg_extract_to_data_directory( unzip_file, &file_info, node, relative_file_path );

			unzCloseCurrentFile( unzip_file );
		}
		else
		{
			NTG_TRACE_ERROR_WITH_STRING( "couldn't open zip contents", file_name );
		}
	}
	while( unzGoToNextFile( unzip_file ) != UNZ_END_OF_LIST_OF_FILE );

	unzClose( unzip_file );

	return NTG_NO_ERROR;
}


const char *ntg_extract_filename_from_path( const char *path )
{
	int i;

	assert( path );

	for( i = strlen( path ) - 1; i >= 0; i-- )
	{
		switch( path[ i ] )
		{
			case '/':
			case '\\':
				return path + i + 1;
		}
	}

	return NULL;
}


const char *ntg_copy_file_to_data_directory( const ntg_node_attribute *attribute )
{
	const char *data_directory = NULL;
	const char *input_path = NULL;
	const char *copied_file = NULL;
	char *output_filename = NULL;
	
	assert( attribute );

	data_directory = ntg_node_get_data_directory( attribute->node );
	if( !data_directory )
	{
		NTG_TRACE_ERROR_WITH_STRING( "can't get data directory for node", attribute->node->name );
		return NULL;
	}

	input_path = ntg_value_get_string( attribute->value );
	copied_file = ntg_extract_filename_from_path( input_path );
	if( !copied_file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "can't extract filename from path", input_path );
		return NULL;
	}

	output_filename = ntg_strdup( data_directory );
	output_filename = ntg_string_append( output_filename, copied_file );

	ntg_copy_file( input_path, output_filename );

	ntg_free( output_filename );

	return copied_file;
}
