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

#ifdef _WINDOWS
	#ifdef interface 
		#undef interface
	#endif
#endif


#ifndef INTEGRA_INTERFACE_PRIVATE_H
#define INTEGRA_INTERFACE_PRIVATE_H

#ifdef __cplusplus
extern "C" {
#endif

#include "../externals/guiddef.h"
#include <time.h>
#include <stdbool.h>

#include "Integra/integra.h"

#ifndef NTG_ENDPOINT_TYPEDEF
typedef struct ntg_endpoint_ ntg_endpoint;
#define NTG_ENDPOINT_TYPEDEF
#endif

#ifndef NTG_INTERFACE_TYPEDEF
typedef struct ntg_interface_ ntg_interface;
#define NTG_INTERFACE_TYPEDEF
#endif

typedef struct ntg_interface_info_ ntg_interface_info;
typedef struct ntg_control_info_ ntg_control_info;
typedef struct ntg_state_info_ ntg_state_info;
typedef struct ntg_constraint_ ntg_constraint;
typedef struct ntg_range_ ntg_range;
typedef struct ntg_allowed_state_ ntg_allowed_state;
typedef struct ntg_scale_ ntg_scale;
typedef struct ntg_state_label_ ntg_state_label;
typedef struct ntg_stream_info_ ntg_stream_info;
typedef struct ntg_widget_ ntg_widget;
typedef struct ntg_widget_position_ ntg_widget_position;
typedef struct ntg_widget_attribute_mapping_ ntg_widget_attribute_mapping;
typedef struct ntg_tag_ ntg_tag;
typedef struct ntg_implementation_info_ ntg_implementation_info;


typedef enum ntg_endpoint_type_ 
{
    NTG_CONTROL = 1,
    NTG_STREAM = 2

} ntg_endpoint_type;


typedef enum ntg_control_type_
{
	NTG_STATE = 1,
	NTG_BANG = 2

} ntg_control_type;


typedef enum ntg_scale_type_
{
	NTG_LINEAR = 1,
	NTG_EXPONENTIAL = 2,
	NTG_DECIBEL = 3

} ntg_scale_type;


typedef enum ntg_stream_type_
{
	NTG_AUDIO_STREAM = 1

} ntg_stream_type;


typedef enum ntg_stream_direction_
{
	NTG_STREAM_INPUT = 1,	
	NTG_STREAM_OUTPUT = 2	

} ntg_stream_direction;


typedef enum ntg_module_source_
{
	NTG_MODULE_SHIPPED_WITH_INTEGRA = 1,	
	NTG_MODULE_3RD_PARTY = 2,
	NTG_MODULE_EMBEDDED = 3

} ntg_module_source;



struct ntg_interface_ 
{
	GUID module_guid;
	GUID origin_guid;
	ntg_module_source module_source;
	char *file_path;
	ntg_interface_info *info;
	ntg_endpoint *endpoint_list;
	ntg_widget *widget_list;
	ntg_implementation_info *implementation;
};


struct ntg_interface_info_
{
	char *name;
	char *label;
	char *description;
	ntg_tag *tag_list;
	bool implemented_in_libintegra;
	char *author;
	struct tm created_date;
	struct tm modified_date;
};


struct ntg_tag_
{
	char *tag;
	ntg_tag *next;
};


struct ntg_endpoint_
{
	char *name;
	char *label;
	char *description;
	ntg_endpoint_type type;
	ntg_control_info *control_info;
	ntg_stream_info *stream_info;

	int endpoint_index;

	ntg_endpoint *next;
};

struct ntg_control_info_
{
	ntg_control_type type;
	ntg_state_info *state_info;
	bool can_be_source;
	bool can_be_target;
	bool is_sent_to_host;
};

struct ntg_constraint_
{
	ntg_range *range;
	ntg_allowed_state *allowed_states;
};

struct ntg_state_info_
{
	ntg_value_type type;
	ntg_constraint constraint;
	ntg_value *default_value;
	ntg_scale *scale;
	ntg_state_label *state_labels;
	bool is_saved_to_file;
	bool is_input_file;
};

struct ntg_range_
{
	ntg_value *minimum;
	ntg_value *maximum;
};

struct ntg_allowed_state_
{
	ntg_value *value;
	
	ntg_allowed_state *next;
};

struct ntg_scale_
{
	ntg_scale_type scale_type;
	int exponent_root;
};

struct ntg_state_label_
{
	ntg_value *value;
	char *text;

	ntg_state_label *next;
};

struct ntg_stream_info_
{
	ntg_stream_type type;
	ntg_stream_direction direction;
};

struct ntg_widget_position_
{
	float x;
	float y;
	float width;
	float height;
};

struct ntg_widget_
{
	char *type;
	char *label;
	ntg_widget_position position;
	ntg_widget_attribute_mapping *mapping_list;

	ntg_widget *next;
};

struct ntg_widget_attribute_mapping_
{
	char *widget_attribute;
	char *endpoint;

	ntg_widget_attribute_mapping *next;
};


struct ntg_implementation_info_
{
	char *patch_name;
	unsigned int checksum;
};


ntg_interface *ntg_interface_load( const unsigned char *buffer, unsigned int buffer_size );
void ntg_interface_free( ntg_interface *interface );

bool ntg_interface_is_core( const ntg_interface *interface );
bool ntg_interface_is_core_name_match( const ntg_interface *interface, const char *name );

bool ntg_interface_has_implementation( const ntg_interface *interface );
bool ntg_interface_should_embed_module( const ntg_interface *interface );

bool ntg_endpoint_should_send_to_host( const ntg_endpoint *endpoint );
bool ntg_endpoint_is_input_file( const ntg_endpoint *endpoint );
bool ntg_endpoint_should_load_from_ixd( const ntg_endpoint *endpoint, ntg_value_type loaded_type );
bool ntg_endpoint_is_audio_stream( const ntg_endpoint *endpoint );


#ifdef __cplusplus
}
#endif

#endif

