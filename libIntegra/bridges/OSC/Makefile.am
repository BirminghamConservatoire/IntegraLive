MAINTAINERCLEANFILES = Makefile.in

bridge_name = integra_osc_bridge

integra_osc_bridgedir = $(libdir)/integra
integra_osc_bridge_LTLIBRARIES = integra_osc_bridge.la
integra_osc_bridge_la_CFLAGS = $(CFLAGS) $(OSC_CFLAGS) -DOSC
integra_osc_bridge_la_LDFLAGS = -module -shared -avoid-version -llo
integra_osc_bridge_la_SOURCES = integra_osc_bridge.c

install-exec-hook:
	$(LINK_DLL)
	$(INSTALL_DLL)
	
clean-local:
	$(CLEAN_DLL)

uninstall-hook:
	$(UNINSTALL_DLL)
	
