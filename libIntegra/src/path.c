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

#include "platform_specifics.h"

#include <string.h>
#include <assert.h>
#include <pthread.h>

#include "memory.h"
#include "path.h"
#include "helper.h"

ntg_path *ntg_path_from_string(const char *path_string)
{
    char     *saveptr = NULL;
    char     *temp    = NULL;
    char     *temp2   = NULL;
    ntg_path *path    = NULL;

    assert(path_string);

    if(path_string == '\0' || !strcmp(path_string, NTG_EMPTY_PATH)){
        return ntg_path_new();
    }

    temp    = ntg_strdup(path_string);
    temp2   = temp;
    path    = ntg_path_new();

    for (;; temp = NULL) {
        char *elem = strtok_r(temp, ".", &saveptr);
        if (elem == NULL) {
            break;
        }
        ntg_path_append_element(path, elem);
    }

    ntg_free(temp2);
    return path;

}

const char *ntg_path_to_string_(const ntg_path * path)
{
    char *path_s              = NULL;
    unsigned int marker       = 0;
    size_t len_elem           = 0;
    size_t len_path           = 0;
    unsigned int n            = 0;

    assert(path);

    /* allocate memory for '.' separators and \0 char */
    if (path->n_elems) {
        assert(path->elems != NULL);
        path_s = ntg_malloc(path->n_elems * sizeof(char));
    } else {
        path_s = ntg_calloc(1, sizeof(char));
    }

    len_path = path->n_elems;

    for (n = 0; n < path->n_elems; n++) {
        if(path->elems[n] == NULL) {
            /* this should never happen */
            NTG_TRACE_ERROR("path element was NULL");
            assert(false);
            continue;
        }
        len_elem = strlen(path->elems[n]);
        len_path += len_elem;
        path_s = ntg_realloc(path_s, len_path * sizeof(char));
        strncpy(&path_s[marker], path->elems[n], len_elem * sizeof(char));
        marker += len_elem;
        strncpy(&path_s[marker], ".", sizeof(char));
        marker++;
    }

    if(marker){
        path_s[marker - 1] = '\0';
    }     
    
    return path_s;

}

void ntg_path_update_string(ntg_path *path)
{
    assert(path);
    if (path->string != NULL) {
        ntg_free ((char *)path->string);
    }
    path->string = ntg_path_to_string_ (path);
}

char *ntg_path_pop_element(ntg_path * path)
{
	char * ret = NULL;

    assert (path != NULL);

    if (path->n_elems == 0) {
        NTG_TRACE_ERROR("path has zero elements");
        return NULL;
    }

    path->n_elems--;

    ret = path->elems[path->n_elems];

    if(path->n_elems == 0){
        ntg_free(path->elems);
        path->elems = NULL;
    }

    ntg_path_update_string(path);

    return ret;
}

ntg_path *ntg_path_append_element(ntg_path * path, const char *element)
{
    assert (element != NULL);
    assert (path != NULL);

    path->n_elems++;
    if (path->elems == NULL ||
            sizeof(path->elems) < (path->n_elems * sizeof(char *))) {
        path->elems = ntg_realloc(path->elems, path->n_elems * sizeof(char *));
    }
    path->elems[path->n_elems - 1] = ntg_strdup(element);
    ntg_path_update_string(path);

    return path;
}

ntg_path *ntg_path_reverse_elements(ntg_path * path)
{

    int n;
    int m = path->n_elems - 1;
    int N = path->n_elems / 2;

    for (n = 0; n < N; n++, m--) {
        char *temp     = path->elems[n];
        path->elems[n] = path->elems[m];
        path->elems[m] = temp;
    }
    ntg_path_update_string(path);

    return path;
}

ntg_path *ntg_path_join(const ntg_path * start, const ntg_path * end)
{
    int n;
    ntg_path *result;

    result          = ntg_path_new();
    result->n_elems = start->n_elems + end->n_elems;
    result->elems   = ntg_malloc(result->n_elems * sizeof(char *));

    /* FIX: could probably use memcpy here */
    for (n = 0; n < start->n_elems; n++) {
        result->elems[n] = ntg_strdup(start->elems[n]);
    }
    for (; n < result->n_elems; n++) {
        result->elems[n] = ntg_strdup(end->elems[n - start->n_elems]);
    }
    ntg_path_update_string(result);

    return result;
}


ntg_error_code ntg_path_validate(const ntg_path * path)
{
	int n;

    if (path == NULL) {
        NTG_TRACE_ERROR("path is NULL");
        assert(false);
        return NTG_PATH_ERROR;
    }
    if (path->string == NULL) {
        NTG_TRACE_ERROR("path string is NULL");
        assert(false);
        return NTG_PATH_ERROR;
    }
    if ((path->elems == NULL && path->n_elems) ||
            (path->elems != NULL && !path->n_elems)) {
        NTG_TRACE_ERROR("path elements mismatch");
        if(!path->elems){
            NTG_TRACE_ERROR_WITH_INT(
                    "%s(): path->elems is NULL, but path->n_elems is",
                    path->n_elems);
        } else {
            NTG_TRACE_ERROR(
                    "%s(): path->n_elems is 0, but path->elems is not NULL");
        }
		NTG_TRACE_ERROR_WITH_STRING("Path", path->string);
        assert(false);
        return NTG_PATH_ERROR;
    }
    if ((path->n_elems && !strlen(path->string)) ||
            (!path->n_elems && strlen(path->string))) {
        NTG_TRACE_ERROR("path string mismatch");
        if(*path->string == '\0'){
            NTG_TRACE_ERROR_WITH_INT(
                    "path->string is empty, but path->n_elems is",
                    path->n_elems);
        } else {
            NTG_TRACE_ERROR_WITH_STRING(
                    "path->string is",
                    path->string);
            NTG_TRACE_ERROR_WITH_INT(
                    "but path->n_elems is",
                    path->n_elems);

		}
        assert(false);
        return NTG_PATH_ERROR;
    }
    if (path->n_elems > NTG_PATH_MAX_ELEMS){
        NTG_TRACE_ERROR_WITH_INT("path->n_elems exceeds", 
                NTG_PATH_MAX_ELEMS);
        assert(false);
        return NTG_PATH_ERROR;
    }
    {
        for (n = 0; n < path->n_elems; n++) {
            if(path->elems[n] == NULL){
                NTG_TRACE_ERROR_WITH_INT("path->n_elems[n] is NULL where n=", n);
                NTG_TRACE_ERROR_WITH_STRING("path: ", path->string);
                assert(false);
            }
        }
    }

    return NTG_NO_ERROR;
}

ntg_path *ntg_path_new(void)
{
    ntg_path *path;

    path          = ntg_malloc(sizeof(ntg_path));
    path->n_elems = 0;
    path->elems   = NULL;
    path->string  = ntg_calloc(1, sizeof(char));

    return path;
}

ntg_error_code ntg_path_free(ntg_path * path)
{

    ntg_error_code error_code = NTG_NO_ERROR;

    if (ntg_path_validate(path) != NTG_NO_ERROR) {
        assert(0);
        return NTG_ERROR;
    }

    if (path->elems != NULL) {
        int n;
        for (n = 0; n < path->n_elems; n++) {
            ntg_free(path->elems[n]);
        }
        ntg_free(path->elems);
    }
    ntg_free((char *)path->string);
    ntg_free(path);

    return error_code;

}

ntg_path *ntg_path_copy(const ntg_path * source)
{
    if(ntg_path_validate(source) != NTG_NO_ERROR){
        return NULL;
    }else{

        ntg_path *path;
        int n;

        path          = ntg_path_new();
        path->n_elems = source->n_elems;
        path->elems   = ntg_malloc(path->n_elems * sizeof(char *));

        for (n = 0; n < path->n_elems; n++) {
            path->elems[n] = ntg_strdup(source->elems[n]);
        }
        ntg_path_update_string(path);

        return path;
    }
}

bool ntg_path_compare(const ntg_path * path1, const ntg_path * path2)
{

    unsigned int n = 0;

    assert (ntg_path_validate(path1) == NTG_NO_ERROR);
    assert (ntg_path_validate(path2) == NTG_NO_ERROR);

    if (path1->n_elems != path2->n_elems) {
        return false;
    }
    if (strcmp(path1->string, path2->string)) {
        return false;
    } else {
        for (n = 0; n < path1->n_elems; n++) {
            assert (!strcmp(path1->elems[n], path2->elems[n]));
        }
    }
    return true;
}

/* path filter */
ntg_path *ntg_path_filter(const ntg_path *path1, const ntg_path *path2)
{
    const ntg_path *pathlong  = path1;
    const ntg_path *pathshort = path2;
    ntg_path *rem;

    int n = 0;
    rem = ntg_path_new();

    if (path2->n_elems > path1->n_elems) {
        pathlong = path2;
        pathshort = path1;
    }

    for (n = 0; n < pathshort->n_elems; n++) {
        if(!strcmp(pathlong->elems[n], pathshort->elems[n])) {
            continue;
        }
        ntg_path_append_element(rem, pathlong->elems[n]);
    }

    for (; n < pathlong->n_elems; n++) {
        ntg_path_append_element(rem, pathlong->elems[n]);
    }

    return rem;
}

