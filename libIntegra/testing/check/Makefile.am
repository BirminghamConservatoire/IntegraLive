MAINTAINERCLEANFILES = Makefile.in

TESTS = check_libIntegra
check_PROGRAMS = $(TESTS)
check_libIntegra_SOURCES = check_libIntegra.c \
			   check_value.c \
			   check_path.c
check_libIntegra_CFLAGS = @CHECK_CFLAGS@ -Werror -I$(top_builddir)/src -I$(top_builddir)
check_libIntegra_LDADD = @CHECK_LIBS@ -L$(top_builddir)/src/.libs -lIntegra

