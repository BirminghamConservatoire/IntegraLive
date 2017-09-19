REPOSITORYROOT=../..
PRODUCT=Integra\ Live
CREATORPRODUCT=Module\ Creator

APPNAME=$(PRODUCT).app
PDVERSION=0.43-3
PDDLPATH=0.43.3
PDPREFIX=pd-$(PDVERSION)
PDAPPNAME=$(PDPREFIX).app
PDGZNAME=$(PDPREFIX).mac.tar.gz
EXTRABINDIR=../../libIntegra/externals/macosx/extra
PDDLBASE=http://downloads.sourceforge.net/project/pure-data/pure-data
CREATORAPPNAME=$(CREATORPRODUCT).app
RESDIR=Contents/Resources
APPRESDIR=$(APPNAME)/$(RESDIR)
CREATORRESIDR=$(CREATORAPPNAME)/$(RESDIR)
NAMESPACE=integra
MODULES=$(REPOSITORYROOT)/modules
SCHEMADIR=$(MODULES)/XML/schemas
GUIDIR=$(REPOSITORYROOT)/GUI/src
SERVERDIR=$(REPOSITORYROOT)/server
CREATORDIR=$(REPOSITORYROOT)/SDK/ModuleCreator/src
DOCDIR=$(REPOSITORYROOT)/documentation
DEFAULTBUILD=release
INTEGRA_BASE_URL=http://www.integralive.org/incoming
SDKROOT=$(REPOSITORYROOT)/SDK
TEMPLATESDIR=$(SDKROOT)/templates
PDHOSTDIR=$(CREATORRESIDR)/$(APPNAME)/Contents/Resources/host

-include Make.config

GDB=gdb --args

.PHONY: dropdmg

all: $(DEFAULTBUILD)
	
movedirs:
	mv server/* $(APPRESDIR)
	mv documentation $(APPRESDIR)

release: server gui documentation movedirs

dmg: $(DEFAULTBUILD)
	if [ ! -e $(PRODUCT)_temp.dmg ]; then \
	    hdiutil create -megabytes 300 -fs HFS+ -volname $(PRODUCT) $(PRODUCT)_temp.dmg; \
	fi
	hdiutil mount $(PRODUCT)_temp.dmg
	mv $(APPNAME) /Volumes/$(PRODUCT)
	hdiutil detach /Volumes/$(PRODUCT)
	-rm -f $(PRODUCT).dmg
	hdiutil convert $(PRODUCT)_temp.dmg -format UDZO -imagekey zlib-level=9 -o $(PRODUCT).dmg
	rm $(PRODUCT)_temp.dmg

dropdmg: $(DEFAULTBUILD)
	-mkdir $(PRODUCT)
	-cp .VolumeIcon.icns $(PRODUCT)
	-cp -R $(APPNAME) $(PRODUCT)
	codesign --deep --force -s $(CERTIFICATENAME) --entitlements entitlements.plist $(PRODUCT)/$(APPNAME)
	dropdmg --config-name="Integra Live" $(PRODUCT)
	-rm -rf $(PRODUCT)

creator-dropdmg:
	-mkdir $(CREATORPRODUCT)
	-cp .VolumeIcon.icns $(CREATORPRODUCT)
	-cp -R $(CREATORAPPNAME) $(CREATORPRODUCT)
	codesign --deep --force -s $(CERTIFICATENAME) --entitlements entitlements.plist $(CREATORPRODUCT)/$(CREATORAPPNAME)
	dropdmg --config-name="Developer SDK" $(CREATORPRODUCT)
	-rm -rf $(CREATORPRODUCT)
	
gui:
	make -C $(GUIDIR) app
	rm -rf $(APPNAME)
	mv $(GUIDIR)/$(APPNAME) ./
	touch $(APPNAME)/Contents/Resources/META-INF/AIR/debug

server:
	mkdir server
	xcodebuild -project $(SERVERDIR)/xcode/integra_server/integra_server.xcodeproj -scheme integra_server -configuration Release CONFIGURATION_BUILD_DIR=`pwd`/server
	rm -rf server/*.dSYM
	# FIX! For now move csv and xsd to be sibling of integra_server
	mv server/Integra.framework/Resources/*.csv server/Integra.framework/Resources/*.xsd server/

server-clean:
	rm -rf server


host:
	curl -L $(PDDLBASE)/$(PDDLPATH)/$(PDGZNAME) > $(PDGZNAME)
	tar zxf $(PDGZNAME)
	cp -r $(EXTRABINDIR)/* $(PDAPPNAME)/Contents/Resources/extra


host-clean:
	rm -rf $(PDGZNAME) $(PDAPPNAME)

creator: documentation
	@if test ! -d $(APPNAME); \
	then echo $(APPNAME) does not exist. Run 'make release' first. && exit 2; \
	fi
	make -C $(CREATORDIR) app
	rm -rf $(CREATORAPPNAME)
	mv $(CREATORDIR)/$(CREATORAPPNAME) ./
	cp -r $(TEMPLATESDIR) $(CREATORRESIDR)
	cp -r $(APPNAME) $(CREATORRESIDR)
	mv documentation $(CREATORRESIDR)
	mkdir $(PDHOSTDIR)
	cp -r $(PDAPPNAME)/Contents/Resources/* $(PDHOSTDIR)
	ln -s pd $(PDHOSTDIR)/bin/pd_integra

	
documentation:
	make -C $(DOCDIR)/markdown
	mkdir -p documentation/html
	-cp -r $(DOCDIR)/page-images documentation/
	-cp -r $(DOCDIR)/markdown/* documentation/html
	find ./documentation/html/ -not -name *.htm -exec rm -f {} \;

dependencies-clean:
	-rm -rf $(LIBINTEGRADEPS_DIR)
	-rm $(LIBINTEGRADEPS_FILE)

gui-clean:
	make -C $(GUIDIR) clean

clean: server-clean gui-clean host-clean
	make -C $(DOCDIR)/markdown clean
	-rm -rf documentation
	-diskutil unmount $(PD_MOUNT_NAME)
	-diskutil unmount $(PRODUCT)
	-rm -rf $(APPNAME)
	-rm -rf $(PRODUCT).dmg
	-rm -rf $(PRODUCT)
	-rm -rf $(CREATORAPPNAME)

maintainer-clean: clean dependencies-clean
	-rm *.dmg
	make -C $(LIBINTEGRAPATH) maintainer-clean
	cd $(LIBINTEGRAPATH) && ./autogen.sh && cd -

upload:
	scp Integra Live.dmg postlude@frs.sourceforge.net:/home/frs/project/integralive/

