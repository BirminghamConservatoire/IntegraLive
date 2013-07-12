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

#include "data_directory.h"
#include "helper.h"
#include "globals.h"
#include "file_io.h"

#ifdef _WINDOWS
	#define NTG_SCRATCH_DIRECTORY_ROOT "libIntegra" 
#else
	#define NTG_SCRATCH_DIRECTORY_ROOT ".libIntegra" 
#endif

void ntg_delete_directory( const char *directory_name )
{
	DIR *directory_stream;
	struct dirent *directory_entry;
	const char *name;
	char *full_path;
	struct stat entry_data;

	directory_stream = opendir( directory_name );
	if( !directory_stream )
	{
		NTG_TRACE_ERROR_WITH_STRING( "unable to open directory", directory_name );
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

		if( strcmp( name, ".." ) == 0 || strcmp( name, "." ) == 0 )
		{
			continue;
		}

		full_path = ntg_strdup( directory_name );
		full_path = ntg_string_append( full_path, NTG_PATH_SEPARATOR );
		full_path = ntg_string_append( full_path, name );

		if( stat( full_path, &entry_data ) != 0 )
		{
			NTG_TRACE_ERROR_WITH_ERRNO( "couldn't read directory entry data" );
			delete[] full_path;
			continue;
		}

		switch( entry_data.st_mode & _S_IFMT )
		{
			case S_IFDIR:	/* directory */
				ntg_delete_directory( full_path  );
				break;

			default:
				ntg_delete_file( full_path );
				break;
		}

		delete[] full_path;
	}
	while( directory_entry != NULL );

	closedir( directory_stream );

	if( rmdir( directory_name ) != 0 )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Failed to remove directory", directory_name );
	}
}


bool ntg_is_directory( const char *directory_name )
{
	struct stat status_info;

	assert( directory_name );

	return ( stat( directory_name, &status_info) == 0 && S_ISDIR( status_info.st_mode ) );
}


void ntg_scratch_directory_initialize( ntg_server *server )
{
#ifdef _WINDOWS

	char path_buffer[ NTG_LONG_STRLEN ];
	int i;
	GetTempPathA( NTG_LONG_STRLEN, path_buffer );

	/* replace windows slashes with unix slashes */
	for( i = strlen( path_buffer ) - 1; i >= 0; i-- )
	{
		if( path_buffer[ i ] == '\\' )
		{
			path_buffer[ i ] = '/';
		}
	}
	server->scratch_directory_root = ntg_strdup( path_buffer );

#else

	const char *tmp_dir = getenv( "TMPDIR" );
	if( tmp_dir )
	{
		server->scratch_directory_root = ntg_strdup( tmp_dir );
		server->scratch_directory_root = ntg_string_append( server->scratch_directory_root, NTG_PATH_SEPARATOR );
	}
	else
	{
		server->scratch_directory_root = ntg_strdup( "~/" );
	}
#endif
	
	server->scratch_directory_root = ntg_string_append( server->scratch_directory_root, NTG_SCRATCH_DIRECTORY_ROOT );

	if( ntg_is_directory( server->scratch_directory_root ) )
	{
		ntg_delete_directory( server->scratch_directory_root );
	}

	server->scratch_directory_root = ntg_string_append( server->scratch_directory_root, NTG_PATH_SEPARATOR );

	mkdir( server->scratch_directory_root );
}


void ntg_scratch_directory_free( ntg_server *server )
{
	ntg_delete_directory( server->scratch_directory_root );

	delete[] server->scratch_directory_root;
	server->scratch_directory_root = NULL;
}



char *ntg_extract_first_directory( const char *path )
{
	char *first_directory;
	char *first_slash, *first_backslash;
	
	assert( path );

	first_directory = ntg_strdup( path );

	first_slash = strchr( first_directory, '/' );
	first_backslash = strchr( first_directory, '\\' );

	if( !first_slash && !first_backslash )
	{
		return NULL;
	}

	if( first_slash ) 
	{
		*first_slash = 0;
	}

	if( first_backslash ) 
	{
		*first_backslash = 0;
	}

	return first_directory;
}


void ntg_construct_subdirectories( const char *root_directory, const char *relative_file_path )
{
	char *subdirectory;
	char *root_and_subdirectory;

	assert( root_directory && relative_file_path );

	subdirectory = ntg_extract_first_directory( relative_file_path );
	if( !subdirectory )
	{
		return;
	}

	root_and_subdirectory = new char[ strlen( root_directory ) + strlen( subdirectory ) + strlen( NTG_PATH_SEPARATOR ) + 1 ];
	sprintf( root_and_subdirectory, "%s%s%s", root_directory, subdirectory, NTG_PATH_SEPARATOR );

	mkdir( root_and_subdirectory );

	ntg_construct_subdirectories( root_and_subdirectory, relative_file_path + strlen( subdirectory ) + 1 );

	delete[] root_and_subdirectory;
	delete[] subdirectory;
}