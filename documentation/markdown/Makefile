DOCS=quick-start-guide scripting1 scripting2 module-development-guide module-development-quickstart acknowledgements
PICS=../page-images

all: $(PICS) $(DOCS)

clean: $(DOCS:=_clean) $(PICS:=_clean)

force:

$(DOCS:=_clean): force
	$(MAKE) -C $(@:_clean=) clean

$(PICS:=_clean): force
	$(MAKE) -C $(@:_clean=) clean

$(DOCS): force
	$(MAKE) -C $@

$(PICS): force
	$(MAKE) -C $@
