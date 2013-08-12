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
#include "globals.h"
#include "logic.h"
#include "node_endpoint.h"
#include "value.h"
#include "file_helper.h"
#include "server.h"


namespace ntg_internal
{
	const string CDataDirectory::s_node_directory = "node_data";



	string CDataDirectory::create_for_node( const CNode &node, const CServer &server )
	{
		ostringstream stream;

		stream << server.get_scratch_directory() << s_node_directory << node.get_id() << CFileIO::s_path_separator;

		string node_directory_name = stream.str();

		mkdir( node_directory_name.c_str() );

		return node_directory_name;
	}


	void CDataDirectory::change( const string &old_directory, const string &new_directory )
	{
		CFileHelper::delete_directory( old_directory );

		mkdir( new_directory.c_str() );
	}


	void CDataDirectory::copy_to_zip( zipFile zip_file, const CNode &node, const CPath &path_root )
	{
		assert( zip_file );

		if( node.get_logic().has_data_directory() )
		{
			string relative_node_path = get_relative_node_path( node, path_root );

			if( relative_node_path.empty() )
			{
				NTG_TRACE_ERROR << "Couldn't build relative node path to " << node.get_path().get_string();
			}
			else
			{
				ostringstream target_path;
				target_path << s_node_directory << CFileIO::s_path_separator << relative_node_path;
			
				const string *data_directory_name = node.get_logic().get_data_directory();
				if( data_directory_name )
				{
					copy_directory_contents_to_zip( zip_file, target_path.str(), *data_directory_name );
				}
				else
				{
					NTG_TRACE_ERROR << "Couldn't get data directory name for " << node.get_path().get_string();
				}
			}
		}

		/* walk tree of child nodes */
		const node_map &children = node.get_children();
		for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
		{
			const CNode *child = i->second;
			copy_to_zip( zip_file, *child, path_root );
		}
	}


	CError CDataDirectory::extract_from_zip( const string &file_path, const CNode *parent_node )
	{
		unzFile unzip_file = unzOpen( file_path.c_str() );
		if( !unzip_file )
		{
			NTG_TRACE_ERROR << "Couldn't open zip file " << file_path;
			return CError::FAILED;
		}

		string node_directory = get_node_directory_path_in_zip( unzip_file );
		int node_directory_length = node_directory.length();

		if( unzGoToFirstFile( unzip_file ) != UNZ_OK )
		{
			NTG_TRACE_ERROR << "Couldn't iterate contents of " << file_path;
			unzClose( unzip_file );
			return CError::FAILED;
		}

		do
		{
			unz_file_info file_info;
			char file_name[ NTG_LONG_STRLEN ];
			if( unzGetCurrentFileInfo( unzip_file, &file_info, file_name, NTG_LONG_STRLEN, NULL, 0, NULL, 0 ) != UNZ_OK )
			{
				NTG_TRACE_ERROR << "Couldn't extract file info for " << file_path;
				continue;
			}

			if( strlen( file_name ) <= node_directory_length || memcmp( file_name, node_directory.c_str(), node_directory_length ) != 0 )
			{
				/* skip file not in node directory */
				continue;
			}

			string relative_node_path_string = CFileHelper::extract_first_directory_from_path( file_name + node_directory_length );
			if( relative_node_path_string.empty() )
			{
				NTG_TRACE_ERROR << "unexpected content - no relative path: " << file_name;
				continue;
			}

			CPath relative_node_path = CPath( relative_node_path_string );
			const CNode *node = server_->find_node( relative_node_path, parent_node );

			if( !node )
			{
				NTG_TRACE_ERROR << "couldn't resolve path: " << relative_node_path_string;
				continue;
			}

			if( !node->get_logic().has_data_directory() )
			{
				NTG_TRACE_ERROR << "found data file for node which shouldn't have data directory: " << file_name;
				continue;
			}

			const char *relative_file_path = file_name + node_directory_length + relative_node_path_string.length() + 1;

			if( unzOpenCurrentFile( unzip_file ) == UNZ_OK )
			{
				extract_from_zip_to_data_directory( unzip_file, &file_info, *node, relative_file_path );

				unzCloseCurrentFile( unzip_file );
			}
			else
			{
				NTG_TRACE_ERROR << "couldn't open zip contents: " << file_name;
			}
		}
		while( unzGoToNextFile( unzip_file ) != UNZ_END_OF_LIST_OF_FILE );

		unzClose( unzip_file );

		return CError::SUCCESS;
	}


	void CDataDirectory::extract_from_zip_to_data_directory( unzFile unzip_file, unz_file_info *file_info, const CNode &node, const char *relative_file_path )
	{
		char *target_path;
		FILE *output_file;
		unsigned char *output_buffer;
		int bytes_read, total_bytes_read, bytes_remaining;

		assert( unzip_file && file_info && relative_file_path );

		const string *data_directory = node.get_logic().get_data_directory();
		assert( data_directory );

		CFileHelper::construct_subdirectories( *data_directory, relative_file_path );

		target_path = new char[ data_directory->length() + strlen( relative_file_path ) + 1 ];
		sprintf( target_path, "%s%s", data_directory->c_str(), relative_file_path );

		output_file = fopen( target_path, "wb" );
		if( !output_file )
		{
			NTG_TRACE_ERROR << "Couldn't write to data directory: " << target_path;
			delete[] target_path;
			return;
		}

		delete[] target_path;

		output_buffer = new unsigned char[ CFileIO::s_data_copy_buffer_size ];

		total_bytes_read = 0;
		while( total_bytes_read < file_info->uncompressed_size )
		{
			bytes_remaining = file_info->uncompressed_size - total_bytes_read;
			assert( bytes_remaining > 0 );

			bytes_read = unzReadCurrentFile( unzip_file, output_buffer, MIN( CFileIO::s_data_copy_buffer_size, bytes_remaining ) );
			if( bytes_read <= 0 )
			{
				NTG_TRACE_ERROR << "Error decompressing file";
				break;
			}

			fwrite( output_buffer, 1, bytes_read, output_file );

			total_bytes_read += bytes_read;
		}

		delete[] output_buffer;

		fclose( output_file );
	}


	string CDataDirectory::copy_file_to_data_directory( const CNodeEndpoint &input_file )
	{
		const string *data_directory = input_file.get_node().get_logic().get_data_directory();
		if( !data_directory )
		{
			NTG_TRACE_ERROR << "can't get data directory for node " << input_file.get_node().get_name();
			return NULL;
		}

		const string &input_path = *input_file.get_value();
		string copied_file = CFileHelper::extract_filename_from_path( input_path );
		if( copied_file.empty() || copied_file == input_path )
		{
			NTG_TRACE_ERROR << "can't extract filename from path " << input_path;
			return NULL;
		}

		string output_filename( *data_directory );
		output_filename += copied_file;

		CFileHelper::copy_file( input_path.c_str(), output_filename.c_str() );

		return copied_file;
	}


	string CDataDirectory::get_relative_node_path( const CNode &node, const CPath &root ) 
	{
		const string &node_path_string = node.get_path().get_string();
		const string &root_path_string = root.get_string();

		int node_path_length = node_path_string.length();
		int root_path_length = root_path_string.length();

		if( node_path_length <= root_path_length || node_path_string.substr( 0, root_path_length ) != root_path_string )
		{
			NTG_TRACE_ERROR << "node is not a descendant of root";
			return string();
		}

		if( root_path_length > 0 ) 
		{
			/* if root is not the root of the entire tree, skip the dot after root path */
			root_path_length++;
		}

		return node_path_string.substr( root_path_length );
	}


	string CDataDirectory::get_node_directory_path_in_zip( unzFile unzip_file )
	{
		/* 
		 This method is needed because old versions of integra live stored directly in integra_data, instead 
		 of integra_data/node_data.
		*/

		string normal_node_directory_path = CFileIO::s_data_directory_name + s_node_directory + CFileIO::s_path_separator;

		assert( unzip_file );

		if( does_zip_contain_directory( unzip_file, normal_node_directory_path ) )
		{
			return normal_node_directory_path;
		}

		if( does_zip_contain_directory( unzip_file, CFileIO::s_implementation_directory_name ) )
		{
			return normal_node_directory_path;
		}

		return CFileIO::s_data_directory_name;
	}


	bool CDataDirectory::does_zip_contain_directory( unzFile unzip_file, const string &directory )
	{
		assert( unzip_file );

		int directory_length = directory.length();

		if( unzGoToFirstFile( unzip_file ) != UNZ_OK )
		{
			NTG_TRACE_ERROR << "Couldn't iterate contents";
			return false;
		}

		do
		{
			unz_file_info file_info;
			char file_name[ NTG_LONG_STRLEN ];
			if( unzGetCurrentFileInfo( unzip_file, &file_info, file_name, NTG_LONG_STRLEN, NULL, 0, NULL, 0 ) != UNZ_OK )
			{
				NTG_TRACE_ERROR << "Couldn't extract file info";
				continue;
			}

			if( strlen( file_name ) >= directory_length && memcmp( file_name, directory.c_str(), directory_length ) == 0 )
			{
				return true;
			}
		}
		while( unzGoToNextFile( unzip_file ) != UNZ_END_OF_LIST_OF_FILE );

		return false;
	}



	void CDataDirectory::copy_directory_contents_to_zip( zipFile zip_file, const string &target_path, const string &source_path )
	{
		DIR *directory_stream = opendir( source_path.c_str() );
		if( !directory_stream )
		{
			NTG_TRACE_ERROR << "unable to open directory " << source_path;
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

			string file_name = directory_entry->d_name;

			if( file_name == ".." || file_name == "." )
			{
				continue;
			}

			string full_source_path = source_path + file_name;

			struct stat entry_data;
			if( stat( full_source_path.c_str(), &entry_data ) != 0 )
			{
				NTG_TRACE_ERROR << "couldn't read directory entry data: " << strerror( errno );
				continue;
			}

			ostringstream full_target_path;
			full_target_path << CFileIO::s_data_directory_name << target_path << CFileIO::s_path_separator << file_name;

			switch( entry_data.st_mode & _S_IFMT )
			{
				case S_IFDIR:	/* directory */
					full_source_path += CFileIO::s_path_separator;
					copy_directory_contents_to_zip( zip_file, full_target_path.str(), full_source_path );
					break;

				default:
					CFileIO::copy_file_to_zip( zip_file, full_target_path.str(), full_source_path );
					break;
			}
		}
		while( directory_entry != NULL );
	}






}


