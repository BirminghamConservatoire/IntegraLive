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

#ifndef INTEGRA_VALUE_PRIVATE_H
#define INTEGRA_VALUE_PRIVATE_H



#include "Integra/integra.h"


#include <stdlib.h>

#define NTG_NIL_REPR "(nil)"


struct ntg_value_ {
    ntg_value_type type;
    union ctype_ {
        char *s;
        float f;
        int i;
    } ctype;
};


/* values */
LIBINTEGRA_API ntg_value_type ntg_value_get_type(const ntg_value *value);
LIBINTEGRA_API float ntg_value_get_float(const ntg_value *value);
LIBINTEGRA_API int ntg_value_get_int(const ntg_value *value);
LIBINTEGRA_API char *ntg_value_get_string(const ntg_value *value);


/** \brief Returns a pointer to a newly allocated value
  * \param void *v a pointer to the value initialiser
  * \param ... optional parameter of type size_t specifying byte array length for value of type NTG_BLOB */
LIBINTEGRA_API ntg_value *ntg_value_new(ntg_value_type type, const void *v, ...);

/** \brief Free ntg_value previously allocated with ntg_value_new() */
LIBINTEGRA_API ntg_error_code ntg_value_free(ntg_value *value) ;



/** \brief Returns a pointer to a newly allocated value and takes the
 *   value as a string, regardless of type.
 */
ntg_value *ntg_xml_value_new(int type, const char *v);

/** \brief Copies the source value into target converting type if possible
 *
 * \param ntg_value *target A pointer to an ntg_value struct that will b used to store the value
 * \param ntg_value *source A pointer to an ntg_value struct that contains the source value 
 *
 * */
void ntg_value_copy(ntg_value *target, const ntg_value *source); 

/** \brief duplicate a value by allocating a new one and copying in
  * Analogous to strdup()
  */
ntg_value *ntg_value_duplicate(const ntg_value *value);

/** \brief Set an ntg_value as given by type 
 *
 * \param ntg_value *target A pointer to an ntg_value struct that will b used to store the value
 * \param void *v A pointer to the actual value
 * \param ... optional fourth parameter specifying the length of a byte array
 *
 * */
void ntg_value_set(ntg_value *value, const void *v, ...);

/** \brief Prints a ntg_value to a C string */
ntg_error_code ntg_value_sprintf(char *output, int chars_available, const ntg_value *value);

/**\brief Compares two values for equality 
  * Currently only compares values of same type otherwise returns error */
ntg_error_code ntg_value_compare(const ntg_value *value,
        const ntg_value *comparable);

/**\return a type-agnostic scalar subtraction between two values.
  * both values must be of same type */
float ntg_value_get_difference( const ntg_value *value1, const ntg_value *value2 );


/* \brief convert a string representation of a value to a value */
ntg_value *ntg_value_from_string(ntg_value_type type, const char *string);

/* \brief attempt to convert a value from one type to another
 */
ntg_value *ntg_value_change_type(const ntg_value *value, ntg_value_type newType);



#endif
