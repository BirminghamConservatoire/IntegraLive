MAINTAINERCLEANFILES = Makefile.in

bridgedir = $(libdir)/integra


bridge_LTLIBRARIES = \
		     integra_dummy_bridge.la

integra_dummy_bridge_la_CFLAGS = $(CFLAGS) $(PD_CFLAGS) -DPD -I./deps
integra_dummy_bridge_la_LDFLAGS = -module -avoid-version
integra_dummy_bridge_la_SOURCES = integra_dummy_bridge.c

#Adapted from swh LADSPA bridges. 
install-bridgeLTLIBRARIES: $(bridge_LTLIBRARIES)
	mkdir -p $(bridgedir)
	list='$(bridge_LTLIBRARIES)'; \
	for file in $$list; do \
	  sofile=`basename $$file .la`.so; \
	  $(INSTALL_PROGRAM) .libs/$$sofile $(bridgedir); \
	done

uninstall-bridgeLTLIBRARIES:
	list='$(bridge_LTLIBRARIES)'; \
	for file in $$list; do \
	  sofile=`basename $$file .la`.so; \
	  rm -f $(bridgedir)/$$sofile; \
	done
