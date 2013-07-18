
/* run the server indefinitely with an osc bridge */

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <assert.h>
#include <string.h>

#include "src/platform_specifics.h"

#include "Integra/integra.h"
#include "src/trace.h"

#include "close_orphaned_processes.h"

#ifdef _WINDOWS
#include <windows.h>
/* disable warnings about deprecated string functions */
#pragma warning(disable : 4996)
#define PATH_SEPARATOR '\\'
#else
#include <signal.h> /* for kill() */
#include "spawn_.h"
#define _spawnv spawnv
#define PATH_SEPARATOR '/'
#endif


#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#define MAXIMUM_ARGUMENTS ( 50 )
#define NUMBER_OF_PROCESSES_TO_CLOSE ( 2 )


const char *base_name(const char *pathname)
{
    const char *lastsep = strrchr(pathname, PATH_SEPARATOR);
    return lastsep ? lastsep+1 : pathname;
}


int count_arguments( const char **arguments )
{
    int number_of_arguments;
    for( number_of_arguments = 0; number_of_arguments < MAXIMUM_ARGUMENTS; number_of_arguments++ )
    {
        if( arguments[ number_of_arguments ] == NULL )
        {
            return number_of_arguments;
        }
    }

    return number_of_arguments;
}

void write_pid_to_file( const char *path )
{
    FILE *file = fopen(path, "w");
    char buf[10];

    sprintf(buf, "%d", getpid());
    fputs(buf, file);
    fclose(file);
}

unsigned int read_pid_from_file( const char *path )
{
    FILE *file = fopen(path, "r");
    char buf[10];
    int pid = 0;

    if(file == NULL)
    {
        return 0;
    }

    fgets(buf, 10, file);
    fclose(file);

    pid = (int)strtol(buf, NULL, 10);

    return pid;
}

void append_argument( const char **arguments, const char *argument )
{
    int number_of_arguments = count_arguments( arguments );

    if( number_of_arguments >= MAXIMUM_ARGUMENTS )
    {
        NTG_TRACE_ERROR("too many host arguments" );
        return;
    }

    arguments[ number_of_arguments ] = argument;
    arguments[ number_of_arguments + 1 ] = NULL;
}


void prepend_argument( const char **arguments, const char *argument )
{
    int number_of_arguments = count_arguments( arguments );
    int i = 0;

    if( number_of_arguments >= MAXIMUM_ARGUMENTS )
    {
        NTG_TRACE_ERROR("too many host arguments" );
        return;
    }

    for( i = number_of_arguments; i >= 0; i-- )
    {
        arguments[ i + 1 ] = arguments[ i ];
    }

    arguments[ 0 ] = argument;
}

void post_command_line_options(const char *command_name) 
{
    printf("Usage: %s [OPTION]...\nTry `%s -help for more information.\n",
            command_name, command_name);

}

void post_help(const char *command_name) {

    printf(
            "Usage: %s [OPTION]...\n"
            "Run the Integra server until terminated\n"
            "Example: %s -bridge=../integra_osc_bridge.so -host ../bin/pd\n"

            "\nBridge, Interface and Host options:\n"
            "  -bridge=[string]\t\tpath of server->host bridge\n"
            "  -system_modules=[string]\t\tlocation of system-installed .integra-module files\n"
            "  -third_party_modules=[string]\t\tlocation of third-party .integra-module files\n"
            "  -host=[string]\t\tpath of host executable\n"
            "  -hostargs\t\t\targuments are passed into the host\n"

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

int main( int argc, char *argv[] )
{
    const char *command_name = NULL;
    const char *bridge_path = NULL;
	const char *system_module_directory = NULL;
	const char *third_party_module_directory = NULL;
    const char *host_path = NULL;
    const char *host_arguments[ MAXIMUM_ARGUMENTS + 1 ];

    ntg_trace_category_bits trace_category_bits = NO_TRACE_CATEGORY_BITS;
    ntg_trace_options_bits trace_option_bits = NO_TRACE_OPTIONS_BITS;
    unsigned short xmlrpc_server_port = 0;
    const char *osc_client_url = NULL;
    unsigned short osc_client_port = 0;	
    unsigned short number_of_processes_to_close = 0;

    const char *process_names_to_close[ NUMBER_OF_PROCESSES_TO_CLOSE ];

    int host_process_handle = -1;
    int i = 0;
    const char *argument = NULL;
    const char *equals = NULL;
    int flag_length = 0;
    bool in_host_arguments = false;
    bool have_host_path = false;
    /* defaults */
    bool trace_errors = true;
    bool trace_progress = true;
    bool trace_verbose = false;

    host_arguments[ 0 ] = NULL;
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

        if( in_host_arguments )
        {
            append_argument( host_arguments, argument );
            continue;
        }

        equals = strchr( argument, '=' );
        if( equals != NULL )
        {
            flag_length = ( equals - argument );

            /*test for options with values here: */

            if( memcmp( argument, "-bridge", flag_length ) == 0 )
            {
                bridge_path = equals + 1;
                continue;
            }

			if( memcmp( argument, "-system_modules", flag_length ) == 0 )
			{
				system_module_directory = equals + 1;
				continue;
			}

			if( memcmp( argument, "-third_party_modules", flag_length ) == 0 )
			{
				third_party_module_directory = equals + 1;
				continue;
			}
			
			if( memcmp( argument, "-host", flag_length ) == 0 )
            {
                host_path = equals + 1;
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
                trace_errors = ( atoi(equals + 1) != 0 );
                continue;
            }

            if( memcmp( argument, "-trace_progress", flag_length ) == 0 )
            {
                trace_progress = ( atoi(equals + 1) != 0 );
                continue;
            }

            if( memcmp( argument, "-trace_verbose", flag_length ) == 0 )
            {
                trace_verbose = ( atoi(equals + 1) != 0 );
                continue;
            }
        }
        else
        {
            /*test for options without values here: */
            if( strcmp( argument, "-timestamp_trace" ) == 0 )
            {
                trace_option_bits = static_cast<ntg_trace_options_bits> ( trace_option_bits | TRACE_TIMESTAMP_BITS );
                continue;
            }

            if( strcmp( argument, "-locationstamp_trace" ) == 0 )
            {
                trace_option_bits = static_cast<ntg_trace_options_bits> ( trace_option_bits | TRACE_LOCATION_BITS );
                continue;
            }

            if( strcmp( argument, "-threadstamp_trace" ) == 0 )
            {
                trace_option_bits = static_cast<ntg_trace_options_bits> ( trace_option_bits | TRACE_THREADSTAMP_BITS );
                continue;
            }

            if( strcmp( argument, "-help" ) == 0 )
            {
                post_help(command_name);
                return 0;
            }

            if( strcmp( argument, "-hostargs" ) == 0 )
            {
                in_host_arguments = true;
                continue;
            }
        }
    }

    /*set the tracing settings */
    if( trace_errors ) trace_category_bits = static_cast<ntg_trace_category_bits>( trace_category_bits | TRACE_ERROR_BITS );
    if( trace_progress ) trace_category_bits = static_cast<ntg_trace_category_bits>( trace_category_bits | TRACE_PROGRESS_BITS );
    if( trace_verbose ) trace_category_bits = static_cast<ntg_trace_category_bits>( trace_category_bits | TRACE_VERBOSE_BITS );

    ntg_set_trace_options(trace_category_bits, trace_option_bits);

    /*close any processes that might be left over from a previous crash */
    NTG_TRACE_PROGRESS("closing orphaned processes");
    if( host_path != NULL && strlen( host_path ) > 0) 
	{
        have_host_path = true;
        number_of_processes_to_close = NUMBER_OF_PROCESSES_TO_CLOSE;
    } else 
	{
        number_of_processes_to_close = NUMBER_OF_PROCESSES_TO_CLOSE - 1;
    }

    process_names_to_close[ 0 ] = command_name;
    process_names_to_close[ 1 ] = host_path;
    close_orphaned_processes( process_names_to_close, number_of_processes_to_close );

    /*host's 0th argument should be it's own executable path */
    prepend_argument( host_arguments, host_path );


    /*start the host */
    if( have_host_path )
    {
        host_process_handle = _spawnv( P_NOWAIT, host_path, host_arguments );
        if( host_process_handle < 0 )
        {
            NTG_TRACE_ERROR_WITH_ERRNO("failed to start host: ");
        }
    }
    else
    {
        NTG_TRACE_ERROR("unable to start host - no path provided" );
    }

    /*run the server */
    ntg_server_run( bridge_path, system_module_directory, third_party_module_directory, 
					xmlrpc_server_port, osc_client_url, osc_client_port);

    if( host_process_handle > 0 )
    {
		NTG_TRACE_PROGRESS("shutting down host");
#ifdef _WINDOWS
        TerminateProcess( (HANDLE) host_process_handle, 0 );
#else
        kill( host_process_handle, SIGKILL );
#endif
    } 
	else 
	{
        NTG_TRACE_ERROR_WITH_INT( "couldn't kill host, PID was:", host_process_handle );
    }

    return 0;
}



