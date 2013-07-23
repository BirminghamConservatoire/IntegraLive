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

#include "module_manager.h"
#include "scratch_directory.h"
#include "interface.h"
#include "helper.h"
#include "globals.h"
#include "file_io.h"

using namespace ntg_api;

/* 
 whilst dealing with zipped files, we always use linux-style path separators, 
 because windows can use the two interchangeably, 
 and PD can't cope with windows separators at all
*/

#define NTG_MODULE_INNER_DIRECTORY_NAME "integra_module_data" NTG_PATH_SEPARATOR
#define NTG_IDD_FILE_NAME NTG_MODULE_INNER_DIRECTORY_NAME "interface_definition.iid"
#define NTG_INTERNAL_IMPLEMENTATION_DIRECTORY_NAME NTG_MODULE_INNER_DIRECTORY_NAME "implementation" NTG_PATH_SEPARATOR

#define NTG_IMPLEMENTATION_DIRECTORY_NAME "implementations" NTG_PATH_SEPARATOR
#define NTG_EMBEDDED_MODULE_DIRECTORY_NAME "loaded_embedded_modules" NTG_PATH_SEPARATOR

#define NTG_CHECKSUM_SEED 53

#ifndef _WINDOWS
#include <sys/stat.h>
#define _S_IFMT S_IFMT
#endif


#define NTG_LEGACY_CLASS_ID_FILENAME "id2guid.csv"


namespace ntg_internal
{
	CModuleManager::CModuleManager( const string &scratch_directory_root, const string &system_module_directory, const string &third_party_module_directory )
	{
		load_legacy_module_id_file();

		m_implementation_directory_root = scratch_directory_root + NTG_IMPLEMENTATION_DIRECTORY_NAME;

		if( !ntg_is_directory( m_implementation_directory_root.c_str() ) )
		{
			mkdir( m_implementation_directory_root.c_str() );
		}

		m_embedded_module_directory = scratch_directory_root + NTG_EMBEDDED_MODULE_DIRECTORY_NAME;

		if( !ntg_is_directory( m_embedded_module_directory.c_str() ) )
		{
			mkdir( m_embedded_module_directory.c_str() );
		}

		load_modules_from_directory( system_module_directory, NTG_MODULE_SHIPPED_WITH_INTEGRA );

		load_modules_from_directory( third_party_module_directory, NTG_MODULE_3RD_PARTY );
		m_third_party_module_directory = third_party_module_directory + NTG_PATH_SEPARATOR;
	}


	CModuleManager::~CModuleManager()
	{
		unload_all_modules();

		if( m_legacy_module_id_table )
		{
			delete[] m_legacy_module_id_table;
		}

		ntg_delete_directory( m_implementation_directory_root.c_str() );

		ntg_delete_directory( m_embedded_module_directory.c_str() );
	}


	ntg_error_code CModuleManager::load_from_integra_file( const string &integra_file, guid_set &new_embedded_modules )
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
		GUID loaded_module_id;
		ntg_error_code error_code = NTG_NO_ERROR;

		new_embedded_modules.clear();

		unzip_file = unzOpen( integra_file.c_str() );
		if( !unzip_file )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Couldn't open zip file", integra_file.c_str() );
			return NTG_FAILED;
		}

		implementation_directory_length = strlen( NTG_INTEGRA_IMPLEMENTATION_DIRECTORY_NAME );

		if( unzGoToFirstFile( unzip_file ) != UNZ_OK )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Couldn't iterate contents", integra_file.c_str() );
			unzClose( unzip_file );
			return NTG_FAILED;
		}

		copy_buffer = new unsigned char[ NTG_DATA_COPY_BUFFER_SIZE ];

		do
		{
			temporary_file_name = NULL;
			temporary_file = NULL;

			if( unzGetCurrentFileInfo( unzip_file, &file_info, file_name, NTG_LONG_STRLEN, NULL, 0, NULL, 0 ) != UNZ_OK )
			{
				NTG_TRACE_ERROR_WITH_STRING( "Couldn't extract file info", integra_file.c_str() );
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
				error_code = NTG_FAILED;
				continue;
			}

			temporary_file = fopen( temporary_file_name, "wb" );
			if( !temporary_file )
			{
				NTG_TRACE_ERROR_WITH_STRING( "couldn't open temporary file", temporary_file_name );
				error_code = NTG_FAILED;
				goto CLEANUP;
			}

			if( unzOpenCurrentFile( unzip_file ) != UNZ_OK )
			{
				NTG_TRACE_ERROR_WITH_STRING( "couldn't open zip contents", file_name );
				error_code = NTG_FAILED;
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
					error_code = NTG_FAILED;
					goto CLEANUP;
				}

				fwrite( copy_buffer, 1, bytes_read, temporary_file );

				total_bytes_read += bytes_read;
			}

			fclose( temporary_file );
			temporary_file = NULL;

			if( load_module( temporary_file_name, NTG_MODULE_EMBEDDED, loaded_module_id ) )
			{
				new_embedded_modules.insert( loaded_module_id );

				store_module( loaded_module_id );
			}

			CLEANUP:

			if( temporary_file )
			{
				fclose( temporary_file );
			}

			if( temporary_file_name )
			{
				ntg_delete_file( temporary_file_name );
				delete[] temporary_file_name;
			}

			unzCloseCurrentFile( unzip_file );
		}
		while( unzGoToNextFile( unzip_file ) != UNZ_END_OF_LIST_OF_FILE );

		unzClose( unzip_file );

		delete[] copy_buffer;

		return error_code;
	}


	ntg_error_code CModuleManager::install_module( const string &module_file, CModuleInstallResult &result )
	{
		bool module_was_loaded = false;
		GUID module_id;
	
		memset( &result, 0, sizeof( CModuleInstallResult ) );

		ntg_guid_set_null( &module_id );

		module_was_loaded = load_module( module_file, NTG_MODULE_3RD_PARTY, module_id );
		if( module_was_loaded )
		{
			result.module_id = module_id;
			return store_module( module_id );
		}

		if( ntg_guid_is_null( &module_id ) )
		{
			return NTG_FILE_VALIDATION_ERROR;
		}

		const ntg_interface *existing_interface = get_interface_by_module_id( module_id );
		if( !existing_interface )
		{
			NTG_TRACE_ERROR( "can't lookup existing interface" );
			return NTG_FAILED;
		}

		switch( existing_interface->module_source )
		{
			case NTG_MODULE_SHIPPED_WITH_INTEGRA:
			case NTG_MODULE_3RD_PARTY:
			case NTG_MODULE_IN_DEVELOPMENT:
				return NTG_MODULE_ALREADY_INSTALLED;

			case NTG_MODULE_EMBEDDED:
				result.module_id = module_id;
				result.was_previously_embedded = true;
				return change_module_source( ( ntg_interface & ) *existing_interface, NTG_MODULE_3RD_PARTY );

			default:

				NTG_TRACE_ERROR( "existing interface has unexpected module source" );
				return NTG_FAILED;
		}
	}


	ntg_error_code CModuleManager::install_embedded_module( const GUID &module_id )
	{
		const ntg_interface *interface;
		
		interface = get_interface_by_module_id( module_id );
		if( !interface )
		{
			NTG_TRACE_ERROR( "Can't find interface" );
			return NTG_ERROR;
		}

		if( interface->module_source != NTG_MODULE_EMBEDDED )
		{
			NTG_TRACE_ERROR( "Module isn't embedded" );
			return NTG_ERROR;
		}

		return change_module_source( ( ntg_interface & ) *interface, NTG_MODULE_3RD_PARTY );
	}

	ntg_error_code CModuleManager::uninstall_module( const GUID &module_id, CModuleUninstallResult &result )
	{
		ntg_error_code error_code = NTG_NO_ERROR;

		result.remains_as_embedded = false;

		ntg_interface *interface = ( ntg_interface * ) get_interface_by_module_id( module_id );
		if( !interface )
		{
			NTG_TRACE_ERROR( "Can't find interface" );
			return NTG_ERROR;
		}

		if( interface->module_source != NTG_MODULE_3RD_PARTY )
		{
			NTG_TRACE_ERROR( "Can't uninstall module - it is not a 3rd party module" );
			return NTG_ERROR;
		}

		if( is_module_in_use( server_->root_nodes, module_id ) )
		{
			result.remains_as_embedded = true;
			return change_module_source( *interface, NTG_MODULE_EMBEDDED );
		}

		result.remains_as_embedded = false;

		error_code = ntg_delete_file( interface->file_path );
		if( error_code != NTG_NO_ERROR )
		{
			return error_code;
		}

		unload_module( interface );
		return NTG_NO_ERROR;
	}

	ntg_error_code CModuleManager::load_module_in_development( const string &module_file, CLoadModuleInDevelopmentResult &result )
	{
		for( map_guid_to_interface::const_iterator i = m_module_id_map.begin(); i != m_module_id_map.end(); i++ )
		{
			ntg_interface *interface = i->second;

			if( interface->module_source != NTG_MODULE_IN_DEVELOPMENT )
			{
				continue;
			}

			if( ntg_guid_is_null( &result.previous_module_id ) )
			{
				result.previous_module_id = interface->module_guid;

				if( is_module_in_use( server_->root_nodes, interface->module_guid ) )
				{
					change_module_source( *interface, NTG_MODULE_EMBEDDED );
					result.previous_remains_as_embedded = true;
				}
				else
				{
					unload_module( interface );
				}
			}
			else
			{
				NTG_TRACE_ERROR( "Encountered more than one in-development module!" );
				return NTG_FAILED;
			}
		}

		return NTG_NO_ERROR;
	}

	
	const guid_set &CModuleManager::get_all_module_ids() const
	{
		return m_module_ids;
	}


	const ntg_interface *CModuleManager::get_interface_by_module_id( const GUID &id ) const
	{
		map_guid_to_interface::const_iterator lookup = m_module_id_map.find( id );
		if( lookup == m_module_id_map.end() ) 
		{
			return NULL;
		}
		else
		{
			return lookup->second;
		}
	}


	const ntg_interface *CModuleManager::get_interface_by_origin_id( const GUID &id ) const
	{
		map_guid_to_interface::const_iterator lookup = m_origin_id_map.find( id );
		if( lookup == m_origin_id_map.end() ) 
		{
			return NULL;
		}
		else
		{
			return lookup->second;
		}
	}


	const ntg_interface *CModuleManager::get_core_interface_by_name( const string &name ) const
	{
		map_string_to_interface::const_iterator lookup = m_core_name_map.find( name );
		if( lookup == m_core_name_map.end() ) 
		{
			return NULL;
		}
		else
		{
			return lookup->second;
		}
	}


	string CModuleManager::get_unique_interface_name( const ntg_interface &interface ) const
	{
		char *module_guid = ntg_guid_to_string( &interface.module_guid );

		ostringstream unique_name;
		unique_name << interface.info->name << "-" << module_guid;

		delete[] module_guid;

		return unique_name.str();
	}


	string CModuleManager::get_patch_path( const ntg_interface &interface ) const
	{
		const string patch_extension = ".pd";

		assert( interface.implementation && interface.implementation->patch_name );

		string implementation_path = get_implementation_path( interface ) + interface.implementation->patch_name;

		/* chop off patch extension */
		int implementation_path_length = implementation_path.length() - patch_extension.length();
		if( implementation_path_length <= 0 || implementation_path.substr( implementation_path_length ) != patch_extension )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Implementation path doesn't end in correct patch extension", implementation_path.c_str() );
			return NULL;
		}

		return implementation_path.substr( 0, implementation_path_length );
	}


	void CModuleManager::get_orphaned_embedded_modules( const node_map &search_nodes, guid_set &results ) const
	{
		/* first pass - collect ids of all embedded modules */
		for( map_guid_to_interface::const_iterator i = m_module_id_map.begin(); i != m_module_id_map.end(); i++ )
		{
			const ntg_interface *interface = i->second;

			if( interface->module_source == NTG_MODULE_EMBEDDED )
			{
				results.insert( interface->module_guid );
			}
		}

		/* second pass - walk node tree pruning any modules still in use */
		remove_in_use_module_ids_from_set( search_nodes, results );
	}


	void CModuleManager::unload_modules( const guid_set &module_ids )
	{
		for( guid_set::const_iterator i = module_ids.begin(); i != module_ids.end(); i++ )
		{
			ntg_interface *interface = ( ntg_interface * ) get_interface_by_module_id( *i );
			assert( interface );

			unload_module( interface );
		}
	}


	ntg_error_code CModuleManager::interpret_legacy_module_id( ntg_id old_id, GUID &output ) const
	{
		if( !m_legacy_module_id_table || old_id >= m_legacy_module_id_table_elems )
		{
			NTG_TRACE_ERROR_WITH_INT( "Can't interpret class id", old_id );
			return NTG_ERROR;
		}

		output = m_legacy_module_id_table[ old_id ];

		return ntg_guid_is_null( &output ) ? NTG_ERROR : NTG_NO_ERROR;
	}


	void CModuleManager::load_modules_from_directory( const string &module_directory, ntg_module_source module_source )
	{
		DIR *directory_stream;
		struct dirent *directory_entry;
		const char *name;
		struct stat entry_data;
		GUID module_guid;

		directory_stream = opendir( module_directory.c_str() );
		if( !directory_stream )
		{
			NTG_TRACE_ERROR_WITH_STRING( "unable to open directory", module_directory.c_str() );
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

			string full_path = module_directory + NTG_PATH_SEPARATOR + name;

			if( stat( full_path.c_str(), &entry_data ) != 0 )
			{
				NTG_TRACE_ERROR_WITH_ERRNO( "couldn't read directory entry data" );
				continue;
			}

			switch( entry_data.st_mode & _S_IFMT )
			{
				case S_IFDIR:	/* directory */
					continue;

				default:
					load_module( full_path, module_source, module_guid );
					break;
			}
		}
	}


	void CModuleManager::load_legacy_module_id_file()
	{
		char line[ NTG_LONG_STRLEN ];
		FILE *file = NULL;
		const char *guid_as_string;
		ntg_id old_id;
		GUID guid;

		m_legacy_module_id_table = NULL;
		m_legacy_module_id_table_elems = 0;

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

			if( old_id >= m_legacy_module_id_table_elems )
			{
				int new_table_size = old_id + 1;
				GUID *new_legacy_module_id_table = new GUID[ new_table_size ];

				memcpy( new_legacy_module_id_table, m_legacy_module_id_table, m_legacy_module_id_table_elems * sizeof( GUID ) );
				memset( new_legacy_module_id_table + m_legacy_module_id_table_elems, 0, ( new_table_size - m_legacy_module_id_table_elems ) * sizeof( GUID ) );

				delete m_legacy_module_id_table;
				m_legacy_module_id_table = new_legacy_module_id_table;
				m_legacy_module_id_table_elems = new_table_size;
			}

			m_legacy_module_id_table[ old_id ] = guid;
		}

		fclose( file );
	}


	/* 
	 CModuleManager::load_module only returns true if the module isn't already loaded
	 however, it stores the id of the loaded module in module_guid regardless of whether the module was already loaded
	*/

	bool CModuleManager::load_module( const string &filename, ntg_module_source module_source, GUID &module_guid )
	{
		unzFile unzip_file;
		ntg_interface *interface = NULL;
		unsigned int checksum = 0;

		ntg_guid_set_null( &module_guid );

		unzip_file = unzOpen( filename.c_str() );
		if( !unzip_file )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Unable to open zip", filename.c_str() );
			return false;
		}

		interface = load_interface( unzip_file );
		if( !interface ) 
		{
			NTG_TRACE_ERROR_WITH_STRING( "Failed to load interface", filename.c_str() );
			unzClose( unzip_file );
			return false;
		}

		module_guid = interface->module_guid;

		if( m_module_id_map.count( interface->module_guid ) > 0 )
		{
			NTG_TRACE_VERBOSE_WITH_STRING( "Module already loaded", interface->info->name );
			ntg_interface_free( interface );
			unzClose( unzip_file );
			return false;
		}

		if( interface->info->implemented_in_libintegra && module_source != NTG_MODULE_SHIPPED_WITH_INTEGRA )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Attempt to load 'implemented in libintegra' module as 3rd party or embedded", interface->info->name )
			ntg_interface_free( interface );
			unzClose( unzip_file );
			return false;
		}

		interface->file_path = ntg_strdup( filename.c_str() );
		interface->module_source = module_source;

		m_module_id_map[ interface->module_guid ] = interface;

		if( m_origin_id_map.count( interface->origin_guid ) > 0 )
		{
			NTG_TRACE_VERBOSE_WITH_STRING( "Two modules with same origin!  Leaving original in origin->interface table", interface->info->name );
		}
		else
		{
			m_origin_id_map[ interface->origin_guid ] = interface;
		}

		if( ntg_interface_is_core( interface ) )
		{
			if( m_core_name_map.count( interface->info->name ) > 0 )
			{
				NTG_TRACE_VERBOSE_WITH_STRING( "Two core modules with same name!  Leaving original in name->interface table", interface->info->name );
			}
			else
			{
				m_core_name_map[ interface->info->name ] = interface;
			}
		}
	
		m_module_ids.insert( interface->module_guid );

		if( ntg_interface_has_implementation( interface ) )
		{
			extract_implementation( unzip_file, *interface, checksum );

			assert( interface && interface->implementation );
			interface->implementation->checksum = checksum;
		}

		unzClose( unzip_file );

		return true;
	}


	void CModuleManager::unload_all_modules()
	{
		/* take a copy, as the original will change as we delete */
		guid_set module_ids( m_module_ids );

		for( guid_set::const_iterator i = module_ids.begin(); i != module_ids.end(); i++ )
		{
			ntg_interface *interface = ( ntg_interface * ) get_interface_by_module_id( *i );
			assert( interface );

			unload_module( interface );
		}

		assert( m_module_ids.empty() );
		assert( m_module_id_map.empty() );
		assert( m_origin_id_map.empty() );
		assert( m_core_name_map.empty() );
	}


	ntg_interface *CModuleManager::load_interface( unzFile unzip_file )
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
		buffer = new unsigned char[ buffer_size ];

		if( unzReadCurrentFile( unzip_file, buffer, buffer_size ) != buffer_size )
		{
			NTG_TRACE_ERROR( "Unable to read " NTG_IDD_FILE_NAME );
			delete[] buffer;
			return NULL;
		}

		interface = ntg_interface_load( buffer, buffer_size );
		delete[] buffer;

		return interface;
	}


	ntg_error_code CModuleManager::extract_implementation( unzFile unzip_file, const ntg_interface &interface, unsigned int &checksum )
	{
		unz_file_info file_info;
		char file_name[ NTG_LONG_STRLEN ];
		const char *relative_file_path;
		unsigned char *output_buffer;
		FILE *output_file;

		assert( unzip_file );

		checksum = 0;

		string implementation_directory = get_implementation_path( interface );

		if( ntg_is_directory( implementation_directory.c_str() ) )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Can't extract module implementation - target directory already exists", implementation_directory.c_str() );
			return NTG_FAILED;
		}

		mkdir( implementation_directory.c_str() );

		if( unzGoToFirstFile( unzip_file ) != UNZ_OK )
		{
			NTG_TRACE_ERROR( "Couldn't iterate contents" );
			return NTG_FAILED;
		}

		do
		{
			if( unzGetCurrentFileInfo( unzip_file, &file_info, file_name, NTG_LONG_STRLEN, NULL, 0, NULL, 0 ) != UNZ_OK )
			{
				NTG_TRACE_ERROR( "Couldn't extract file info" );
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

			ntg_construct_subdirectories( implementation_directory.c_str(), relative_file_path );

			string target_path = implementation_directory + relative_file_path;

			checksum ^= MurmurHash2( relative_file_path, strlen( relative_file_path ), NTG_CHECKSUM_SEED );

			if( unzOpenCurrentFile( unzip_file ) == UNZ_OK )
			{
				output_file = fopen( target_path.c_str(), "wb" );
				if( output_file )
				{
					output_buffer = new unsigned char[ file_info.uncompressed_size ];

					if( unzReadCurrentFile( unzip_file, output_buffer, file_info.uncompressed_size ) != file_info.uncompressed_size )
					{
						NTG_TRACE_ERROR_WITH_STRING( "Error decompressing file", file_name );
					}
					else
					{
						checksum ^= MurmurHash2( output_buffer, file_info.uncompressed_size, NTG_CHECKSUM_SEED );

						fwrite( output_buffer, 1, file_info.uncompressed_size, output_file );
					}

					delete[] output_buffer;

					fclose( output_file );
				}
				else
				{
					NTG_TRACE_ERROR_WITH_STRING( "Couldn't write to implementation file", target_path.c_str() );
				}

				unzCloseCurrentFile( unzip_file );
			}
			else
			{
				NTG_TRACE_ERROR_WITH_STRING( "couldn't open zip contents", file_name );
			}
		}
		while( unzGoToNextFile( unzip_file ) != UNZ_END_OF_LIST_OF_FILE );

		return NTG_NO_ERROR;
	}


	void CModuleManager::unload_module( ntg_interface *interface )
	{
		assert( interface );

		if( ntg_interface_has_implementation( interface ) )
		{
			delete_implementation( *interface );
		}

		if( interface->module_source == NTG_MODULE_EMBEDDED )
		{
			ntg_delete_file( interface->file_path );
		}

		m_module_id_map.erase( interface->module_guid );

		/* only remove origin id keys if the entry points to this interface */
		map_guid_to_interface::const_iterator lookup = m_origin_id_map.find( interface->origin_guid );
		if( lookup != m_origin_id_map.end() )
		{
			if( lookup->second == interface )
			{
				m_origin_id_map.erase( interface->origin_guid );
			}
		}

		if( ntg_interface_is_core( interface ) )
		{
			/* only remove from core name map if the entry points to this interface */
			assert( m_core_name_map.count( interface->info->name ) > 0 );
			if( m_core_name_map.at( interface->info->name ) == interface )
			{
				m_core_name_map.erase( interface->info->name );
			}
		}

		/* remove from id set */
		m_module_ids.erase( interface->module_guid );

		ntg_interface_free( interface );
	}


	string CModuleManager::get_implementation_path( const ntg_interface &interface ) const
	{
		return m_implementation_directory_root + get_implementation_directory_name( interface );
	}


	string CModuleManager::get_implementation_directory_name( const ntg_interface &interface ) const
	{
		return get_unique_interface_name( interface ) + NTG_PATH_SEPARATOR;
	}


	void CModuleManager::delete_implementation( const ntg_interface &interface )
	{
		ntg_delete_directory( get_implementation_path( interface ).c_str() );
	}


	ntg_error_code CModuleManager::store_module( const GUID &module_id )
	{
		ntg_interface *interface;
		ntg_error_code error_code;

		interface = ( ntg_interface * ) get_interface_by_module_id( module_id );
		if( !interface )
		{
			NTG_TRACE_ERROR( "failed to lookup interface" );
			return NTG_ERROR;
		}

		if( !interface->file_path )
		{
			NTG_TRACE_ERROR( "Unknown interface file path" );
			return NTG_ERROR;
		}

		string module_storage_path = get_storage_path( *interface );
		if( module_storage_path.empty() )
		{
			NTG_TRACE_ERROR( "failed to get storage path" );
			return NTG_ERROR;
		}

		error_code = ntg_copy_file( interface->file_path, module_storage_path.c_str() );
		if( error_code != NTG_NO_ERROR )
		{
			return error_code;
		}

		delete[] interface->file_path;
		interface->file_path = strdup( module_storage_path.c_str() );

		return NTG_NO_ERROR;
	}


	string CModuleManager::get_storage_path( const ntg_interface &interface ) const
	{
		string storage_directory;

		switch( interface.module_source )
		{
			case NTG_MODULE_3RD_PARTY:
				storage_directory = m_third_party_module_directory;
				break;

			case NTG_MODULE_EMBEDDED:
				storage_directory = m_embedded_module_directory; 
				break;

			case NTG_MODULE_SHIPPED_WITH_INTEGRA:
			case NTG_MODULE_IN_DEVELOPMENT:
			default:
				NTG_TRACE_ERROR( "Unexpected module source" );
				return string();
		}

		string unique_name = get_unique_interface_name( interface );

		return storage_directory + unique_name + "." + NTG_MODULE_SUFFIX;
	}


	ntg_error_code CModuleManager::change_module_source( ntg_interface &interface, ntg_module_source new_source )
	{
		/* sanity checks */
		if( interface.module_source == NTG_MODULE_SHIPPED_WITH_INTEGRA || new_source == NTG_MODULE_SHIPPED_WITH_INTEGRA )
		{
			return NTG_ERROR;
		}

		if( interface.module_source == new_source )
		{
			return NTG_ERROR;
		}

		interface.module_source = new_source;

		string new_file_path = get_storage_path( interface );
		if( new_file_path.empty() )
		{
			return NTG_FAILED;			
		}

		rename( interface.file_path, new_file_path.c_str() );

		delete[] interface.file_path;
		interface.file_path = strdup( new_file_path.c_str() );
	
		return NTG_NO_ERROR;
	}


	bool CModuleManager::is_module_in_use( const ntg_internal::node_map &search_nodes, const GUID &module_id ) const
	{
		for( node_map::const_iterator i = search_nodes.begin(); i != search_nodes.end(); i++ )
		{
			const CNode *node = i->second;

			if( ntg_guids_are_equal( &node->get_interface()->module_guid, &module_id ) )
			{
				return true;
			}

			if( is_module_in_use( node->get_children(), module_id ) )
			{
				return true;
			}
		}

		return false;
	}


	void CModuleManager::remove_in_use_module_ids_from_set( const node_map &search_nodes, ntg_api::guid_set &set ) const
	{
		for( node_map::const_iterator i = search_nodes.begin(); i != search_nodes.end(); i++ )
		{
			const CNode *node = i->second;
			
			set.erase( node->get_interface()->module_guid );

			remove_in_use_module_ids_from_set( node->get_children(), set );
		}
	}

}


