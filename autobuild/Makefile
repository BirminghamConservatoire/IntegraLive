PRODUCT=Integra\ Live
CREATORPRODUCT=Module\ Creator
APPNAME=$(PRODUCT).app
CREATORAPPNAME=$(CREATORPRODUCT).app
RESDIR=Contents/Resources
APPRESDIR=$(APPNAME)/$(RESDIR)
CREATORRESIDR=$(CREATORAPPNAME)/$(RESDIR)
NAMESPACE=integra
PDPATH=
SVNROOT=..
MODULES=$(SVNROOT)/modules
SCHEMADIR=$(MODULES)/XML/schemas
GUIDIR=$(SVNROOT)/GUI/src
CREATORDIR=$(SVNROOT)/SDK/ModuleCreator/src
DOCDIR=$(SVNROOT)/documentation
LIBINTEGRAPATH=$(SVNROOT)/libIntegra
DEFAULTBUILD=release
INTEGRA_BASE_URL=http://www.integralive.org/incoming
LIBINTEGRADEPS_DIR=libIntegra-dependencies-OSX
LIBINTEGRADEPS_FILE=$(LIBINTEGRADEPS_DIR).tar.gz
LIBINTEGRADEPS_URL=$(INTEGRA_BASE_URL)/$(LIBINTEGRADEPS_FILE)
DEPENDENCIESDIR=$(PWD)/$(LIBINTEGRADEPS_DIR)/lib
SDKROOT=$(SVNROOT)/SDK
TEMPLATESDIR=$(SDKROOT)/templates
FSPLAY=fsplay~

SERVERDIR=server
SERVERBIN=$(SERVERDIR)/bin
SERVERLIB=$(SERVERDIR)/lib
SERVERMAKESUFFIX=CC='gcc -mmacosx-version-min=10.6 -arch i386 -arch x86_64' CXX='g++ -mmacosx-version-min=10.6 -arch i386 -arch x86_64' CPP='gcc -E -mmacosx-version-min=10.6 -arch i386' CXXCPP='g++ -E -mmacosx-version-min=10.6 -arch i386'
SERVERCONFIGBASE=--disable-dependency-tracking --enable-luascripting --enable-server --enable-dummy_bridge --enable-osc_bridge --prefix=$(PWD)/$(SERVERDIR) --with-lua=$(PWD)/$(LIBINTEGRADEPS_DIR) --with-liblo-include-dir=$(PWD)/$(LIBINTEGRADEPS_DIR)/include
WERROR=#--enable-Werror
SERVERCONFIGDEBUG=$(SERVERCONFIGBASE) --enable-debug=yes $(WERROR) LDFLAGS="-L$(DEPENDENCIESDIR)"
SERVERCONFIGRELEASE=$(SERVERCONFIGBASE) --enable-debug=no LDFLAGS="-L$(DEPENDENCIESDIR)"

-include Make.config

PD_DMG_NAME=$(PD_VERSION_NAME).dmg
PD_APP_NAME=$(PD_VERSION_NAME).app
PD_MOUNT_NAME=Pd-extended
PD_MOUNT_POINT=/Volumes/$(PD_MOUNT_NAME)
PD_OSC_HOST=$(SVNROOT)/host/Pd/Integra_Host.pd

GDB=gdb --args

.PHONY:

all: $(DEFAULTBUILD)
	
movedirs:
	mv server $(APPRESDIR)
	mv host $(APPRESDIR)
	mv documentation $(APPRESDIR)
	mv modules $(APPRESDIR)

debug: server-debug host gui modules documentation movedirs

release: server-release host gui modules documentation movedirs
	cd $(APPNAME) && find ./ -name .svn | xargs rm -rf && cd ..
	# codesign --deep --force -f -v -s "3rd Party Mac Developer Application: Birmingham City" --entitlements entitlements.plist $(APPNAME)

dmg: $(DEFAULTBUILD)
	if [ ! -e $(PRODUCT)_temp.dmg ]; then \
	    hdiutil create -megabytes 300 -fs HFS+ -volname $(PRODUCT) $(PRODUCT)_temp.dmg; \
	fi
	hdiutil mount $(PRODUCT)_temp.dmg
	#rsync -av $(APPNAME) /Volumes/$(PRODUCT)
	mv $(APPNAME) /Volumes/$(PRODUCT)
	hdiutil detach /Volumes/$(PRODUCT)
	-rm -f $(PRODUCT).dmg
	hdiutil convert $(PRODUCT)_temp.dmg -format UDZO -imagekey zlib-level=9 -o $(PRODUCT).dmg
	rm $(PRODUCT)_temp.dmg
	#codesign -f -v -s "3rd Party Mac Developer Installer: Birmingham City University" $(PRODUCT).dmg

dropdmg: $(DEFAULTBUILD)
	-mkdir $(PRODUCT)
	-cp .VolumeIcon.icns $(PRODUCT)
	-cp -r $(APPNAME) $(PRODUCT)
	dropdmg --config-name="Integra Live" $(PRODUCT)
	-rm -rf $(PRODUCT)

creator-dropdmg: creator
	-mkdir $(CREATORPRODUCT)
	-cp .VolumeIcon.icns $(CREATORPRODUCT)
	-cp -r $(CREATORAPPNAME) $(CREATORPRODUCT)
	dropdmg --config-name="Developer SDK" $(CREATORPRODUCT)
	-rm -rf $(CREATORPRODUCT)
	
run: 
	open $(APPNAME)

run-server-debug:
	cd $(APPNAME)/Contents/Resources/server/bin && gdb --args ./integra_server -bridge=../lib/integra/integra_osc_bridge.so -xmlrpc_server_port=8003 -osc_server_port=8004 -osc_client_port=8005 -osc_client_url=127.0.0.1 -system_modules=../../modules -third_party_modules=./ThirdPartyModules -trace_progress=1 -host=../../host/bin/pd_integra -hostargs=../../host/extra/Integra_Host.pd
	

run-gui:
	make -C $(GUIDIR) run

server-dependencies:
	if [ ! -d $(LIBINTEGRADEPS_DIR) ]; then \
	    wget $(LIBINTEGRADEPS_URL);\
	    tar zxf $(LIBINTEGRADEPS_FILE); \
	fi

server-configure-release: server-dependencies
	cd $(LIBINTEGRAPATH) && ./configure $(SERVERCONFIGRELEASE) $(SERVERCONFIGSUFFIX) PATH=$(PATH):$(PWD)/$(LIBINTEGRADEPS_DIR)/bin && cd -

server-configure-debug: server-dependencies
	cd $(LIBINTEGRAPATH) && ./configure $(SERVERCONFIGDEBUG) $(SERVERCONFIGSUFFIX) PATH=$(PATH):$(PWD)/$(LIBINTEGRADEPS_DIR)/bin && cd -

server:
	make -C $(LIBINTEGRAPATH) $(SERVERMAKESUFFIX)

	make -C $(LIBINTEGRAPATH) install
	# do what we can automatically
	cd server/bin; \
	    sudo ruby ../../localize_dependencies.rb integra_server ../lib;\
	    sudo ruby ../../localize_dependencies.rb ../lib/integra/integra_osc_bridge.so ../lib;\
	    sudo ruby ../../localize_dependencies.rb ../lib/libIntegra.0.dylib ../lib
	cp server/share/libintegra/CollectionSchema.xsd server/bin/
	cp server/share/libintegra/id2guid.csv server/bin/

server-debug: server-configure-debug server

server-release: server-configure-release server

gui:
	make -C $(GUIDIR) app
	rm -rf $(APPNAME)
	mv $(GUIDIR)/$(APPNAME) ./
	touch $(APPNAME)/Contents/Resources/META-INF/AIR/debug

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
	
host:
	if [ ! -e $(PD_DMG_NAME) ]; then \
	    echo downloading $(PD_DMG_NAME); \
	    wget $(PD_BASE_URL)/$(PD_DMG_NAME); \
	fi
	yes | hdiutil mount $(PD_DMG_NAME) > /dev/null
	cp -r $(PD_MOUNT_POINT)/*.app/Contents/Resources host
	find ./host -type d -exec chmod 755 {} \;
	sh remove_externals.sh
	if [ ! -e $(FSPLAY).zip ]; then \
		wget http://integralive.org/incoming/$(FSPLAY).zip; \
	fi
	unzip $(FSPLAY).zip
	mv $(FSPLAY)/* host/extra/
	rm -rf $(FSPLAY)
	cp $(PD_MOUNT_POINT)/*.app/Contents/lib/libfftw3f.3.dylib host/extra/bsaylor
	cd host/extra/bsaylor && chmod 644 partconv~.pd_darwin && install_name_tool -change @executable_path/../../lib/libfftw3f.3.dylib @loader_path/libfftw3f.3.dylib partconv~.pd_darwin && cd -
	cp $(PD_OSC_HOST) host/extra
	rm -rf extra
	cd host/bin; cp -f pd pd_integra; rm -f pd; ln -s pd_integra pd

modules: host server
	-mkdir modules
	-cp $(MODULES)/* ./modules

documentation:
	make -C $(DOCDIR)/markdown
	mkdir -p documentation/html
	-cp -r $(DOCDIR)/page-images documentation/
	-cp -r $(DOCDIR)/markdown/* documentation/html
	find ./documentation/html/ -not -name *.htm -exec rm -f {} \;

server-clean:
	make -C $(LIBINTEGRAPATH) clean
	-rm -rf server

dependencies-clean:
	-rm -rf $(LIBINTEGRADEPS_DIR)
	-rm $(LIBINTEGRADEPS_FILE)

gui-clean:
	make -C $(GUIDIR) clean

clean: server-clean gui-clean
	make -C $(DOCDIR)/markdown clean
	-rm -rf host
	-rm -rf documentation
	-diskutil unmount $(PD_MOUNT_NAME)
	-diskutil unmount $(PRODUCT)
	-rm -rf $(APPNAME)
	-rm -rf $(PRODUCT).dmg
	-rm -rf $(CREATORAPPNAME)


maintainer-clean: clean dependencies-clean
	-rm *.dmg
	make -C $(LIBINTEGRAPATH) maintainer-clean
	cd $(LIBINTEGRAPATH) && ./autogen.sh && cd -


upload:
	scp Integra\ Live.dmg postlude@frs.sourceforge.net:/home/frs/project/integralive/

