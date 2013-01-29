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
    const char *string;
};

ntg_path *ntg_path_filter(const ntg_path *path1, const ntg_path *path2);

#endif
