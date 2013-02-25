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

#ifdef _WINDOWS
#include <direct.h>
#else
#include <sys/stat.h>
#define _S_IFMT S_IFMT
#define mkdir(x) mkdir(x, 0777)
#endif

#include "../externals/minizip/zip.h"
#include "../externals/minizip/unzip.h"

#include "module_manager.h"
#include "scratch_directory.h"
#include "interface.h"
#include "memory.h"
#include "helper.h"
#include "list.h"
#include "globals.h"
#include "file_io.h"


/* 
 whilst dealing with zipped files, we always use linux-style path separators, 
 because windows can use the two interchangeably, 
 and PD can't cope with windows separators at all
*/

#define NTG_MODULE_INNER_DIRECTORY_NAME "integra_module_data" NTG_PATH_SEPARATOR
#define NTG_IDD_FILE_NAME NTG_MODULE_INNER_DIRECTORY_NAME "interface_definition.iid"
#define NTG_INTERNAL_IMPLEMENTATION_DIRECTORY_NAME NTG_MODULE_INNER_DIRECTORY_NAME "implementation" NTG_PATH_SEPARATOR

#define NTG_IMPLEMENTATION_DIRECTORY_NAME "implementations" NTG_PATH_SEPARATOR
#define NTG_MODULE_DIRECTORY_NAME "loaded_modules" NTG_PATH_SEPARATOR

#ifndef _WINDOWS
#include <sys/stat.h>
#define _S_IFMT S_IFMT
#endif


#define NTG_LEGACY_CLASS_ID_FILENAME "id2guid.csv"



ntg_interface *ntg_module_manager_load_interface( unzFile unzip_file )
{
	unz_file_info file_info;
	unsigned char *buffer = NULL;
	unsigned int buffer_size = 0;
	ntg_interface *interface = NULL;

	assert( unzip_file );

	if( unzLocateFile( unzip_file, NTG_IDD_FILE_NAME, 0 ) != UNZ_OK )
	{
		NTG_TRACE_ERROR( "Unable to locate " NTG_IDD_FILE_NAME );
		return NULL;
	}

	if( unzGetCurrentFileInfo( unzip_file, &file_info, NULL, 0, NULL, 0, NULL, 0 ) != UNZ_OK )
	{
		NTG_TRACE_ERROR( "Couldn't get info for " NTG_IDD_FILE_NAME );
		return NULL;
	}

	if( unzOpenCurrentFile( unzip_file ) != UNZ_OK )
	{
		NTG_TRACE_ERROR( "Unable to open " NTG_IDD_FILE_NAME );
		return NULL;
	}

	buffer_size = file_info.uncompressed_size;
	buffer = ntg_malloc( buffer_size );

	if( unzReadCurrentFile( unzip_file, buffer, buffer_size ) != buffer_size )
	{
		NTG_TRACE_ERROR( "Unable to read " NTG_IDD_FILE_NAME );
		ntg_free( buffer );
		return NULL;
	}

	interface = ntg_interface_load( buffer, buffer_size );
	ntg_free( buffer );

	return interface;
}


char *ntg_module_manager_get_unique_interface_name( const ntg_interface *interface )
{
	char *unique_name;
	char *module_guid;

	assert( interface );

	module_guid = ntg_guid_to_string( &interface->module_guid );

	unique_name = ntg_strdup( interface->info->name );
	unique_name = ntg_string_append( unique_name, "-" );
	unique_name = ntg_string_append( unique_name, module_guid );

	ntg_free( module_guid );

	return unique_name;
}


char *ntg_module_manager_get_implementation_directory_name( const ntg_interface *interface )
{
	char *directory_name;

	assert( interface );

	directory_name = ntg_module_manager_get_unique_interface_name( interface );
	directory_name = ntg_string_append( directory_name, NTG_PATH_SEPARATOR );

	return directory_name;
}


char *ntg_module_manager_get_implementation_path( const ntg_module_manager *module_manager, const ntg_interface *interface )
{
	char *implementation_path;
	char *directory_name;

	assert( module_manager && interface );

	implementation_path = ntg_strdup( module_manager->implementation_directory_root );
	directory_name = ntg_module_manager_get_implementation_directory_name( interface );

	implementation_path = ntg_string_append( implementation_path, directory_name );

	ntg_free( directory_name );

	return implementation_path;
}


char *ntg_module_manager_get_module_path( const ntg_module_manager *module_manager, const ntg_interface *interface )
{
	char *module_path;
	char *unique_name;

	assert( module_manager && interface );

	unique_name = ntg_module_manager_get_unique_interface_name( interface );

	module_path = ntg_malloc( strlen( module_manager->module_directory_root ) + strlen( unique_name ) + strlen( NTG_MODULE_SUFFIX ) + 2 );
	sprintf( module_path, "%s%s.%s", module_manager->module_directory_root, unique_name, NTG_MODULE_SUFFIX );

	ntg_free( unique_name );

	return module_path;
}


ntg_error_code ntg_module_manager_extract_implementation( ntg_module_manager *module_manager, unzFile unzip_file, const ntg_interface *interface )
{
	char *implementation_directory;
	char *target_path;
	unz_file_info file_info;
	char file_name[ NTG_LONG_STRLEN ];
	const char *relative_file_path;
	void *output_buffer;
	FILE *output_file;
	ntg_error_code result = NTG_NO_ERROR;

	assert( module_manager && unzip_file && interface );

	implementation_directory = ntg_module_manager_get_implementation_path( module_manager, interface );

	if( ntg_is_directory( implementation_directory ) )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Can't extract module implementation - target directory already exists", implementation_directory );
		result = NTG_FAILED;
		goto CLEANUP;
	}

	mkdir( implementation_directory );

	if( unzGoToFirstFile( unzip_file ) != UNZ_OK )
	{
		NTG_TRACE_ERROR( "Couldn't iterate contents" );
		result = NTG_FAILED;
		goto CLEANUP;
	}

	do
	{
		if( unzGetCurrentFileInfo( unzip_file, &file_info, file_name, NTG_LONG_STRLEN, NULL, 0, NULL, 0 ) != UNZ_OK )
		{
			NTG_TRACE_ERROR( "Couldn't extract file info" );
			result = NTG_FAILED;
			continue;
		}

		if( strlen( file_name ) <= strlen( NTG_INTERNAL_IMPLEMENTATION_DIRECTORY_NAME ) || memcmp( file_name, NTG_INTERNAL_IMPLEMENTATION_DIRECTORY_NAME, strlen( NTG_INTERNAL_IMPLEMENTATION_DIRECTORY_NAME ) ) != 0 )
		{
			/* skip files not in NTG_INTERNAL_IMPLEMENTATION_DIRECTORY_NAME */
			continue;
		}

		if( strcmp( file_name + strlen( file_name ) - 1, NTG_PATH_SEPARATOR ) == 0 )
		{
			/* skip directories */
			continue;
		}

		relative_file_path = file_name + strlen( NTG_INTERNAL_IMPLEMENTATION_DIRECTORY_NAME );

		ntg_construct_subdirectories( implementation_directory, relative_file_path );

		target_path = ntg_strdup( implementation_directory );
		target_path = ntg_string_append( target_path, relative_file_path );

		if( unzOpenCurrentFile( unzip_file ) == UNZ_OK )
		{
			output_file = fopen( target_path, "wb" );
			if( output_file )
			{
				output_buffer = ntg_malloc( file_info.uncompressed_size );

				if( unzReadCurrentFile( unzip_file, output_buffer, file_info.uncompressed_size ) != file_info.uncompressed_size )
				{
					NTG_TRACE_ERROR_WITH_STRING( "Error decompressing file", file_name );
					result = NTG_FAILED;
				}
				else
				{
					fwrite( output_buffer, 1, file_info.uncompressed_size, output_file );
				}

				ntg_free( output_buffer );

				fclose( output_file );
			}
			else
			{
				NTG_TRACE_ERROR_WITH_STRING( "Couldn't write to implementation file", target_path );
				result = NTG_FAILED;
			}

			unzCloseCurrentFile( unzip_file );
		}
		else
		{
			NTG_TRACE_ERROR_WITH_STRING( "couldn't open zip contents", file_name );
			result = NTG_FAILED;
		}

		ntg_free( target_path );
	}
	while( unzGoToNextFile( unzip_file ) != UNZ_END_OF_LIST_OF_FILE );

	CLEANUP:

	ntg_free( implementation_directory );

	return result;
}


void ntg_module_manager_delete_implementation( ntg_module_manager *module_manager, const ntg_interface *interface )
{
	char *implementation_directory;

	assert( module_manager && interface );

	implementation_directory = ntg_module_manager_get_implementation_path( module_manager, interface );

	ntg_delete_directory( implementation_directory );
}


const GUID *ntg_module_manager_load_module( ntg_module_manager *module_manager, const char *filename, ntg_module_source module_source )
{
	unzFile unzip_file;
	ntg_interface *interface = NULL;
	ntg_list *module_id_list;
	GUID *guids;
	char *stored_module_path;

	assert( module_manager && filename );

	unzip_file = unzOpen( filename );
	if( !unzip_file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Unable to open zip", filename );
		return NULL;
	}

	interface = ntg_module_manager_load_interface( unzip_file );
	if( !interface ) 
	{
		NTG_TRACE_ERROR_WITH_STRING( "Failed to load interface", filename );
		unzClose( unzip_file );
		return NULL;
	}

	if( ntg_hashtable_lookup_guid( module_manager->module_id_map, &interface->module_guid ) )
	{
		NTG_TRACE_VERBOSE_WITH_STRING( "Module already loaded", interface->info->name );
		ntg_interface_free( interface );
		unzClose( unzip_file );
		return NULL;
	}

	interface->module_source = module_source;

	ntg_hashtable_add_guid_key( module_manager->module_id_map, &interface->module_guid, interface );

	if( ntg_hashtable_lookup_guid( module_manager->origin_id_map, &interface->origin_guid ) )
	{
		NTG_TRACE_VERBOSE_WITH_STRING( "Two modules with same origin!  Leaving original in origin->interface table", interface->info->name );
	}
	else
	{
		ntg_hashtable_add_guid_key( module_manager->origin_id_map, &interface->origin_guid, interface );
	}

	if( ntg_interface_is_core( interface ) )
	{
		if( ntg_hashtable_lookup_string( module_manager->core_name_map, interface->info->name ) )
		{
			NTG_TRACE_VERBOSE_WITH_STRING( "Two core modules with same name!  Leaving original in name->interface table", interface->info->name );
		}
		else
		{
			ntg_hashtable_add_string_key( module_manager->core_name_map, interface->info->name, interface );
		}
	}
	
	module_id_list = module_manager->module_id_list;
	module_id_list->n_elems++;
	guids = ntg_realloc( module_id_list->elems, module_id_list->n_elems * sizeof( GUID ) );
	guids[ module_id_list->n_elems - 1 ] = interface->module_guid;
	module_id_list->elems = guids;

	if( ntg_interface_has_implementation( interface ) )
	{
		ntg_module_manager_extract_implementation( module_manager, unzip_file, interface );
	}

	if( ntg_interface_should_store_module( interface ) )
	{
		stored_module_path = ntg_module_manager_get_module_path( module_manager, interface );
		ntg_copy_file( filename, stored_module_path );
		ntg_free( stored_module_path );
	}

	unzClose( unzip_file );

	return &interface->module_guid;
}


void ntg_module_manager_load_legacy_module_id_file( ntg_module_manager *module_manager )
{
	char line[ NTG_LONG_STRLEN ];
	FILE *file = NULL;
	const char *guid_as_string;
	ntg_id old_id;
	GUID guid;

	assert( module_manager );

	module_manager->legacy_module_id_table = NULL;
	module_manager->legacy_module_id_table_elems = 0;

	file = fopen( NTG_LEGACY_CLASS_ID_FILENAME, "r" );
	if( !file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "failed to open legacy class id file", NTG_LEGACY_CLASS_ID_FILENAME );
		return;
	}

	while( !feof( file ) )
	{
		if( !fgets( line, NTG_LONG_STRLEN, file ) )
		{
			break;
		}

		old_id = atoi( line );
		if( old_id == 0 )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Error reading old id from legacy class id file line", line );
			continue;
		}

		guid_as_string = strchr( line, ',' );
		if( !guid_as_string )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Error reading guid from legacy class id file line", line );
			continue;
		}

		/* skip comma and space */
		guid_as_string += 2;	

		if( ntg_string_to_guid( guid_as_string, &guid ) != NTG_NO_ERROR )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Error parsing guid", guid_as_string );
			continue;
		}

		if( old_id >= module_manager->legacy_module_id_table_elems )
		{
			module_manager->legacy_module_id_table = ntg_realloc( module_manager->legacy_module_id_table, ( old_id + 1 ) * sizeof( GUID ) );
			memset( module_manager->legacy_module_id_table + module_manager->legacy_module_id_table_elems, 0, ( old_id + 1 - module_manager->legacy_module_id_table_elems ) * sizeof( GUID ) );
			module_manager->legacy_module_id_table_elems = old_id + 1;
		}

		module_manager->legacy_module_id_table[ old_id ] = guid;
	}

	fclose( file );
}


void ntg_module_manager_load_from_directory( ntg_module_manager *module_manager, const char *directory, ntg_module_source module_source )
{
	DIR *directory_stream;
	struct dirent *directory_entry;
	const char *name;
	char *full_path;
	struct stat entry_data;

	assert( module_manager && directory );

	directory_stream = opendir( directory );
	if( !directory_stream )
	{
		NTG_TRACE_ERROR_WITH_STRING( "unable to open directory", directory );
		return;
	}

	while( true )
	{
		directory_entry = readdir( directory_stream );
		if( !directory_entry )
		{
			break;
		}

		name = directory_entry->d_name;

		full_path = ntg_strdup( directory );
		full_path = ntg_string_append( full_path, NTG_PATH_SEPARATOR );
		full_path = ntg_string_append( full_path, name );

		if( stat( full_path, &entry_data ) != 0 )
		{
			NTG_TRACE_ERROR_WITH_ERRNO( "couldn't read directory entry data" );
			ntg_free( full_path );
			continue;
		}

		switch( entry_data.st_mode & _S_IFMT )
		{
			case S_IFDIR:	/* directory */
				continue;

			default:
				ntg_module_manager_load_module( module_manager, full_path, module_source );
				break;
		}

		ntg_free( full_path );
	}
	while( directory_entry != NULL );
}


void ntg_unload_module( ntg_module_manager *module_manager, ntg_interface *interface )
{
	char *stored_module_path;
	ntg_list *module_id_list;
	GUID *ids;
	int i;
	bool found;

	assert( module_manager && interface );

	if( ntg_interface_should_store_module( interface ) )
	{
		stored_module_path = ntg_module_manager_get_module_path( module_manager, interface );
		ntg_delete_file( stored_module_path );
		ntg_free( stored_module_path );
	}

	if( ntg_interface_has_implementation( interface ) )
	{
		ntg_module_manager_delete_implementation( module_manager, interface );
	}

	ntg_hashtable_remove_guid_key( module_manager->module_id_map, &interface->module_guid );

	/* only remove origin id keys if the entry points to this interface */
	if( ntg_hashtable_lookup_guid( module_manager->origin_id_map, &interface->origin_guid ) == interface )
	{
		ntg_hashtable_remove_guid_key( module_manager->origin_id_map, &interface->origin_guid );
	}

	if( ntg_interface_is_core( interface ) )
	{
		/* only remove from core name map if the entry points to this interface */
		if( ntg_hashtable_lookup_string( module_manager->core_name_map, interface->info->name ) == interface )
		{
			ntg_hashtable_remove_string_key( module_manager->core_name_map, interface->info->name );
		}
	}

	/* remove from id list */
	module_id_list = module_manager->module_id_list;
	ids = ( GUID * ) module_id_list->elems;
	found = false;

	for( i = 0; i < module_id_list->n_elems - 1; i++ )
	{
		if( !found )
		{
			if( ntg_guids_are_equal( &ids[ i ], &interface->module_guid ) )
			{
				found = true;
			}
		}

		if( found )
		{
			ids[ i ] = ids[ i + 1 ];
		}
	}

	if( !found )
	{
		NTG_TRACE_ERROR( "Failed to find guid in id list" );
	}

	ntg_interface_free( interface );
}


void ntg_free_all_modules( ntg_module_manager *module_manager )
{
	ntg_interface *interface;
	ntg_list *module_id_list;
	GUID *ids;
	const GUID *id;
	int number_of_modules;
	int i;

	assert( module_manager );

	module_id_list = module_manager->module_id_list;

	number_of_modules = module_id_list->n_elems;
	ids = ntg_malloc( sizeof( GUID ) * number_of_modules );
	memcpy( ids, module_id_list->elems, sizeof( GUID ) * number_of_modules );
		
	for( i = 0; i < number_of_modules; i++ )
	{
		id = &ids[ i ];

		interface = (ntg_interface *) ntg_get_interface_by_module_id( module_manager, id );
		assert( interface );

		ntg_unload_module( module_manager, interface );
	}

	ntg_free( ids );
}


const ntg_list *ntg_module_id_list( const ntg_module_manager *module_manager )
{
	assert( module_manager->module_id_list );

	return module_manager->module_id_list;
}


const ntg_interface *ntg_get_interface_by_module_id( const ntg_module_manager *module_manager, const GUID *module_id )
{
	assert( module_manager && module_manager->module_id_map );

	return ( const ntg_interface * ) ntg_hashtable_lookup_guid( module_manager->module_id_map, module_id );
}


const ntg_interface *ntg_get_interface_by_origin_id( const ntg_module_manager *module_manager, const GUID *origin_id )
{
	assert( module_manager && module_manager->origin_id_map );

	return ( const ntg_interface * ) ntg_hashtable_lookup_guid( module_manager->origin_id_map, origin_id );
}


const ntg_interface *ntg_get_core_interface_by_name( const ntg_module_manager *module_manager, const char *name )
{
	assert( module_manager && module_manager->core_name_map );

	return ( const ntg_interface * ) ntg_hashtable_lookup_string( module_manager->core_name_map, name );
}


ntg_error_code ntg_interpret_legacy_module_id( const ntg_module_manager *module_manager, ntg_id old_id, GUID *output )
{
	GUID *legacy_module_id_table;
	assert( module_manager && output );

	legacy_module_id_table = module_manager->legacy_module_id_table;

	if( !legacy_module_id_table || old_id >= module_manager->legacy_module_id_table_elems )
	{
		NTG_TRACE_ERROR_WITH_INT( "Can't interpret class id", old_id );
		return NTG_ERROR;
	}

	*output = legacy_module_id_table[ old_id ];

	return ntg_guid_is_null( output ) ? NTG_ERROR : NTG_NO_ERROR;
}


ntg_module_manager *ntg_module_manager_create( const char *scratch_directory_root )
{
	char *implementation_directory_root;
	char *module_directory_root;
	ntg_module_manager *module_manager;

	module_manager = ntg_malloc( sizeof( ntg_module_manager ) );
	module_manager->module_id_map = ntg_hashtable_new();
	module_manager->origin_id_map = ntg_hashtable_new();
	module_manager->core_name_map = ntg_hashtable_new();
	module_manager->module_id_list = ntg_list_new( NTG_LIST_GUIDS );
	
	ntg_module_manager_load_legacy_module_id_file( module_manager );

	implementation_directory_root = ntg_strdup( scratch_directory_root );
	implementation_directory_root = ntg_string_append( implementation_directory_root, NTG_IMPLEMENTATION_DIRECTORY_NAME );

	if( !ntg_is_directory( implementation_directory_root ) )
	{
		mkdir( implementation_directory_root );
	}

	module_manager->implementation_directory_root = implementation_directory_root;

	module_directory_root = ntg_strdup( scratch_directory_root );
	module_directory_root = ntg_string_append( module_directory_root, NTG_MODULE_DIRECTORY_NAME );

	if( !ntg_is_directory( module_directory_root ) )
	{
		mkdir( module_directory_root );
	}

	module_manager->module_directory_root = module_directory_root;

	return module_manager;
}

	
void ntg_module_manager_free( ntg_module_manager *module_manager )
{
	assert( module_manager );

	ntg_free_all_modules( module_manager );

	ntg_hashtable_free( module_manager->module_id_map );
	ntg_hashtable_free( module_manager->origin_id_map );
	ntg_hashtable_free( module_manager->core_name_map );

	ntg_list_free( module_manager->module_id_list );

	if( module_manager->legacy_module_id_table )
	{
		ntg_free( module_manager->legacy_module_id_table );
	}

	ntg_delete_directory( module_manager->implementation_directory_root );
	ntg_free( module_manager->implementation_directory_root );

	ntg_delete_directory( module_manager->module_directory_root );
	ntg_free( module_manager->module_directory_root );

	ntg_free( module_manager );
}


void ntg_module_manager_load_from_directories( ntg_module_manager *module_manager, const char *module_directories )
{
	const char *comma;
	int path_length;
	char *path;

	assert( module_manager && module_directories );

	/* iterate through comma-separated list */
	for( comma = strchr( module_directories, ',' ); comma; comma = strchr( module_directories, ',' ) )
	{
		path_length = comma - module_directories;
		path = ntg_malloc( path_length + 1 );
		memcpy( path, module_directories, path_length );
		path[ path_length ] = 0;

		ntg_module_manager_load_from_directory( module_manager, path, NTG_MODULE_SHIPPED_WITH_INTEGRA );
		ntg_free( path );

		module_directories = comma + 1;
	}

	/* load from the last list entry (after last comma) */
	ntg_module_manager_load_from_directory( module_manager, module_directories, NTG_MODULE_SHIPPED_WITH_INTEGRA );
}


char *ntg_module_manager_get_patch_path( const ntg_module_manager *module_manager, const ntg_interface *interface )
{
	const char *patch_extension = ".pd";

	char *implementation_path;
	int implementation_path_length;

	assert( module_manager && interface && interface->implementation && interface->implementation->patch_name );

	implementation_path = ntg_module_manager_get_implementation_path( module_manager, interface );
	implementation_path = ntg_string_append( implementation_path, interface->implementation->patch_name );

	/* chop off patch extension */
	implementation_path_length = strlen( implementation_path ) - strlen( patch_extension );
	if( implementation_path_length <= 0 || strcmp( implementation_path + implementation_path_length, patch_extension ) != 0 )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Implementation path doesn't end in correct patch extension", implementation_path );
		ntg_free( implementation_path );
		return NULL;
	}

	implementation_path[ implementation_path_length ] = 0;

	return implementation_path;
}


ntg_list *ntg_module_manager_load_from_integra_file( ntg_module_manager *module_manager, const char *integra_file )
{
	unzFile unzip_file;
	unz_file_info file_info;
	char file_name[ NTG_LONG_STRLEN ];
	char *temporary_file_name;
	FILE *temporary_file;
	int implementation_directory_length;
	unsigned char *copy_buffer;
	int bytes_read;
	int total_bytes_read;
	int bytes_remaining;
	const GUID *loaded_module_id;
	ntg_list *embedded_module_ids;

	assert( module_manager && integra_file );

	unzip_file = unzOpen( integra_file );
	if( !unzip_file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Couldn't open zip file", integra_file );
		return NULL;
	}

	implementation_directory_length = strlen( NTG_INTEGRA_IMPLEMENTATION_DIRECTORY_NAME );

	if( unzGoToFirstFile( unzip_file ) != UNZ_OK )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Couldn't iterate contents", integra_file );
		unzClose( unzip_file );
		return NULL;
	}

	copy_buffer = ntg_malloc( NTG_DATA_COPY_BUFFER_SIZE );

	embedded_module_ids = ntg_list_new( NTG_LIST_GUIDS );

	do
	{
		temporary_file_name = NULL;
		temporary_file = NULL;

		if( unzGetCurrentFileInfo( unzip_file, &file_info, file_name, NTG_LONG_STRLEN, NULL, 0, NULL, 0 ) != UNZ_OK )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Couldn't extract file info", integra_file );
			continue;
		}

		if( strlen( file_name ) <= implementation_directory_length || memcmp( file_name, NTG_INTEGRA_IMPLEMENTATION_DIRECTORY_NAME, implementation_directory_length ) != 0 )
		{
			/* skip file not in node directory */
			continue;
		}

		temporary_file_name = tempnam( server_->scratch_directory_root, "embedded_module" );
		if( !temporary_file_name )
		{
			NTG_TRACE_ERROR( "couldn't generate temporary filename" );
			continue;
		}

		temporary_file = fopen( temporary_file_name, "wb" );
		if( !temporary_file )
		{
			NTG_TRACE_ERROR_WITH_STRING( "couldn't open temporary file", temporary_file_name );
			goto CLEANUP;
		}

		if( unzOpenCurrentFile( unzip_file ) != UNZ_OK )
		{
			NTG_TRACE_ERROR_WITH_STRING( "couldn't open zip contents", file_name );
			goto CLEANUP;
		}

		total_bytes_read = 0;
		while( total_bytes_read < file_info.uncompressed_size )
		{
			bytes_remaining = file_info.uncompressed_size - total_bytes_read;
			assert( bytes_remaining > 0 );

			bytes_read = unzReadCurrentFile( unzip_file, copy_buffer, MIN( NTG_DATA_COPY_BUFFER_SIZE, bytes_remaining ) );
			if( bytes_read <= 0 )
			{
				NTG_TRACE_ERROR( "Error decompressing file" );
				goto CLEANUP;
			}

			fwrite( copy_buffer, 1, bytes_read, temporary_file );

			total_bytes_read += bytes_read;
		}

		fclose( temporary_file );
		temporary_file = NULL;

		loaded_module_id = ntg_module_manager_load_module( module_manager, temporary_file_name, NTG_MODULE_EMBEDDED );
		if( loaded_module_id )
		{
			GUID *guids;
			embedded_module_ids->elems = ntg_realloc( embedded_module_ids->elems, ( embedded_module_ids->n_elems + 1 ) * sizeof( GUID ) );
			guids = ( GUID * )embedded_module_ids->elems;
			guids[ embedded_module_ids->n_elems ] = *loaded_module_id;
			embedded_module_ids->n_elems ++;
		}

		CLEANUP:

		if( temporary_file )
		{
			fclose( temporary_file );
		}

		if( temporary_file_name )
		{
			ntg_delete_file( temporary_file_name );
			ntg_free( temporary_file_name );
		}

		unzCloseCurrentFile( unzip_file );
	}
	while( unzGoToNextFile( unzip_file ) != UNZ_END_OF_LIST_OF_FILE );

	unzClose( unzip_file );

	ntg_free( copy_buffer );

	return embedded_module_ids;
}



void ntg_module_manager_unload_modules( ntg_module_manager *module_manager, const ntg_list *module_ids )
{
	ntg_interface *interface;
	const GUID *ids;
	int i;

	assert( module_manager && module_ids );

	ids = ( const GUID * ) module_ids->elems;
		
	for( i = 0; i < module_ids->n_elems; i++ )
	{
		interface = (ntg_interface *) ntg_get_interface_by_module_id( module_manager, &( ids[ i ] ) );
		assert( interface );

		ntg_unload_module( module_manager, interface );
	}
}
