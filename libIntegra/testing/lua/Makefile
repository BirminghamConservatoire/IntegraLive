
LIBSPATH=../../src/.libs/

LIBS =  -L$(LIBSPATH) -lIntegra


all: a.out

run: a.out
	LD_LIBRARY_PATH=$(LIBSPATH):${LD_LIBRARY_PATH} ./a.out 8000

gdb: a.out
	LD_LIBRARY_PATH=$(LIBSPATH):${LD_LIBRARY_PATH} gdb ./a.out 8000

a.out: main.c Makefile $(LIBSPATH)libIntegra.so
	gcc -Wall -g -I../.. main.c $(LIBS)

