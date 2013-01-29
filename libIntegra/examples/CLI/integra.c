#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <readline/readline.h>
#include <readline/history.h>

#include "Integra/integra.h"

#define MAX_LINE_LENGTH 1024
#define MAX_WORD_LENGTH 100

#define WELCOME_MSG "  Welcome to the Integra command line interface.\n\n  Interface with the Integra library by issueing commands on the prompt.\n  Type 'help' at any time to get a list of available commands.\n\n"
#define PROMPT "> "
#define INDENT "  "
#define GOODBYE_MSG "  Thanks for using the Integra command line interface.\n  Exiting gracefully.\n\n"
#define CLASSLIST_MSG "  Getting a list of available classes from the server.\n\n"
#define CLASSLIST_MSG_FOUND_CLASSES "  The following classes are available on the server:\n\n"
#define SERVER_SET_MSG " "
#define SERVER_NOT_RUNNING "  The server is not initiated.\n  Try starting the server first by typing \'start\' at the prompt.\n\n"


#define OPTARGS_CHECK_GET(wrong,right) lokke==argc-1?(fprintf(stderr,"Must supply argument for '%s'\n",argv[lokke]),exit(-4),wrong):right
#define OPTARGS_BEGIN(das_usage) {int lokke;const char *usage=das_usage;for(lokke=1;lokke<argc;lokke++){char *a=argv[lokke];if(!strcmp("--help",a)||!strcmp("-h",a)){fprintf(stderr,usage);exit(0);
#define OPTARG(name,name2) }}else if(!strcmp(name,a)||!strcmp(name2,a)){{
#define OPTARG_GETINT() OPTARGS_CHECK_GET(0,atoi(argv[++lokke]))
/*int optargs_inttemp; */
/*#define OPTARG_GETINT() OPTARGS_CHECK_GET(0,(optargs_inttemp=strtol(argv[++lokke],(char**)NULL,10),errno!=0?(perror("strtol"),0):optargs_inttemp)) */
#define OPTARG_GETFLOAT() OPTARGS_CHECK_GET(0.0f,atof(argv[++lokke]))
#define OPTARG_GETSTRING() OPTARGS_CHECK_GET("",argv[++lokke])
#define OPTARG_LAST() }}else if(lokke==argc-1 && argv[lokke][0]!='-'){lokke--;{
#define OPTARGS_ELSE() }else if(1){
#define OPTARGS_END }else{fprintf(stderr,usage);exit(-1);}}}

/* A static variable for holding the line. */
static char *line = NULL;

/* Variables used by -e arguments */
int eval_lines_pos=0;
int num_eval_lines=0;
char *eval_lines[1024];


/* Read a string, and return a pointer to it.
   Returns NULL on EOF. */
char *rl_gets(){
    do{
      free(line);

      if(num_eval_lines==eval_lines_pos)
        line = readline(PROMPT);  /* Get a line from the user. */
      else{
        line = strdup(eval_lines[eval_lines_pos++]);
      }
      if(line==NULL)
        return NULL;
    }while(!strcmp(line,""));

    add_history (line);

    return (line);
}

void start_server(const char *bridge_file){
  ntg_server_run(bridge_file, 8000, 8001, NULL, 8002);
}

int main(int argc, char **argv)
{
    const char          *bridge_file    = "integra_osc_bridge.so";
    const char *control_words[]         = {"help", "start", "stop", "kill", "classlist", "set", "get", "classinfo", "new", "state", "lua", "exit"};
    const char *available_bridges[]     = {"integra_dummy_bridge.so", "integra_pd_bridge.so", "integra_osc_bridge.so", "integra_max_bridge.so"}; 
    char                *input, *address_value, *address, *class_description, *class, *instance, *parent;
    char                *input_arg;
    char               **classes;
    int                  run            = 0;
    int                  sscanf_result  = 0;
    int                  address_argc   = 0;
    int                  server_running = 0;
    int                  i              = 0, j = 0;
    int                  control_length = 0;
    int                  is_equal       = 0;
    int                  int_value      = 0;
    double               float_value    = 0;
    char                *char_value     = 0;
    /*const char *space_delim           = " "; */
    ntg_path            *param_address  = NULL, *root = NULL;
    /*ntg_path *default_path            = NULL; */
    ntg_value           *param_value    = NULL;
    ntg_command_status   cmd_status;
    ntg_info           *class_def      = NULL;

    /*ntg_bridge_callback bridge_callback = 0; */
    ntg_list            *classlist      = NULL;
    
    input          = malloc(sizeof(char) * MAX_WORD_LENGTH);
    input_arg      = malloc(sizeof(char) * MAX_LINE_LENGTH);
    control_length = sizeof(control_words) / sizeof(char *);

    OPTARGS_BEGIN("\n"
                  "integra [--start-server] [--eval stuff] [--file file]\n"
                  "        [ -s           ] [ -e    stuff] [ -f    file]\n"
                  "\n"
                  "-e may be used more than once. Example:\n"
                  "./integra -s -e 'new Delay' -e state"
                  "\n"
                  )
      {
        OPTARG("--start-server","-s"){
          if(server_running == 0){
            start_server(bridge_file);
            server_running = 1;
            printf("Server is running\n");
          }
        }
        OPTARG("--eval","-e") eval_lines[num_eval_lines++] = OPTARG_GETSTRING();
        OPTARG("--file","-f"){
          FILE *file=fopen(OPTARG_GETSTRING(),"r");
          while(true){
            char *line=malloc(256);
            if(fgets(line,254,file)==NULL){
              fclose(file);
              break;
            }
            eval_lines[num_eval_lines++]=line;
          }
        }
      }OPTARGS_END;


    printf (WELCOME_MSG);

    while(run > -1){

        errno = 0;

        /* Reset the run variable */
        run = 0; 
        /* Reset the input_arg variable. */
        memset(input_arg, 0, sizeof(char) * MAX_LINE_LENGTH);

        /* Get input from the command line using --eval or --file, or from the CL */
        rl_gets();

        if(line==NULL){
          run=12;
        }else{
          /* Retrieve the control message and the argument resopectively. */
          sscanf_result = sscanf (line, "%[a-z] %[A-Za-z]", input, input_arg);
          /* Find a match in the list of controlp words. */
          for(j=0; j<control_length; j++) {
            is_equal = strncmp(input, control_words[j], MAX_WORD_LENGTH);
            if(is_equal == 0) {
              run = j + 1;
              break;
            }
          }
        }


        /* Take action according to input command. */
        switch (run)
        {
            case 0: /* no match */
                printf ("%s is not an Integra command.\n", input);
                printf ("No matching input.\n");
                break;
            case 1: /* help */
                for(i = 1; i < control_length; i++) {
                    printf("  %s\n", control_words[i]);
                }
                break;
            case 2: /* start */
                printf("  Attempting to start the Integra server...\n");
                if(sscanf_result > 1) {
                    for(i = 0; i < sizeof(available_bridges) / sizeof(char *); i++) {
                        if(strstr(available_bridges[i], input_arg) != NULL) {
                            bridge_file = available_bridges[i];
                            printf("  Starting the server with the %s\n", bridge_file);
                            break;
                        }
                    }
                }
                start_server(bridge_file);
                server_running = 1;
                printf("Server is running\n");
                break;
            case 3: /* stop */
                printf(GOODBYE_MSG);
                if(server_running) {
                    /* shutdown server */
                    ntg_terminate();
                    run = -1;
                }
                run = -1;
                break;
            case 4: /* kill */
                printf(GOODBYE_MSG);
                if(server_running) {
                    /* shutdown server */
                    ntg_terminate();
                    run = -1;
                }
                run = -1;
                break;
            case 5: /* classlist */
                if(server_running) {
                    printf(CLASSLIST_MSG);
                        classlist = ntg_classlist();
                        if(classlist != NULL) {
                            printf(CLASSLIST_MSG_FOUND_CLASSES);
                            classes = ntg_classlist_get_names(classlist);
                            for(i=0; i<ntg_list_get_n_elems(classlist); i++) {
                                printf("    %s\n", classes[i]);
                            }
                        }
                        else {
                            printf("  No classes are available. Is the server running?\n");
                        }
                    break;
                } else {
                    printf(SERVER_NOT_RUNNING);
                    break;
                }
            case 6: /* set */
                printf(SERVER_SET_MSG);
                /* Server is not initiated. */
                if(server_running == 0) {
                    printf(SERVER_NOT_RUNNING);
                    break;
                }
                /* Server is running. */
                /* No argument = no address/value given. */
                if(sscanf_result < 1) {
                    printf("  Please add an address and a value to your command:\n\n");
                    printf("  set module.attribute value\n\n");
                    /* break; */
                }
                address_value = line + 4;
                printf("Address_value: %s\n", address_value);

                address = malloc(sizeof(char) * (strlen(address_value)));
                char_value = malloc(sizeof(char) * (strlen(address_value)));

                address_argc = sscanf(address_value, "%s %s", address, char_value);
                
                param_address = ntg_path_from_string(address);

                /* Is digit? */
                if(isdigit(char_value[0]) != 0) {
                    /* Is char_value a float? */
                    if(strchr(char_value, '.')) {
                        float_value = atof(char_value);
                        param_value = ntg_value_new(NTG_FLOAT, &float_value);
                    } else {
                        /* char_value is an integer */
                        int_value = atoi(char_value);
                        param_value = ntg_value_new(NTG_INTEGER, &int_value);
                    }
                } else {
                    /* char_value is a blob or a string. Ignoring blob... */
                    param_value = ntg_value_new(NTG_STRING, char_value);
                }
                    ntg_set(param_address, param_value, true);
                free(address);
                free(char_value);
                break;
            case 7: /* get */
                if(server_running == 0) {
                     printf(SERVER_NOT_RUNNING);
                     break;
                }
                if(sscanf_result < 1) {
                    printf("  Please supply the full address for which the value is requested:\n\n  get FooBar.volume\n\n");
                    break;
                }
                break;
            case 8: /* classinfo */
                /* printf("Input_arg: %s\n", input_arg); */
                if(server_running == 0) {
                     printf(SERVER_NOT_RUNNING);
                     break;
                }
                if(sscanf_result < 1) {
                    printf("  Please supply the class name for which information is requested:\n\n  classinfo FooBar\n\n");
                    break;
                }
                    class_def = ntg_classinfo((const char *)input_arg);
                    class_description = 
                        ntg_info_get_description(class_def);
                printf("  %s:\n\n  %s\n\n", input_arg, class_description);                      
                break;
            case 9: /* new */
                address_argc = 0;
                if(server_running == 0) {
                     printf(SERVER_NOT_RUNNING);
                     break;
                }
                if(sscanf_result < 1) {
                    printf("  Please supply the class name you wish to load:\n\n  new FooBar [instance-name] [parent]\n\n");
                    break;
                }
                class        = malloc(sizeof(char) *   strlen(line) - strlen(input));
                instance     = malloc(sizeof(char) *   strlen(line) - strlen(input));
                parent       = malloc(sizeof(char) *   strlen(line) - strlen(input));
                address_argc = sscanf(line, "%[A-Za-z] %[A-Za-z] %[A-Za-z] %[A-Za-z]", input, class, instance, parent);
                if(address_argc == 2) {
                    free(instance);
                    free(parent);
                    instance = NULL;
                    parent = NULL;
                }
                if(address_argc == 3) {
                    free(parent);
                    parent = NULL;
                }
                    root = ntg_path_new();
                    cmd_status = ntg_new(class, instance, root);
                break;
        case 10:
          if(server_running == 0) {
            printf(SERVER_NOT_RUNNING);
            break;
          }
          {
              ntg_print_state();
            break;
          }
        case 11:
          if(server_running == 0) {
            printf(SERVER_NOT_RUNNING);
            break;
          }
          if(strlen(line)>4){
              ntg_lua_eval(ntg_path_new(),&line[4]);
          }
          break;
        case 12:
          exit(0);
        default: 
          break;
        }
    }
    free(input);
    free(input_arg);
    free(line);
    return 0;
}
