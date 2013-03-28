/** libIntegra multimedia module interface
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

#ifdef HAVE_CONFIG_H
#    include <config.h>
#endif

#ifdef __gnu_linux__
#define _GNU_SOURCE
#endif

#include "platform_specifics.h"

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <dirent.h>
#include <ctype.h>
#include <assert.h>

#include "helper.h"
#include "globals.h"
#include "Integra/integra.h"

#ifdef _WINDOWS
#define NTG_MULTI_PATH_SEPARATOR ";"
#else
#define NTG_MULTI_PATH_SEPARATOR ":"
#endif

char *ntg_strdup(const char *string)
{
    if (string != NULL) {
      size_t len = strlen(string);
      char *newstring = ntg_malloc(len + 1);
      strncpy(newstring, string, len + 1);
      return newstring;
    } else {
        NTG_TRACE_ERROR("string is NULL");
    }
    return NULL;
}

char *ntg_substring_replace(char *str, char *orig, char *rep)
{
    char *buffer;
    char *p;

    buffer = ntg_malloc(1024 * sizeof(char));

    if(!(p = strstr(str, orig))){  /* Is 'orig' even in 'str'? */
        return str;
    }

    strncpy(buffer, str, p-str); /* Copy characters from 'str' start to 'orig' st$ */
    buffer[p-str] = '\0';

    sprintf(buffer+(p-str), "%s%s", rep, p+strlen(orig));

    buffer = ntg_realloc(buffer, strlen(buffer) + 1); /* shrink buffer to string */

    return buffer;
}

int ntg_count_digits(int num)
{

    int j = 0;

    if (!num)
        return 1;

    while (num) {

        j += 1;
        num /= 10;

    }

    return j;

}


int ntg_lower(char *str)
{

    int i = 0;

    while (str[i]) {
        str[i] = tolower(str[i]);
        i++;
    }

    return 0;
}

int ntg_upper(char *str)
{

    int i = 0;

    while (str[i]) {
        str[i] = toupper(str[i]);
        i++;
    }

    return 0;
}

/* dest must have been allocated with ntg_alloc, or be NULL */
char *ntg_string_append(char *dest, const char *source)
{
    if (source != NULL) {

        size_t source_length = strlen(source);
        size_t dest_length   = dest!=NULL?strlen(dest):0;
        size_t final_length  = dest_length + source_length;

        dest = ntg_realloc(dest, final_length + 1);

        if(dest_length) {
            strncat(dest, source, source_length);
        } else {
            strncpy(dest, source, source_length + 1);
        }
    }

    return dest;
}

char *ntg_string_join(const char *s1, const char *s2)
{
    size_t len_s1;
    size_t len_s2;
    size_t len;
    char *s;

    len_s1 = (s1 != NULL ? strlen(s1) : 0);
    len_s2 = (s2 != NULL ? strlen(s2) : 0);
    len    = len_s1 + len_s2;

    if (!len) {
        return NULL;
    }

    s = ntg_malloc(len + 1);

    strncpy(s, s1, len_s1 + 1);
    strncat(s, s2, len_s2);

    return s;

}

/* dest must have been allocated with ntg_alloc, or be NULL. */
static char *ntg_append_path(char *dest, const char *source)
{

    if (dest != NULL) {
      dest = ntg_realloc(dest, strlen(dest) +
              strlen(NTG_MULTI_PATH_SEPARATOR) + 1);
      strncat (dest, NTG_MULTI_PATH_SEPARATOR,
              strlen(NTG_MULTI_PATH_SEPARATOR));
    }

    return ntg_string_append(dest, source);
}

char *ntg_build_path_list(int envvars)
{
	char *paths = NULL, *env_var = NULL, *home = NULL, *temp = NULL;

	size_t temp_len = 0;
    size_t paths_length = 0;

	const int max_cwd_length = 1024;

    if (NTG_PATH & envvars) {

        env_var = getenv("PATH");

        paths = ntg_append_path(paths, env_var);

    }
    if (NTG_HOME & envvars) {

        env_var = getenv("HOME");

        paths = ntg_append_path(paths, env_var);

    }
    if (NTG_PWD & envvars) {

        env_var = getenv("PWD");

        paths = ntg_append_path(paths, env_var);


    }
    if (NTG_CWD & envvars) {

        env_var = ntg_malloc( max_cwd_length );

		if( getcwd( env_var, max_cwd_length ) != NULL )
		{
			paths = ntg_append_path(paths, env_var);
		}
		else
		{
            NTG_TRACE_ERROR_WITH_ERRNO("getcwd failed");
		}

		ntg_free( env_var );
    }
    if (NTG_LD_LIBRARY_PATH & envvars) {

        env_var = getenv("LD_LIBRARY_PATH");

        if (env_var == NULL)
          paths = ntg_append_path(paths, NTG_DEFAULT_LD_LIBRARY_PATH);
        else
          paths = ntg_append_path(paths, env_var);
    }
    if (NTG_XDG_DATA_DIRS & envvars) {

        env_var = getenv("XDG_DATA_DIRS");

        if (env_var == NULL)
          paths = ntg_append_path(paths, NTG_DEFAULT_XDG_DATA_DIRS_PATH);
        else
          paths = ntg_append_path(paths, env_var);

    }
    if (NTG_NTG_BRIDGE_PATH & envvars) {

        env_var = getenv("NTG_BRIDGE_PATH");

        if (env_var == NULL) {
          paths = ntg_append_path(paths,  NTG_DEFAULT_BRIDGE_PATH);
        } else {
          paths = ntg_append_path(paths, env_var);
        }

    }
    if (NTG_NTG_DEFS_PATH & envvars) {

        env_var = getenv("NTG_DEFS_PATH");

        if (env_var == NULL) {
          paths = ntg_append_path(paths, NTG_DEFAULT_DEFS_PATH);
        } else {
          paths = ntg_append_path(paths, env_var);
        }

    }
    if (NTG_NTG_USER_DIR & envvars) {

        env_var = getenv("NTG_USER_DIR");

        if (env_var == NULL && getenv("HOME") != NULL) {
            /* FIX! */
          temp_len = strlen(getenv("HOME")) + 1;
          home = ntg_malloc(temp_len * sizeof(char));
          strncpy(home, getenv("HOME"), temp_len);
          temp = ntg_string_append(home, NTG_DEFAULT_USER_DIR);
          paths = ntg_append_path(paths, temp);
          ntg_free(temp);
          ntg_free(home);
        }else
          paths = ntg_append_path(paths, env_var);

    }

    paths_length = strlen(paths);
    paths = ntg_realloc(paths, paths_length + 1);
    paths[paths_length] = '\0';

    return paths;

}


long ntg_file_length(FILE * file_handle)
{

    long file_length;

    fseek(file_handle, 0, SEEK_END);
    file_length = ftell(file_handle);
    fseek(file_handle, 0, SEEK_SET);

    return file_length;

}

char *ntg_file_find(const char *fn, int envvars)
{
    char *paths = NULL;
    char *path = NULL;
    char *cp = NULL;
    int access_rv = 0;
    size_t full_path_bytes;

	paths = ntg_build_path_list(envvars);

    NTG_TRACE_VERBOSE_WITH_STRING("Looking for file", fn);
    NTG_TRACE_VERBOSE_WITH_STRING("Using path list", paths);

    while ((path = strtok_r(paths, NTG_MULTI_PATH_SEPARATOR, &cp))) {

        char *full_path;

        paths = NULL;

        ntg_bashfilename(path, path);

        NTG_TRACE_VERBOSE_WITH_STRING("Looking in", path);

        full_path_bytes =
            strlen(path) + strlen("/") + strlen(fn) + NTG_NULL_BYTES;
        full_path = (char *)ntg_malloc(full_path_bytes * sizeof(char));
		snprintf(full_path, full_path_bytes, "%s/%s", path, fn);

        ntg_bashfilename(full_path, full_path);
        NTG_TRACE_VERBOSE_WITH_STRING("trying to access file at",full_path);
        access_rv = access(full_path, F_OK);

        if (!access_rv) {
            NTG_TRACE_VERBOSE_WITH_STRING("found", full_path);
            return full_path;
        }

        ntg_free(full_path);
    }

    NTG_TRACE_VERBOSE_WITH_STRING("file not found",fn);

    return NULL;

}

char *ntg_search_for_file(const char *token, char *file_suffix, int envvars)
{

    char *paths = NULL, *path = NULL, *suffix = NULL;
    const char suff_delimiter = '.';
    int access_rv = 0;
    struct dirent *content;
    DIR *dir;
    int ignore_suffix = 0;

    NTG_TRACE_VERBOSE_WITH_STRING("Looking for", token);

	NTG_TRACE_VERBOSE("Building path list");

    paths = ntg_build_path_list(envvars);

    NTG_TRACE_VERBOSE("Checking file suffix");

    if (file_suffix == NULL)
        ignore_suffix = 1;

    NTG_TRACE_VERBOSE("Traversing path list");

    while ((path = strtok(paths, NTG_MULTI_PATH_SEPARATOR))) {

        char *full_path;

        paths = NULL;

        if (path[0] != '/') {
            NTG_TRACE_VERBOSE_WITH_STRING("Ignoring relative path", path);
            continue;
        }

        NTG_TRACE_VERBOSE_WITH_STRING("Looking in", path);

        full_path = (char *)ntg_malloc(strlen(path) + 265);

        dir = opendir(path);
        if (dir != NULL) {
            while ((content = readdir(dir))) {

                /* FIX: added by jb to prevent crash in serializer test.c */
                if (token == NULL)
                    break;

                /* Does it match the token? */
                if (strstr(content->d_name, token) != NULL) {
                    /* Are we looking at the suffix and does the file have
                       one? */
                    if (!ignore_suffix) {
                        if ((suffix =
                             strrchr(content->d_name, suff_delimiter))) {
                            /* Does it match the suffix? */
                            if (strncmp(suffix + 1, file_suffix, 3) == 0) {
                                sprintf(full_path, "%s/%s", path,
                                        content->d_name);
                                break;
                            }
                        }
                    } else {
                        sprintf(full_path, "%s/%s", path, content->d_name);
                        break;
                    }
                }
            }
        }
        access_rv = access(full_path, F_OK);
        if (!access_rv) {
            NTG_TRACE_VERBOSE_WITH_STRING("found", full_path);
            return full_path;
        }

        NTG_TRACE_ERROR_WITH_STRING("failed to find", token);

        ntg_free(full_path);
    }

    return NULL;
}


char *ntg_ensure_filename_has_suffix( const char *filename, const char *suffix )
{
	int filename_length;
	int suffix_length;
	char *appended_filename;

	assert( filename && suffix );

	filename_length = strlen( filename );
	suffix_length = strlen( suffix );

	if( filename_length > suffix_length + 1 )
	{
		if( strcmp( filename + filename_length - suffix_length, suffix ) == 0 )
		{
			if( filename[ filename_length - suffix_length - 1 ] == '.' )
			{
				/* filename already has suffix */
				return strdup( filename );
			}
		}
	}

	appended_filename = ntg_malloc( filename_length + suffix_length + 2 );
	sprintf( appended_filename, "%s.%s", filename, suffix );

	return appended_filename;
}


unsigned int array_elements(void **array)
{

    int len = 0;

    while (array[len])
        len++;

    len -= 1;

    return (len < 0 ? 0 : len);

}

/** from Miller Puckette **/
void ntg_bashfilename(const char *from, char *to)
{
    char c;
    while ((c = *from++)) {
#ifdef _WINDOWS
        if (c == '/')
            c = '\\';
#endif
        *to++ = c;
    }
    *to = 0;
}

/** from Miller Puckette **/
void ntg_unbashfilename(const char *from, char *to)
{
    char c;
    while ((c = *from++)) {
#ifdef _WINDOWS
        if (c == '\\')
            c = '/';
#endif
        *to++ = c;
    }
    *to = 0;
}

/** from Miller Puckette **/
int ntg_is_absolute_path(const char *dir)
{
    if (dir[0] == '/' || dir[0] == '~'
#ifdef _WINDOWS
        || dir[0] == '%' || (dir[1] == ':' && dir[2] == '/')
#endif
        ) {
        return 1;
    } else {
        return 0;
    }
}

char *ntg_replace_substring(const char *string, const char *original,
                            const char *replacement)
{

    size_t len_string, len_original, len_replacement, len_new, len_firstpart;
    char *new, *substring;

    len_string = strlen(string);
    len_original = strlen(original);
    len_replacement = strlen(replacement);

    len_new = (len_original - len_string) + len_replacement;

    new = ntg_malloc((len_new + 1) * sizeof(char));

    substring = strstr(string, original);

    len_firstpart = (string - substring) * -1;

    strncpy(new, string, len_firstpart * sizeof(char));
    strncpy(&new[len_firstpart], replacement, len_replacement * sizeof(char));
    strncpy(&new[len_firstpart + len_replacement],
            &string[len_firstpart + len_original],
            len_string - len_firstpart + len_original);

    return new;

}

/* taken from libxml2 examples */
xmlChar *ConvertInput(const char *in, const char *encoding)
{
    unsigned char *out;
    int ret;
    int size;
    int out_size;
    int temp;
    xmlCharEncodingHandlerPtr handler;

    if (in == 0)
        return 0;

    handler = xmlFindCharEncodingHandler(encoding);

    if (!handler) {
        NTG_TRACE_ERROR_WITH_STRING("ConvertInput: no encoding handler found for",
               encoding ? encoding : "");
        return NULL;
    }

    size = (int)strlen(in) + 1;
    out_size = size * 2 - 1;
    out = malloc((size_t) out_size);

    if (out != 0) {
        temp = size - 1;
        ret = handler->input(out, &out_size, (const xmlChar *)in, &temp);
        if ((ret < 0) || (temp - size + 1)) {
            if (ret < 0) {
                NTG_TRACE_ERROR("ConvertInput: conversion wasn't successful.");
            } else {
                NTG_TRACE_ERROR_WITH_INT
                    ("ConvertInput: conversion wasn't successful. converted octets",
                     temp);
            }

            free(out);
            out = NULL;
        } else {
            out = realloc(out, out_size + 1);
            out[out_size] = 0;  /* null terminating out */
        }
    } else {
        NTG_TRACE_ERROR("ConvertInput: no mem");
    }

    return out;
}

char *ntg_make_indent(int n_spaces)
{

    char *indent;
    int n;

    indent = ntg_malloc(2 * sizeof(char));
    snprintf(indent, 2 * sizeof(char), "\n");

    for (n = 0; n < n_spaces; n++) {
        indent = ntg_string_append(indent, "  ");
    }

    return indent;

}

char *ntg_make_node_name(const char *class_name)
{

    ntg_id fake_id;
    char *node_name;

    fake_id = ntg_id_new();

    node_name = ntg_malloc((strlen(class_name) +
                            ntg_count_digits(fake_id) + 1) * sizeof(char));

    sprintf(node_name, "%s%li", class_name, fake_id);

    return node_name;

}

bool ntg_string_endswith (const char *string, const char *suffix)
{
	size_t len_string = 0;
	size_t len_suffix = 0;

    if (string == NULL || suffix == NULL) {
        return false;
    }
    
	len_string = strlen(string);
    len_suffix = strlen(suffix);

    if (len_suffix >  len_string) {
        return false;
    }

    return strncmp(string + len_string - len_suffix, suffix, len_suffix) == 0;
}

void ntg_slash_to_dot(char *string)
{
    size_t length;

    length = strlen(string);

    while(length--) {
        if(string[length] == '/'){
            string[length] = '.';
        }
    }

}


/* helper to read a single hexadecimal character */
ntg_error_code ntg_read_hex_char( char input, unsigned char *output )
{
	if( input >= '0' && input <= '9' )
	{
		*output = input - '0';
		return NTG_NO_ERROR;
	}

	if( input >= 'A' && input <= 'F' )
	{
		*output = input + 0x0A - 'A';
		return NTG_NO_ERROR;
	}

	if( input >= 'a' && input <= 'f' )
	{
		*output = input + 0x0A - 'a';
		return NTG_NO_ERROR;
	}

	return NTG_ERROR;
}


/* helper to read up to a caller-specified number of hexadecimal characters, up to an unsigned long's worth */
unsigned long ntg_read_hex_chars( const char *input, unsigned int number_of_bytes, ntg_error_code *error_code )
{
	unsigned long result = 0;
	unsigned char nibble;
	int i;

	assert( input && number_of_bytes <= sizeof( unsigned long ) );

	for( i = 0; i < number_of_bytes * 2; i++ )
	{
		if( ntg_read_hex_char( input[ i ], &nibble ) != NTG_NO_ERROR )
		{
			*error_code = NTG_ERROR;
			return 0;
		}

		result = ( result << 4 ) + nibble;
	}

	return result;
}


bool ntg_guids_are_equal( const GUID *guid1, const GUID *guid2 )
{
	return ( memcmp( guid1, guid2, sizeof( GUID ) ) == 0 );
}


void ntg_guid_set_null( GUID *guid )
{
	memset( guid, 0, sizeof( GUID ) );
}


bool ntg_guid_is_null( const GUID *guid )
{
	GUID null_guid;
	ntg_guid_set_null( &null_guid );

	return ntg_guids_are_equal( guid, &null_guid );
}


char *ntg_guid_to_string( const GUID *guid )
{
	char *string;

	assert( guid );

	string = ntg_malloc( 37 );

	sprintf( string, "%.8x-%.4x-%.4x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x", 
		guid->Data1, guid->Data2, guid->Data3,
		guid->Data4[ 0 ], guid->Data4[ 1 ], guid->Data4[ 2 ], guid->Data4[ 3 ], 
		guid->Data4[ 4 ], guid->Data4[ 5 ], guid->Data4[ 6 ], guid->Data4[ 7 ] );

	return string;
}


ntg_error_code ntg_string_to_guid( const char *string, GUID *output )
{
	ntg_error_code error_code = NTG_NO_ERROR;
	int i;

	assert( string && output );

	if( strlen( string ) < 36 ) 
	{
		return NTG_ERROR;
	}
	
	if( string[ 8 ] != '-' || string[ 13 ] != '-' || string[ 18 ] != '-' || string[ 23 ] != '-' )
	{
		return NTG_ERROR;
	}

	output->Data1 = ntg_read_hex_chars( string, sizeof( uint32_t ), &error_code );
	output->Data2 = ntg_read_hex_chars( string + 9, sizeof( uint16_t ), &error_code );
	output->Data3 = ntg_read_hex_chars( string + 14, sizeof( uint16_t ), &error_code );

	for( i = 0; i < 2; i++ )
	{
		output->Data4[ i ] = ntg_read_hex_chars( string + 19 + i * 2, sizeof( uint8_t ), &error_code );
	}

	for( i = 0; i < 6; i++ )
	{
		output->Data4[ i + 2 ] = ntg_read_hex_chars( string + 24 + i * 2, sizeof( uint8_t ), &error_code );
	}

	if( error_code != NTG_NO_ERROR )
	{
		ntg_guid_set_null( output );
	}

	return error_code;
}


char *ntg_date_to_string( const struct tm *date )
{
	char *output;
	assert( date );

	output = ntg_malloc( 20 );
	sprintf( output, "%04i-%02i-%02iT%02i:%02i:%02i", date->tm_year + 1900, date->tm_mon + 1, date->tm_mday, date->tm_hour, date->tm_min, date->tm_sec );
	return output;
}


ntg_error_code ntg_string_to_date( const char *input, struct tm *output )
{
	if( strlen( input ) < 16 )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Unexpected date/time format", input );
		return NTG_ERROR;
	}

	output->tm_year = atoi( input ) - 1900;
	output->tm_mon = atoi( input + 5 ) - 1;
	output->tm_mday = atoi( input + 8 );
	output->tm_hour = atoi( input + 11 );
	output->tm_min = atoi( input + 14 );
	output->tm_sec = atoi( input + 17 );
	output->tm_isdst = -1;
	if( mktime( output ) == -1 )
	{
		return NTG_ERROR;
	}
	else
	{
		return NTG_NO_ERROR;
	}
}


int ntg_levenshtein_distance( const char *string1, const char *string2 )
{
	int length1, length2;
	int cost = 0;

	assert( string1 && string2 );

	length1 = strlen( string1 );
	length2 = strlen( string2 );

	if( length1 == 0 ) return length2;
	if( length2 == 0 ) return length1;

    if( string1[ 0 ] != string2[ 0 ] ) 
	{
		cost = 1;
	}

	return MIN( MIN(
		ntg_levenshtein_distance( string1 + 1, string2 ) + 1,
		ntg_levenshtein_distance( string1, string2 + 1 ) + 1 ), 
		ntg_levenshtein_distance( string1 + 1, string2 + 1 ) + cost );
}
