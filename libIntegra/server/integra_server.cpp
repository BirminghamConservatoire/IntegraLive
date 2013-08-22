/** IntegraServer - console app to expose xmlrpc interface to libIntegra
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


#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <assert.h>
#include <string.h>

#ifdef _WINDOWS
#pragma warning(disable : 4251)		/* disable warnings about exported classes which use stl */
#endif

#include "api/trace.h"
#include "api/server_startup_info.h"
#include "api/integra_session.h"
#include "api/server.h"
#include "api/value.h"
#include "api/path.h"

#include "close_orphaned_processes.h"
#include "xmlrpc_server.h"
#include "osc_client.h"

#include <pthread.h>

#ifdef _WINDOWS
//#include <windows.h>
//#pragma warning(disable : 4996)		/* disable warnings about deprecated string functions */
#define PATH_SEPARATOR '\\'
#else
#define PATH_SEPARATOR '/'
#endif


using namespace integra_api;


const char *base_name( const char *pathname )
{
    const char *lastsep = strrchr(pathname, PATH_SEPARATOR);
    return lastsep ? lastsep+1 : pathname;
}



void post_command_line_options( const char *command_name ) 
{
    printf( "Usage: %s [OPTION]...\nTry `%s -help for more information.\n", command_name, command_name );

}

void post_help( const char *command_name ) 
{
    printf(
            "Usage: %s [OPTION]...\n"
            "Run the Integra server until terminated\n"
			"Example: %s -system_modules=../system_modules -third_party_modules=../third_party_modules\n"

            "\nModule directory options:\n"
            "  -system_modules=[string]\t\tlocation of system-installed .module files\n"
            "  -third_party_modules=[string]\t\tlocation of third-party .module files\n"

            "\nNetwork port options:\n"
            "  -xmlrpc_server_port=[integer]\tlibIntegra xmlrpc port\n"
            "  -osc_client_url=[string]\tlibIntegra osc client url\n"
            "  -osc_client_port=[integer]\tlibIntegra osc client port\n"

            "\nTracing options:\n"
            "  -trace_errors=[0/1]\t\tlog errors to stdout\n"
            "  -trace_progress=[0/1]\t\tlog progress to stdout\n"
            "  -trace_verbose=[0/1]\t\tlog detailed progress to stdout\n"
            "  -timestamp_trace\t\tstamp tracing with date/time\n"
            "  -locationstamp_trace\t\tstamp tracing with filename, "
            "\n\t\t\t\tline number and function\n"
            "  -threadstamp_trace\t\tstamp tracing with thread id of caller\n"
            , command_name, command_name);

}


sem_t *create_semaphore( const string &name ) 
{
	#ifdef __APPLE__
		sem_t *semaphore = sem_open( name.c_str(), O_CREAT, 0777, 0 );
	#else
		sem_t *semaphore = new sem_t;
		sem_init( semaphore, 0, 0 );
	#endif

	return semaphore;
}


void destroy_semaphore( sem_t *semaphore ) 
{
	#ifdef __APPLE__
		sem_close( semaphore );
	#else
		sem_destroy( semaphore );
	#endif
}


int main( int argc, char *argv[] )
{
	CServerStartupInfo startup_info;

	const char *command_name = NULL;

	string osc_client_url;
	unsigned short osc_client_port = 0;

	unsigned short xmlrpc_server_port = 0;

    int i = 0;
    const char *argument = NULL;
    const char *equals = NULL;
    int flag_length = 0;

    /* defaults */
    bool trace_errors = true;
    bool trace_progress = true;
    bool trace_verbose = false;

	bool trace_timestamp = false;
	bool trace_location = false;
	bool trace_thread = false;

    command_name = base_name( argv[0] );

    if(argc == 1) 
    {
        post_command_line_options(command_name);
        return -1;
    }

    /*deal with commandline arguments */
    for( i = 1; i < argc; i++ )
    {
        argument = argv[ i ];

        equals = strchr( argument, '=' );
        if( equals != NULL )
        {
            flag_length = ( equals - argument );

            /*test for options with values here: */

			if( memcmp( argument, "-system_modules", flag_length ) == 0 )
			{
				startup_info.system_module_directory = equals + 1;
				continue;
			}

			if( memcmp( argument, "-third_party_modules", flag_length ) == 0 )
			{
				startup_info.third_party_module_directory = equals + 1;
				continue;
			}
			
            if( memcmp( argument, "-xmlrpc_server_port", flag_length ) == 0 )
            {
                xmlrpc_server_port = atoi( equals + 1 );
                continue;
            }

            if( memcmp( argument, "-osc_client_url", flag_length ) == 0 )
            {
                osc_client_url = equals + 1;
                continue;
            }

            if( memcmp( argument, "-osc_client_port", flag_length ) == 0 )
            {
                osc_client_port = atoi( equals + 1 );
                continue;
            }

            if( memcmp( argument, "-trace_errors", flag_length ) == 0 )
            {
                trace_errors = ( atoi( equals + 1 ) != 0 );
                continue;
            }

            if( memcmp( argument, "-trace_progress", flag_length ) == 0 )
            {
                trace_progress = ( atoi( equals + 1 ) != 0 );
                continue;
            }

            if( memcmp( argument, "-trace_verbose", flag_length ) == 0 )
            {
                trace_verbose = ( atoi( equals + 1 ) != 0 );
                continue;
            }
        }
        else
        {
            /*test for options without values here: */
            if( strcmp( argument, "-timestamp_trace" ) == 0 )
            {
				trace_timestamp = true;
                continue;
            }

            if( strcmp( argument, "-locationstamp_trace" ) == 0 )
            {
				trace_location = true;
                continue;
            }

            if( strcmp( argument, "-threadstamp_trace" ) == 0 )
            {
				trace_thread = true;
                continue;
            }

            if( strcmp( argument, "-help" ) == 0 )
            {
                post_help(command_name);
                return 0;
            }
        }
    }

	#ifdef _WINDOWS
		/*initialize windows socket API */
		WORD socket_api_version = MAKEWORD( 2, 2 );
		WSADATA socket_api_data;
		if( WSAStartup( socket_api_version, &socket_api_data ) != 0 )
		{
			INTEGRA_TRACE_ERROR << "Error starting windows socket API";
			return 0;
		}
	#endif

    /*set the tracing settings */
	CTrace::set_categories_to_trace( trace_errors, trace_progress, trace_verbose );
	CTrace::set_details_to_trace( trace_timestamp, trace_location, trace_thread );

    /*close any processes that might be left over from a previous crash */
    INTEGRA_TRACE_PROGRESS << "closing orphaned processes";

	std::list<std::string> process_names_to_close;
	process_names_to_close.push_back( command_name );
    close_orphaned_processes( process_names_to_close );

	/* start the osc client */
	COscClient *osc_client = new COscClient( osc_client_url, osc_client_port );
	startup_info.notification_sink = osc_client;

	/*start the integra session */
	CIntegraSession integra_session;
	CError error = integra_session.start_session( startup_info );
	if( error != CError::SUCCESS )
	{
		INTEGRA_TRACE_ERROR << "failed to start integra session: " << error.get_text();
	}
	else
	{
		sem_t *sem_xmlrpc_initialized = create_semaphore( "sem_xmlrpc_initialized" );
		sem_t *sem_system_shutdown = create_semaphore( "sem_system_shutdown" );

		pthread_t xmlrpc_thread;

		/* create the xmlrpc interface */
		INTEGRA_TRACE_PROGRESS << "creating xmlrpc interface...";
		CXmlRpcServerContext xmlrpc_context;
		xmlrpc_context.m_integra_session = &integra_session;
		xmlrpc_context.m_port = xmlrpc_server_port;
		xmlrpc_context.m_sem_initialized = sem_xmlrpc_initialized;
		xmlrpc_context.m_sem_shutdown = sem_system_shutdown;
		pthread_create( &xmlrpc_thread, NULL, ntg_xmlrpc_server_run, &xmlrpc_context );

		INTEGRA_TRACE_PROGRESS << "blocking until shutdown signal...";
		sem_wait( sem_system_shutdown );
		
		INTEGRA_TRACE_PROGRESS << "received shutdown signal...";

		ntg_xmlrpc_server_terminate( sem_xmlrpc_initialized );

		/* FIX: for now we only support the old 'stable' xmlrpc-c, which can't
		   wake up a sleeping server */
		pthread_join( xmlrpc_thread, NULL );

		INTEGRA_TRACE_PROGRESS << "XMLRPC interface closed";

		destroy_semaphore( sem_xmlrpc_initialized );
		destroy_semaphore( sem_system_shutdown );
		
		INTEGRA_TRACE_PROGRESS << "ending integra session...";

		integra_session.end_session();

		INTEGRA_TRACE_PROGRESS << "integra session ended";
	}

	/* stop the osc client */
	delete osc_client;

	#ifdef _WINDOWS
		/*cleanup windows socket API */
		WSACleanup();
	#endif

    return 0;
}



