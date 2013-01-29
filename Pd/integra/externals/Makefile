# include PD_PATH="path/to/pd" in Makefile.config
-include Makefile.config
PD_INCLUDE=$(PD_PATH)/src
FAT_FLAGS=""

EXTERNALS=audiosettings bsaylor iemnet zexy/src osc hcs ext13 pluginhost~ freeverb~

.PHONY=all $(EXTERNALS) clean install force



all: premake $(EXTERNALS) osc postmake


install: $(EXTERNALS:=_install)

clean: $(EXTERNALS:=_clean)

force:

$(EXTERNALS:=_install): force
	$(MAKE) -C $(@:_install=) install

$(EXTERNALS:=_clean): force
	$(MAKE) -C $(@:_clean=) clean

premake:
#	cp osc/Makefile osc/Makefile.svn
#	cp osc/Makefile.alt osc/Makefile

postmake:
#	cp osc/Makefile.svn osc/Makefile

$(EXTERNALS): force
	$(MAKE) -C $@ PD_PATH=$(PD_PATH) PD_INCLUDE=$(PD_INCLUDE) FAT_FLAGS=$(FAT_FLAGS)

