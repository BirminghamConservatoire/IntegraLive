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

#ifndef INTEGRA_QUEUE_PRIVATE_H
#define INTEGRA_QUEUE_PRIVATE_H

#include <stdbool.h>
#include "command.h"

typedef struct ntg_queue_ {
  int n_elements;
  int read_pos;
  int write_pos;
  int used;
  ntg_command **data;
} ntg_queue;


ntg_queue *ntg_queue_new(int n_elements);
ntg_command *ntg_queue_pop(ntg_queue *rb);
void ntg_queue_free(ntg_queue *rb);
bool ntg_queue_push(ntg_queue *rb, ntg_command *data);


#endif
