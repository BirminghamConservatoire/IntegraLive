/* For information on usage and redistribution, and for a DISCLAIMER OF ALL
* WARRANTIES, see the file, "LICENSE.txt," in this distribution.

iemlib1 written by Thomas Musil, Copyright (c) IEM KUG Graz Austria 2000 - 2006 */

#include "m_pd.h"
#include "iemlib.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

#define SFI_HEADER_SAMPLERATE 0
#define SFI_HEADER_FILENAME 1
#define SFI_HEADER_MULTICHANNEL_FILE_LENGTH 2
#define SFI_HEADER_HEADERBYTES 3
#define SFI_HEADER_CHANNELS 4
#define SFI_HEADER_BYTES_PER_SAMPLE 5
#define SFI_HEADER_ENDINESS 6

#define SFI_HEADER_SIZE 7



/* --------------------------- soundfile_info -------------------------------- */
/* -- reads only header of a wave-file and outputs the important parameters -- */

static t_class *soundfile_info_class;

typedef struct _soundfile_info
{
  t_object  x_obj;
  long      *x_begmem;
  int       x_size;
  t_atom    x_atheader[SFI_HEADER_SIZE];
  t_canvas  *x_canvas;
  void      *x_list_out;
} t_soundfile_info;

static short soundfile_info_str2short(char *cvec)
{
  short s=0;
  unsigned char *uc=(unsigned char *)cvec;
  
  s += (short)(*uc);
  s += (short)(*(uc+1)*256);
  return(s);
}

static long soundfile_info_str2long(char *cvec)
{
  long l=0;
  unsigned char *uc=(unsigned char *)cvec;
  
  l += (long)(*uc);
  l += (long)(*(uc+1)*256);
  l += (long)(*(uc+2)*65536);
  l += (long)(*(uc+3)*16777216);
  return(l);
}

static void soundfile_info_read(t_soundfile_info *x, t_symbol *filename)
{
  char completefilename[400];
  int i, n, n2, n4, filesize, read_chars, header_size=0, ch, bps, sr;
  FILE *fh;
  t_atom *at;
  char *cvec;
  long ll;
  short ss;
  
  if(filename->s_name[0] == '/')/*make complete path + filename*/
  {
    strcpy(completefilename, filename->s_name);
  }
  else if(((filename->s_name[0] >= 'A')&&(filename->s_name[0] <= 'Z')||
    (filename->s_name[0] >= 'a')&&(filename->s_name[0] <= 'z'))&&
    (filename->s_name[1] == ':')&&(filename->s_name[2] == '/'))
  {
    strcpy(completefilename, filename->s_name);
  }
  else
  {
    strcpy(completefilename, canvas_getdir(x->x_canvas)->s_name);
    strcat(completefilename, "/");
    strcat(completefilename, filename->s_name);
  }
  
  fh = fopen(completefilename,"rb");
  if(!fh)
  {
    post("soundfile_info_read: cannot open %s !!\n", completefilename);
  }
  else
  {
    n = x->x_size;
    n2 = sizeof(short) * x->x_size;
    n4 = sizeof(long) * x->x_size;
    fseek(fh, 0, SEEK_END);
    filesize = ftell(fh);
    fseek(fh,0,SEEK_SET);
    read_chars = (int)fread(x->x_begmem, sizeof(char), n4, fh) /2;
    fclose(fh);
    //    post("read chars = %d", read_chars);
    cvec = (char *)x->x_begmem;
    if(read_chars > 4)
    {
      if(strncmp(cvec, "RIFF", 4))
      {
        post("soundfile_info_read-error:  %s is no RIFF-WAVE-file", completefilename);
        goto soundfile_info_end;
      }
      header_size += 8;
      cvec += 8;
      if(strncmp(cvec, "WAVE", 4))
      {
        post("soundfile_info_read-error:  %s is no RIFF-WAVE-file", completefilename);
        goto soundfile_info_end;
      }
      header_size += 4;
      cvec += 4;
      
      for(i=header_size/2; i<read_chars; i++)
      {
        if(!strncmp(cvec, "fmt ", 4))
          goto soundfile_info_fmt;
        header_size += 2;
        cvec += 2;
      }
      post("soundfile_info_read-error:  %s has at begin no format-chunk", completefilename);
      goto soundfile_info_end;
      
soundfile_info_fmt:
      header_size += 4;
      cvec += 4;
      ll = soundfile_info_str2long(cvec);
      if(ll != 16)
      {
        post("soundfile_info_read-error:  %s has a format-chunk not equal to 16", completefilename);
        goto soundfile_info_end;
      }
      header_size += 4;
      cvec += 4;
      ss = soundfile_info_str2short(cvec);
      /* format */
      if(ss != 1)            /* PCM = 1 */
      {
        post("soundfile_info_read-error:  %s is not PCM-format coded", completefilename);
        goto soundfile_info_end;
      }
      header_size += 2;
      cvec += 2;
      ss = soundfile_info_str2short(cvec);
      /* channels */
      if((ss < 1) || (ss > 100))
      {
        post("soundfile_info_read-error:  %s has no common channel-number", completefilename);
        goto soundfile_info_end;
      }
      SETFLOAT(x->x_atheader+SFI_HEADER_CHANNELS, (t_float)ss);
      ch = ss;
      header_size += 2;
      cvec += 2;
      ll = soundfile_info_str2long(cvec);
      /* samplerate */
      if((ll > 400000) || (ll < 200))
      {
        post("soundfile_info_read-error:  %s has no common samplerate", completefilename);
        goto soundfile_info_end;
      }
      SETFLOAT(x->x_atheader+SFI_HEADER_SAMPLERATE, (t_float)ll);
      sr = ll;
      header_size += 4;
      cvec += 4;
      
      header_size += 4; /* bytes_per_sec */
      cvec += 4;
      ss = soundfile_info_str2short(cvec);
      
      /* bytes_per_sample */
      if((ss < 1) || (ss > 100))
      {
        post("soundfile_info_read-error:  %s has no common number of bytes per sample", completefilename);
        goto soundfile_info_end;
      }
      SETFLOAT(x->x_atheader+SFI_HEADER_BYTES_PER_SAMPLE, (t_float)(ss/ch));
      bps = ss;
      header_size += 2;
      cvec += 2;
      
      header_size += 2; /* bits_per_sample */
      cvec += 2;
      
      for(i=header_size/2; i<read_chars; i++)
      {
        if(!strncmp(cvec, "data", 4))
          goto soundfile_info_data;
        header_size += 2;
        cvec += 2;
      }
      post("soundfile_info_read-error:  %s has at begin no data-chunk", completefilename);
      goto soundfile_info_end;
      
soundfile_info_data:
      header_size += 8;
      cvec += 8;
      
      SETFLOAT(x->x_atheader+SFI_HEADER_HEADERBYTES, (t_float)header_size);
      
      filesize -= header_size;
      filesize /= bps;
      SETFLOAT(x->x_atheader+SFI_HEADER_MULTICHANNEL_FILE_LENGTH, (t_float)filesize);
      SETSYMBOL(x->x_atheader+SFI_HEADER_ENDINESS, gensym("l"));
      SETSYMBOL(x->x_atheader+SFI_HEADER_FILENAME, gensym(completefilename));
      
      /*      post("ch = %d", ss);
      post("sr = %d", ll);
      post("bps = %d", ss/ch);
      post("head = %d", header_size);
      post("len = %d", filesize);*/
      
      outlet_list(x->x_list_out, &s_list, SFI_HEADER_SIZE, x->x_atheader);
      
      
soundfile_info_end:
      
      ;
    }
  }
}

static void soundfile_info_free(t_soundfile_info *x)
{
  freebytes(x->x_begmem, x->x_size * sizeof(long));
}

static void *soundfile_info_new(void)
{
  t_soundfile_info *x = (t_soundfile_info *)pd_new(soundfile_info_class);
  
  x->x_size = 10000;
  x->x_begmem = (long *)getbytes(x->x_size * sizeof(long));
  x->x_list_out = outlet_new(&x->x_obj, &s_list);
  x->x_canvas = canvas_getcurrent();
  return (x);
}

/* ---------------- global setup function -------------------- */

void soundfile_info_setup(void)
{
  soundfile_info_class = class_new(gensym("soundfile_info"), (t_newmethod)soundfile_info_new,
    (t_method)soundfile_info_free, sizeof(t_soundfile_info), 0, 0);
  class_addmethod(soundfile_info_class, (t_method)soundfile_info_read, gensym("read"), A_SYMBOL, 0);
//  class_sethelpsymbol(soundfile_info_class, gensym("iemhelp/help-soundfile_info"));
}
