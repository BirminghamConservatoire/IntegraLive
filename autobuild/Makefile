PRODUCT=Integra\ Live
CREATORPRODUCT=Module\ Creator
APPNAME=$(PRODUCT).app
CREATORAPPNAME=$(CREATORPRODUCT).app
RESDIR=Contents/Resources
APPRESDIR=$(APPNAME)/$(RESDIR)
CREATORRESIDR=$(CREATORAPPNAME)/$(RESDIR)
NAMESPACE=integra
REPOSITORYROOT=..
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

GDB=gdb --args

.PHONY:

all: $(DEFAULTBUILD)
	
movedirs:
	mv server/* $(APPRESDIR)
	mv documentation $(APPRESDIR)

release: server gui documentation movedirs
	#cd $(APPNAME) && find ./ -name .REPOSITORY | xargs rm -rf && cd ..
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

clean: server-clean gui-clean
	make -C $(DOCDIR)/markdown clean
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

