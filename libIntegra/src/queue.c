#include "platform_specifics.h"

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

#include "atomic.c"
#include "queue.h"
#include "command.h"
#include "integra/integra.h"

void *ntg_queue_new(int n_elements){
  ntg_queue *rb=calloc(1,sizeof(ntg_queue) + (sizeof(void*)*n_elements));
  rb->n_elements=n_elements;
  return rb;
}

void *ntg_queue_pop(ntg_queue *rb){

  void *ret = NULL;

  if(rb->used==0)
    return NULL;

  __atomic_add(&rb->used,-1);

  ret=rb->data[rb->read_pos];

  rb->read_pos+=1;
  if(rb->read_pos==rb->n_elements)
    rb->read_pos=0;

  return ret;
}

bool ntg_queue_push(ntg_queue *rb,void *data){
  if(rb->used==rb->n_elements)
    return false;

  rb->data[rb->write_pos] = data;

  __atomic_add(&rb->used,1);

  rb->write_pos+=1;
  if(rb->write_pos==rb->n_elements)
    rb->write_pos=0;

  return true;
}

void ntg_queue_free(ntg_queue *rb)
{
    if(rb->used) {
        NTG_TRACE_ERROR_WITH_INT("ringbuffer still contains elements",
                rb->used);
        assert(false);
    }
    /* queue should already be empty when rb_destory() is called */
    free(rb);
}

