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

#ifndef INTEGRA_PATH_PRIVATE_H
#define INTEGRA_PATH_PRIVATE_H

#include "Integra/integra.h"

#define NTG_EMPTY_PATH "."
#define NTG_PATH_MAX_ELEMS 255

struct ntg_path_ {
    char **elems;
    unsigned int n_elems;
    char *string;
};


/** \brief create an ntg_path from a '.' delimited string */
LIBINTEGRA_API ntg_path *ntg_path_from_string(const char *path_string);

/* \brief pop an element from a path, returning that element as a string.
 * The returned string is a copy and must be freed with ntg_free() after usage. */
LIBINTEGRA_API char *ntg_path_pop_element(ntg_path *path);

/* paths */
/* \brief append an element to the end of a path. 
 * ntg_path *path is modified to hold the new path */
LIBINTEGRA_API void ntg_path_append_element(ntg_path *path, const char *element);

/* Create a new path struct containing the contents of source */
LIBINTEGRA_API ntg_path *ntg_path_copy(const ntg_path *source);

/* \brief Check that a path is valid */
LIBINTEGRA_API ntg_error_code ntg_path_validate(const ntg_path *path);

LIBINTEGRA_API ntg_path *ntg_path_new(void);
LIBINTEGRA_API ntg_error_code ntg_path_free( ntg_path *path);


/** \brief in place path reversal
  */
void ntg_path_reverse_elements(ntg_path *path);



#endif
