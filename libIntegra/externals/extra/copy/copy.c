/* copy - copy a file from one path to another preserving permissions
 *
 * Author: Jamie Bullock <jamie@jamiebullock.com>
 *
 * This is free and unencumbered software released into the public domain.
 *
 * Anyone is free to copy, modify, publish, use, compile, sell, or
 * distribute this software, either in source code form or as a compiled
 * binary, for any purpose, commercial or non-commercial, and by any
 * means.
 *
 * In jurisdictions that recognize copyright laws, the author or authors
 * of this software dedicate any and all copyright interest in the
 * software to the public domain. We make this dedication for the benefit
 * of the public at large and to the detriment of our heirs and
 * successors. We intend this dedication to be an overt act of
 * relinquishment in perpetuity of all present and future rights to this
 * software under copyright law.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * For more information, please refer to <http://unlicense.org/>
 */

#include "m_pd.h"

#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <poll.h>
#include <stdlib.h>
#include <sys/stat.h>

#ifdef __APPLE__
#define O_BINARY 0
#endif

#define CONSOLE_PREFIX "[copy]: "

typedef struct _copy
{
  t_object  x_obj;
  t_outlet *outlet;
}
t_copy;

t_class *copy_class;

int copy(const char *source, const char *target);

void *copy_new(t_symbol *s, int argc, t_atom *argv)
{
  t_copy *x = (t_copy *)pd_new(copy_class);
  x->outlet = outlet_new(&x->x_obj, &s_float);
  post(CONSOLE_PREFIX "copy file from source path to destination path");
  return (void *)x;
}

void copy_list(t_copy *x, t_symbol *s, int ac, t_atom *av)
{
    char source[MAXPDSTRING];
    char target[MAXPDSTRING];

    if(ac != 2 || (av[0].a_type != A_SYMBOL && av[1].a_type != A_SYMBOL))
    {
        pd_error(x, "expected a list containing <source path> <destination path>");
    }

    atom_string(&av[0], source, MAXPDSTRING);
    atom_string(&av[1], target, MAXPDSTRING);

    int rv = copy(source, target);
    rv++;
    
    if(rv)
    {
        post(CONSOLE_PREFIX "%s successfully copied to %s", source, target);
    }

    outlet_float(x->outlet, (t_float)rv);
}

void copy_setup(void)
{
  copy_class = class_new(gensym("copy"),
        (t_newmethod)copy_new,
        0, sizeof(t_copy), 0,
        A_GIMME, 0);
  class_addlist(copy_class, copy_list);
}

void block(int fd, int event) 
{
    struct pollfd topoll;
    topoll.fd = fd;
    topoll.events = event;
    poll(&topoll, 1, -1);
    // no need to check errors - if the stream is bust then the
    // next read/write will tell us
}

int copy_data_buffer(int fdin, int fdout, void *buf, size_t bufsize)
{
    for(;;)
    {
        void *pos;
        // read data to buffer
        ssize_t bytestowrite = read(fdin, buf, bufsize);
        if (bytestowrite == 0) break; // end of input
        if (bytestowrite == -1)
        {
            if (errno == EINTR) continue; // signal handled
            if (errno == EAGAIN)
            {
                block(fdin, POLLIN);
                continue;
            }
            return -1; 
        }

        // write data from buffer
        pos = buf;
        while (bytestowrite > 0)
        {
            ssize_t bytes_written = write(fdout, pos, bytestowrite);
            if (bytes_written == -1) 
            {
                if (errno == EINTR) continue;
                if (errno == EAGAIN)
                {
                    block(fdout, POLLOUT);
                    continue;
                }
                return -1;
            }
            bytestowrite -= bytes_written;
            pos += bytes_written;
        }
    }
    return 0;
}

#ifndef FILECOPY_BUFFER_SIZE
#define FILECOPY_BUFFER_SIZE (64*1024)
#endif

int copy_data(int fdin, int fdout) 
{
    for (size_t bufsize = FILECOPY_BUFFER_SIZE; bufsize >= 256; bufsize /= 2)
    {
        void *buffer = malloc(bufsize);
        if (buffer != NULL)
        {
            int result = copy_data_buffer(fdin, fdout, buffer, bufsize);
            free(buffer);
            return result;
        }
    }

    return -1;
}

int copy(const char *source, const char *target)
{
    struct stat info;

    int fdin = open(source, O_RDONLY|O_BINARY, 0);
    if (fdin == -1) 
    {
        error(CONSOLE_PREFIX "invalid input");
        return -1;
    }

    int rv = fstat(fdin, &info);

    if(rv == -1)
    {
        error(CONSOLE_PREFIX "stat failed\n");
        return -1;
    }

    int fdout = open(target, O_WRONLY|O_BINARY|O_CREAT|O_TRUNC, info.st_mode);
    if (fdout == -1)
    {
        error(CONSOLE_PREFIX "invalid output\n");
        close(fdin);
        return -1;
    } 

    rv = copy_data(fdin, fdout);

    if (rv == -1)
    {
        error(CONSOLE_PREFIX "copy failed\n");
    }

    return 0;
}
