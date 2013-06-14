/* libIntegra multimedia module interface
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

#ifndef INTEGRA_HELPER_H
#define INTEGRA_HELPER_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <stdbool.h>

#ifdef HAVE_CONFIG_H
#    include <config.h>
#else
#define PACKAGE_NAME "libIntegra"
#endif

#include <libxml/encoding.h>

#include "integra/integra.h"

struct tm;


/** These constants are used to determine which environment variables are used 
 * in file searches */
#define NTG_PATH            1
#define NTG_HOME            2
#define NTG_PWD             4 /* The environment variable: PWD */
#define NTG_CWD             8 /* The current working directory */
#define NTG_LD_LIBRARY_PATH 16
#define NTG_XDG_DATA_DIRS   32
#define NTG_NTG_BRIDGE_PATH 64
#define NTG_NTG_DEFS_PATH   128
#define NTG_NTG_USER_DIR    256

/** These are the defaults for the above */

/* note: default INSTALL_PREFIX, if not specified
 * during configure, is /usr/local */

#ifdef INSTALL_PREFIX
#define NTG_EXTRA_LIB INSTALL_PREFIX "/lib" NTG_COLON
#define NTG_EXTRA_BRIDGE INSTALL_PREFIX "/lib/integra" NTG_COLON
#define NTG_EXTRA_DEFS INSTALL_PREFIX "/share/"
#else
#define NTG_EXTRA_LIB
#define NTG_EXTRA_BRIDGE
#define NTG_EXTRA_DEFS
#endif

#define NTG_DEFAULT_LD_LIBRARY_PATH NTG_EXTRA_LIB "/usr/lib"
#define NTG_DEFAULT_BRIDGE_PATH NTG_EXTRA_BRIDGE "/usr/lib/integra"
#define NTG_DEFAULT_SHARE_PATH_PREFIX1 NTG_EXTRA_DEFS
#define NTG_DEFAULT_SHARE_PATH_PREFIX2 "/usr/share/"
#define NTG_COLON ":"
#define NTG_MODULES_SUBDIR "/modules" /* FIX: should be implementations ? */
#define NTG_DEFS_SUBDIR "/definitions"
#define NTG_DEFAULT_DATA_PATH NTG_DEFAULT_SHARE_PATH_PREFIX1 PACKAGE_NAME NTG_COLON NTG_DEFAULT_SHARE_PATH_PREFIX2 PACKAGE_NAME
#define NTG_DEFAULT_DEFS_PATH NTG_DEFAULT_SHARE_PATH_PREFIX1 PACKAGE_NAME NTG_DEFS_SUBDIR
#define NTG_DEFAULT_XDG_DATA_DIRS_PATH NTG_DEFAULT_DATA_PATH NTG_COLON NTG_DEFAULT_SHARE_PATH_PREFIX1 PACKAGE_NAME NTG_MODULES_SUBDIR NTG_COLON NTG_DEFAULT_SHARE_PATH_PREFIX2 PACKAGE_NAME NTG_MODULES_SUBDIR
#define NTG_DEFAULT_USER_DIR "/.integra" /* In the home directory! */

#define NTG_NULL_BYTES 1

#define NTG_NODE_NAME_CHARACTER_SET "0123456789_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

/*ntg_info *infos_root_node; 
  ntg_node *nodes_root_node; 
  */

/** \brief strdup clone, which uses ntg_malloc internally */
char *ntg_strdup(const char *string);

/** \brief Count the number of digits in an int 
 *
 * \note {I'm sure there must be a library function for this, so if there is 
 * could someone please email me}
 *
 */
int ntg_count_digits(int num);


/** 
 * \brief Convenience function to convert a string to lowercase 
 *  \note {The string is modified *in place*}
 *
 */
int ntg_lower(char *str);

/** 
 * \brief Convenience function to convert a string to uppercase 
 *  \note {The string is modified *in place*}
 *
 */
int ntg_upper(char *str);

/** Appends one string to another (not including null character), and returns a pointer to the resulting string */
char *ntg_string_append(char *dest, const char *source);

/** Appends one path to another (not including null character), and returns a pointer to the resulting path */
/*char *ntg_append_path(char *dest, const char *source); */

/** 
 * Returns a null-terminated colon delimited string representing
 * the list of paths based on an environment variable code.
 *
 * See envars description in ntg_file_find. 
 *
 * This function will only guarantee that the file exists. It is
 * up to the caller to check other things about the file,
 * e.g. test if it is read/writable.
 *
 * This function allocates memory for the returned path. It is up
 * to the caller to free this.
 *
 */
char *ntg_build_path_list(int envvars);

/** \brief Return the length of a file in bytes
  */
long ntg_file_length(FILE *file_handle);

/** \brief Find a file and return its path
 *
 * \param char *filename The full name of the file to search for
 * \param int envvars The sum of the environment variable codes
 * for inclusion in the search e.g. NTG_BRIDGE_PATH+PATH.
 *
 * A binary and is performed on the envvars variable to determine
 * which paths to search.
 */
char *ntg_file_find(const char *filename, int envvars);


/** \brief appends suffix to file_name if not already present
 * \param const char *filename The file name to be appended
 * \param const char *suffix the suffix to append
  *
 * This method returns a newly allocated string which should be freed 
 * with ntg_free by the caller
 */

char *ntg_ensure_filename_has_suffix(const char *filename, const char *suffix);


/** Return the number of elements in an array pointers */
unsigned int array_elements(void **array);

/** thanks to Miller Puckette these helpers **/
/* change '/' characters to the system's native file separator */
void ntg_bashfilename(const char *from, char *to);

/* change the system's native file separator to '/' characters  */
void ntg_unbashfilename(const char *from, char *to);

/* test if path is absolute or relative, based on leading /, env vars, ~, etc */
int ntg_is_absolute_path(const char *dir);

/* replace the substring 'original' with 'replacement' inside 'string' */
char *ntg_replace_substring(const char *string, const char *original,
        const char *replacement);
/**
 * ConvertInput:
 * @in: string in a given encoding
 * @encoding: the encoding used
 *
 * Converts @in into UTF-8 for processing with libxml2 APIs
 *
 * Returns the converted UTF-8 string, or NULL in case of error.
 */
/* taken from libxml2 examples */
xmlChar *ConvertInput(const char *in, const char *encoding);

/* make an indent by appending n_spaces spaces to newline character */
char *ntg_make_indent(int n_spaces);

char *ntg_make_node_name(const char *class_name);

/* return the concatenation of s1 and s2. return value must be free'd with
 * ntg_free() */
char *ntg_string_join(const char *s1, const char *s2);

/* replace hashes in a string with dots. modifies the string in place */
void ntg_slash_to_dot(char *string);

/* return true if string ends with suffix */
bool ntg_string_endswith (const char *string, const char *suffix);

/* read a single hexadecimal character */
ntg_error_code ntg_read_hex_char( char input, unsigned char *output );

/* read a caller-specified number of hexadecimal characters, up to an unsigned long's worth */
unsigned long ntg_read_hex_chars( const char *input, unsigned int number_of_bytes, ntg_error_code *error_code );

/* test guids for equality*/
bool ntg_guids_are_equal( const GUID *guid1, const GUID *guid2 );

/* nullify guid */
void ntg_guid_set_null( GUID *guid );

/* test guid for nullness */
bool ntg_guid_is_null( const GUID *guid );


/* converts guid to string in lowercase hexadecimal form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx".  Caller must free */
char *ntg_guid_to_string( const GUID *guid );

/* converts string to guid.  expects string in hexadecimal form "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" */
ntg_error_code ntg_string_to_guid( const char *string, GUID *output );


/* converts date/time to ISO 8601 string.  Caller must free */
char *ntg_date_to_string( const struct tm *date );

/* converts string to date/time.  expects string in ISO 8601 form eg 2012-07-20T14:42 */
ntg_error_code ntg_string_to_date( const char *input, struct tm *output );


/* calculate levenshtein distance between two strings.  */
int ntg_levenshtein_distance( const char *string1, const char *string2 );


/* does the node name consist entirely of valid characters? */
bool ntg_validate_node_name( const char *name );


#ifdef __cplusplus
}
#endif

#endif
