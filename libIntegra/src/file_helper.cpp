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
#ifdef _WINDOWS
#include <direct.h>
#else
#include <sys/stat.h>
#define _S_IFMT S_IFMT
#define mkdir(x) mkdir(x, 0777)
#endif
#include <dirent.h>

#include "file_helper.h"
#include "file_io.h"
#include "api/trace.h"


namespace integra_internal
{
	string CFileHelper::extract_filename_from_path( const string &path )
	{
		size_t last_slash = path.find_last_of( '/' );
		size_t last_backslash = path.find_last_of( '\\' );

		size_t filename_start = ( last_slash == string::npos ) ? 0 : last_slash + 1;

		if( last_backslash != string::npos )
		{
			filename_start = MAX( filename_start, last_backslash + 1 );
		}

		return path.substr( filename_start );
	}


	string CFileHelper::extract_suffix_from_path( const string &path )
	{
		string filename = extract_filename_from_path( path );

		size_t last_dot = filename.find_last_of( '.' );

		if( last_dot == string::npos )
		{
			return "";
		}
		else
		{
			return filename.substr( last_dot + 1 );
		}
	}


	string CFileHelper::extract_directory_from_path( const string &path )
	{
		size_t last_slash = path.find_last_of( '/' );
		size_t last_backslash = path.find_last_of( '\\' );

		size_t directory_length = ( last_slash == string::npos ) ? 0 : last_slash + 1;

		if( last_backslash != string::npos )
		{
			directory_length = MAX( directory_length, last_backslash + 1 );
		}

		return path.substr( 0, directory_length );
	}


	string CFileHelper::extract_first_directory_from_path( const string &path )
	{
		size_t first_slash = path.find_first_of( '/' );
		size_t first_backslash = path.find_first_of( '\\' );

		if( first_slash == string::npos )
		{
			if( first_backslash == string::npos )
			{
				return string();
			}
			else
			{
				return path.substr( 0, first_backslash );
			}
		}
		else
		{
			if( first_backslash == string::npos )
			{
				return path.substr( 0, first_slash );
			}
			else
			{
				return path.substr( 0, MIN( first_slash, first_backslash ) );
			}
		}
	}


	bool CFileHelper::is_directory( const string &directory_name )
	{
		struct stat status_info;
		return ( stat( directory_name.c_str(), &status_info) == 0 && S_ISDIR( status_info.st_mode ) );
	}


	void CFileHelper::delete_directory( const string &directory_name )
	{
		DIR *directory_stream = opendir( directory_name.c_str() );
		if( !directory_stream )
		{
			INTEGRA_TRACE_ERROR << "unable to open directory " << directory_name;
			return;
		}

		struct dirent *directory_entry = NULL;
		while( true )
		{
			directory_entry = readdir( directory_stream );
			if( !directory_entry )
			{
				break;
			}

			const char *name = directory_entry->d_name;

			if( strcmp( name, ".." ) == 0 || strcmp( name, "." ) == 0 )
			{
				continue;
			}

			string full_path = directory_name + CFileIO::path_separator + name;

			struct stat entry_data;
			if( stat( full_path.c_str(), &entry_data ) != 0 )
			{
				INTEGRA_TRACE_ERROR << "couldn't read directory entry data: " << strerror( errno );
				continue;
			}

			switch( entry_data.st_mode & _S_IFMT )
			{
				case S_IFDIR:	/* directory */
					delete_directory( full_path  );
					break;

				default:
					delete_file( full_path );
					break;
			}
		}
		while( directory_entry != NULL );

		closedir( directory_stream );

		if( rmdir( directory_name.c_str() ) != 0 )
		{
			INTEGRA_TRACE_ERROR << "Failed to remove directory " << directory_name;
		}
	}


	bool CFileHelper::file_exists( const string &file_name )
	{
		FILE *file = fopen( file_name.c_str(), "rb" );
		if( file )
		{
			fclose( file );
			return true;
		}

		return false;
	}


	CError CFileHelper::delete_file( const string &file_name )
	{
		if( remove( file_name.c_str() ) != 0 )
		{
			INTEGRA_TRACE_ERROR << "Failed to remove file " << file_name;
			return CError::FAILED;
		}

		return CError::SUCCESS;
	}


	CError CFileHelper::copy_file( const string &source_path, const string &target_path )
	{
		CError error = CError::FAILED;

		FILE *source_file = fopen( source_path.c_str(), "rb" );
		if( !source_file )
		{
			INTEGRA_TRACE_ERROR << "failed to open: " << source_path;
			return CError::FAILED;
		}

		fseek( source_file, 0, SEEK_END );
		unsigned long bytes_to_copy = ftell( source_file );
		fseek( source_file, 0, SEEK_SET );

		FILE *target_file = fopen( target_path.c_str(), "wb" );
        unsigned char *copy_buffer = NULL;
        
		if( !target_file )
		{
			INTEGRA_TRACE_ERROR << "couldn't open for writing: " << target_path;
			goto CLEANUP;
		}

		copy_buffer = new unsigned char[ CFileIO::data_copy_buffer_size ];

		while( bytes_to_copy > 0 )
		{
			unsigned long bytes_read = fread( copy_buffer, 1, MIN( bytes_to_copy, CFileIO::data_copy_buffer_size ), source_file );
			if( bytes_read <= 0 )
			{
				INTEGRA_TRACE_ERROR << "error reading: " << source_path;
				goto CLEANUP;
			}

			fwrite( copy_buffer, 1, bytes_read, target_file );
			bytes_to_copy -= bytes_read;
		}

		error = CError::SUCCESS;

	CLEANUP:

		if( copy_buffer )	delete[] copy_buffer;
		if( target_file )	fclose( target_file );
		if( source_file )	fclose( source_file );

		return error;
	}


	void CFileHelper::construct_subdirectories( const string &root_directory, const string &relative_file_path )
	{
		string subdirectory = CFileHelper::extract_first_directory_from_path( relative_file_path );
		if( subdirectory.empty() )
		{
			return;
		}

		string root_and_subdirectory = root_directory + subdirectory + CFileIO::path_separator;

		mkdir( root_and_subdirectory.c_str() );

		construct_subdirectories( root_and_subdirectory, relative_file_path.substr( subdirectory.length() + 1 ) );
	}


	string CFileHelper::ensure_filename_has_suffix( const string &filename, const string &suffix )
	{
		int filename_length = filename.length();
		int suffix_length = suffix.length();

		if( filename_length > suffix_length + 1 )
		{
			if( filename.substr( filename_length - suffix_length ) == suffix )
			{
				if( filename[ filename_length - suffix_length - 1 ] == '.' )
				{
					/* filename already has suffix */
					return filename;
				}
			}
		}

		return filename + "." + suffix;
	}
}