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
#include "helper.h"
#include "globals.h"
#include "system_class_handlers.h"
#include "node_endpoint.h"
#include "value.h"
#include "file_helpers.h"


#define NTG_NODE_DIRECTORY "node_data"


using namespace ntg_api;


namespace ntg_internal
{
	string CDataDirectory::create_for_node( const CNode &node, const CServer &server )
	{
		ostringstream stream;

		stream << server.scratch_directory_root() << NTG_NODE_DIRECTORY << node.get_id() << NTG_PATH_SEPARATOR;

		string node_directory_name = stream.str();

		mkdir( node_directory_name.c_str() );

		return node_directory_name;
	}


	void CDataDirectory::change( const ntg_api::string &old_directory, const ntg_api::string &new_directory )
	{
		ntg_delete_directory( old_directory.c_str() );

		mkdir( new_directory.c_str() );
	}


	void CDataDirectory::copy_to_zip( zipFile zip_file, const ntg_internal::CNode &node, const ntg_api::CPath &path_root )
	{
		assert( zip_file );

		if( ntg_node_has_data_directory( node ) )
		{
			string relative_node_path = get_relative_node_path( node, path_root );

			if( relative_node_path.empty() )
			{
				NTG_TRACE_ERROR_WITH_STRING( "Couldn't build relative node path to", node.get_path().get_string().c_str() );
			}
			else
			{
				ostringstream target_path;
				target_path << NTG_NODE_DIRECTORY << NTG_PATH_SEPARATOR << relative_node_path;
			
				const string *data_directory_name = ntg_node_get_data_directory( node );
				if( data_directory_name )
				{
					ntg_copy_directory_contents_to_zip( zip_file, target_path.str().c_str(), data_directory_name->c_str() );
				}
				else
				{
					NTG_TRACE_ERROR_WITH_STRING( "Couldn't get data directory name", node.get_path().get_string().c_str() );
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


	ntg_api::error_code CDataDirectory::extract_from_zip( const ntg_api::string &file_path, const ntg_internal::CNode *parent_node )
	{
		unzFile unzip_file = unzOpen( file_path.c_str() );
		if( !unzip_file )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Couldn't open zip file", file_path.c_str() );
			return NTG_FAILED;
		}

		string node_directory = get_node_directory_path_in_zip( unzip_file );
		int node_directory_length = node_directory.length();

		if( unzGoToFirstFile( unzip_file ) != UNZ_OK )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Couldn't iterate contents", file_path.c_str() );
			unzClose( unzip_file );
			return NTG_FAILED;
		}

		do
		{
			unz_file_info file_info;
			char file_name[ NTG_LONG_STRLEN ];
			if( unzGetCurrentFileInfo( unzip_file, &file_info, file_name, NTG_LONG_STRLEN, NULL, 0, NULL, 0 ) != UNZ_OK )
			{
				NTG_TRACE_ERROR_WITH_STRING( "Couldn't extract file info", file_path.c_str() );
				continue;
			}

			if( strlen( file_name ) <= node_directory_length || memcmp( file_name, node_directory.c_str(), node_directory_length ) != 0 )
			{
				/* skip file not in node directory */
				continue;
			}

			string relative_node_path_string = CFileHelpers::extract_first_directory_from_path( file_name + node_directory_length );
			if( relative_node_path_string.empty() )
			{
				NTG_TRACE_ERROR_WITH_STRING( "unexpected content - no relative path", file_name );
				continue;
			}

			CPath relative_node_path = CPath( relative_node_path_string );
			const CNode *node = server_->find_node( relative_node_path, parent_node );

			if( !node )
			{
				NTG_TRACE_ERROR_WITH_STRING( "couldn't resolve path", relative_node_path_string.c_str() );
				continue;
			}

			if( !ntg_node_has_data_directory( *node ) )
			{
				NTG_TRACE_ERROR_WITH_STRING( "found data file for node which shouldn't have data directory", file_name );
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
				NTG_TRACE_ERROR_WITH_STRING( "couldn't open zip contents", file_name );
			}
		}
		while( unzGoToNextFile( unzip_file ) != UNZ_END_OF_LIST_OF_FILE );

		unzClose( unzip_file );

		return NTG_NO_ERROR;
	}


	void CDataDirectory::extract_from_zip_to_data_directory( unzFile unzip_file, unz_file_info *file_info, const CNode &node, const char *relative_file_path )
	{
		char *target_path;
		FILE *output_file;
		unsigned char *output_buffer;
		int bytes_read, total_bytes_read, bytes_remaining;

		assert( unzip_file && file_info && relative_file_path );

		const string *data_directory = ntg_node_get_data_directory( node );
		assert( data_directory );

		ntg_construct_subdirectories( data_directory->c_str(), relative_file_path );

		target_path = new char[ data_directory->length() + strlen( relative_file_path ) + 1 ];
		sprintf( target_path, "%s%s", data_directory->c_str(), relative_file_path );

		output_file = fopen( target_path, "wb" );
		if( !output_file )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Couldn't write to data directory", target_path );
			delete[] target_path;
			return;
		}

		delete[] target_path;

		output_buffer = new unsigned char[ NTG_DATA_COPY_BUFFER_SIZE ];

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

		delete[] output_buffer;

		fclose( output_file );
	}


	ntg_api::string CDataDirectory::copy_file_to_data_directory( const ntg_internal::CNodeEndpoint &node_endpoint )
	{
		const string *data_directory = ntg_node_get_data_directory( *node_endpoint.get_node() );
		if( !data_directory )
		{
			NTG_TRACE_ERROR_WITH_STRING( "can't get data directory for node", node_endpoint.get_node()->get_name().c_str() );
			return NULL;
		}

		const string &input_path = *node_endpoint.get_value();
		string copied_file = CFileHelpers::extract_filename_from_path( input_path );
		if( copied_file.empty() || copied_file == input_path )
		{
			NTG_TRACE_ERROR_WITH_STRING( "can't extract filename from path", input_path.c_str() );
			return NULL;
		}

		string output_filename( *data_directory );
		output_filename += copied_file;

		ntg_copy_file( input_path.c_str(), output_filename.c_str() );

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
			NTG_TRACE_ERROR( "node is not a descendant of root" );
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

		const char *normal_node_directory_path = NTG_INTEGRA_DATA_DIRECTORY_NAME NTG_NODE_DIRECTORY NTG_PATH_SEPARATOR;
		const char *old_node_directory_path = NTG_INTEGRA_DATA_DIRECTORY_NAME;

		assert( unzip_file );

		if( does_zip_contain_directory( unzip_file, normal_node_directory_path ) )
		{
			return normal_node_directory_path;
		}

		if( does_zip_contain_directory( unzip_file, NTG_INTEGRA_IMPLEMENTATION_DIRECTORY_NAME ) )
		{
			return normal_node_directory_path;
		}

		return old_node_directory_path;
	}


	bool CDataDirectory::does_zip_contain_directory( unzFile unzip_file, const string &directory )
	{
		assert( unzip_file );

		int directory_length = directory.length();

		if( unzGoToFirstFile( unzip_file ) != UNZ_OK )
		{
			NTG_TRACE_ERROR( "Couldn't iterate contents" );
			return false;
		}

		do
		{
			unz_file_info file_info;
			char file_name[ NTG_LONG_STRLEN ];
			if( unzGetCurrentFileInfo( unzip_file, &file_info, file_name, NTG_LONG_STRLEN, NULL, 0, NULL, 0 ) != UNZ_OK )
			{
				NTG_TRACE_ERROR( "Couldn't extract file info" );
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







}




#if 0   //DEPRECATED
string ntg_make_up_node_data_directory_name( const CNode &node, const CServer &server )
{
	ostringstream stream;

	stream << server.scratch_directory_root() << NTG_NODE_DIRECTORY << node.get_id(), NTG_PATH_SEPARATOR;

	return stream.str();
}


string ntg_node_data_directory_create( const CNode &node, const CServer &server )
{
	string node_directory_name = ntg_make_up_node_data_directory_name( node, server );

	mkdir( node_directory_name.c_str() );

	return node_directory_name;
}


void ntg_node_data_directory_change( const char *previous_directory_name, const char *new_directory_name )
{
	assert( previous_directory_name && new_directory_name );

	ntg_delete_directory( previous_directory_name );

	mkdir( new_directory_name );
}


string ntg_get_relative_node_path( const CNode &node, const CPath &root ) 
{
	const string &node_path_string = node.get_path().get_string();
	const string &root_path_string = root.get_string();

	int node_path_length = node_path_string.length();
	int root_path_length = root_path_string.length();

	if( node_path_length <= root_path_length || node_path_string.substr( 0, root_path_length ) != root_path_string )
	{
		NTG_TRACE_ERROR( "node is not a descendant of root" );
		return string();
	}

	if( root_path_length > 0 ) 
	{
		/* if root is not the root of the entire tree, skip the dot after root path */
		root_path_length++;
	}

	return node_path_string.substr( root_path_length );
}


void ntg_copy_node_data_directories_to_zip( zipFile zip_file, const CNode &node, const CPath &path_root )
{
	assert( zip_file );

	if( ntg_node_has_data_directory( node ) )
	{
		string relative_node_path = ntg_get_relative_node_path( node, path_root );

		if( relative_node_path.empty() )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Couldn't build relative node path to", node.get_path().get_string().c_str() );
		}
		else
		{
			ostringstream target_path;
			target_path << NTG_NODE_DIRECTORY << NTG_PATH_SEPARATOR << relative_node_path;
			
			const string *data_directory_name = ntg_node_get_data_directory( node );
			if( data_directory_name )
			{
				ntg_copy_directory_contents_to_zip( zip_file, target_path.str().c_str(), data_directory_name->c_str() );
			}
			else
			{
				NTG_TRACE_ERROR_WITH_STRING( "Couldn't get data directory name", node.get_path().get_string().c_str() );
			}
		}
	}

	/* walk tree of child nodes */
	const node_map &children = node.get_children();
	for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
	{
		const CNode *child = i->second;
		ntg_copy_node_data_directories_to_zip( zip_file, *child, path_root );
	}
}


void ntg_extract_to_data_directory( unzFile unzip_file, unz_file_info *file_info, const CNode &node, const char *relative_file_path )
{
	char *target_path;
	FILE *output_file;
	unsigned char *output_buffer;
	int bytes_read, total_bytes_read, bytes_remaining;

	assert( unzip_file && file_info && relative_file_path );

	const string *data_directory = ntg_node_get_data_directory( node );
	assert( data_directory );

	ntg_construct_subdirectories( data_directory->c_str(), relative_file_path );

	target_path = new char[ data_directory->length() + strlen( relative_file_path ) + 1 ];
	sprintf( target_path, "%s%s", data_directory->c_str(), relative_file_path );

	output_file = fopen( target_path, "wb" );
	if( !output_file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Couldn't write to data directory", target_path );
		delete[] target_path;
		return;
	}

	delete[] target_path;

	output_buffer = new unsigned char[ NTG_DATA_COPY_BUFFER_SIZE ];

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

	delete[] output_buffer;

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


error_code ntg_load_data_directories( const char *file_path, const CNode *parent_node )
{
	unzFile unzip_file;
	unz_file_info file_info;
	char file_name[ NTG_LONG_STRLEN ];
	const char *node_directory;
	char *relative_node_path_string;
	const char *relative_file_path;
	int node_directory_length;

	assert( file_path );

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

		CPath relative_node_path = CPath( relative_node_path_string );
		const CNode *node = server_->find_node( relative_node_path, parent_node );

		if( !node )
		{
			NTG_TRACE_ERROR_WITH_STRING( "couldn't resolve path", relative_node_path_string );
			delete[] relative_node_path_string;
			continue;
		}

		if( !ntg_node_has_data_directory( *node ) )
		{
			NTG_TRACE_ERROR_WITH_STRING( "found data file for node which shouldn't have data directory", file_name );
			delete[] relative_node_path_string;
			continue;
		}

		relative_file_path = file_name + node_directory_length + strlen( relative_node_path_string ) + 1;
		delete[] relative_node_path_string;

		if( unzOpenCurrentFile( unzip_file ) == UNZ_OK )
		{
			ntg_extract_to_data_directory( unzip_file, &file_info, *node, relative_file_path );

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


const char *ntg_copy_file_to_data_directory( const CNodeEndpoint *endpoint )
{
	assert( endpoint );

	const string *data_directory = ntg_node_get_data_directory( *endpoint->get_node() );
	if( !data_directory )
	{
		NTG_TRACE_ERROR_WITH_STRING( "can't get data directory for node", endpoint->get_node()->get_name().c_str() );
		return NULL;
	}

	const string &input_path = *endpoint->get_value();
	const char *copied_file = ntg_extract_filename_from_path( input_path.c_str() );
	if( !copied_file )
	{
		NTG_TRACE_ERROR_WITH_STRING( "can't extract filename from path", input_path.c_str() );
		return NULL;
	}

	string output_filename( *data_directory );
	output_filename += copied_file;

	ntg_copy_file( input_path.c_str(), output_filename.c_str() );

	return copied_file;
}


#endif //deprecated