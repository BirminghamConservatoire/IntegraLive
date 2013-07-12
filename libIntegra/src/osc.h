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
_resolve * USA.
 */

#ifndef NTG_OSC_H
#define NTG_OSC_H


#include "lo/lo.h"

void ntg_osc_error(int num, const char *msg, const char *path);

int handler_namespace_method(const char *address, const char *types,
                             lo_arg ** argv, int argc, void *data,
                             void *user_data);


#endif

