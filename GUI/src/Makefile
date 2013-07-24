
# IntegraLive GUI
#####################################
#
# rather than modifying this Makefile, create a Make.config file
# in which you can adjust the following variables to your needs
#
# the variables you most likely will want to adjust are
# FLEX_SDK_PATH and AIR_SDK_PATH

-include Make.config

PRODUCT="Integra Live"
CONFIG=app-config.xml
DESCRIPTOR=IntegraLive-app.xml
ARGS=

MODULES=$(SVNROOT)/modules/trunk
BLOCKDIR=$(SVNROOT)/blocks

CERTIFICATE=integraCert.pfx

#FLEX_SDK_PATH=
#AIR_SDK_PATH=

ADL_FLAGS=-profile extendedDesktop #-nodebug
AMXMLC_DEBUG= -compiler.verbose-stacktraces
AMXMLC_FLAGS=$(AMXMLC_DEBUG) -load-config $(CONFIG)

# do not edit below this line
#####################################


ADL=$(AIR_SDK_PATH)/bin/adl
ADT=$(AIR_SDK_PATH)/bin/adt
AMXMLC=$(FLEX_SDK_PATH)/bin/amxmlc

SED = sed
CURL = curl

BASEVERSION = $(shell cat $(SVNROOT)/BASEVERSION)
FULLVERSION = $(shell cat $(SVNROOT)/FULLVERSION)

.PHONY: $(DESCRIPTOR) clean

all:  IntegraLive.swf

run:
	$(ADL) $(ADL_FLAGS) $(DESCRIPTOR) -- $(ARGS)

$(DESCRIPTOR): $(DESCRIPTOR).in
	$(SED)  -e 's|x.x.x.xxxx|$(FULLVERSION)|g' -e 's|x.x.x|$(BASEVERSION)|g' $< > $@

IntegraLive.swf: $(CONFIG) $(DESCRIPTOR) BlockLibrary
	$(AMXMLC) $(AMXMLC_FLAGS) IntegraLive.mxml

BlockLibrary:
	-mkdir BlockLibrary
	cp $(SVNROOT)/blocks/* BlockLibrary/

key:
	if [ ! -e $(CERTIFICATE) ]; then \
	    $(ADT) -certificate -cn SelfSigned 1024-RSA $(CERTIFICATE) integra;\
	fi

app: IntegraLive.swf key
	$(ADT) -package -storetype pkcs12 -keystore $(CERTIFICATE) -storepass integra -target bundle Integra\ Live.app IntegraLive-app.xml IntegraLive.swf assets
	# Do this separately otherwise adt complains:
	# "is not part of a Mac OS X Native Extensions framework"
	cp -r BlockLibrary $(PRODUCT).app/Contents/Resources
	# Copy in correct .icns files - AIR XML file doesn't support 1024x1024 retina!
	cp icons/*.icns $(PRODUCT).app/Contents/Resources

clean:
	-@rm -f IntegraLive.swf
	-@rm -f *.bak
	-@rm -f $(CONFIG)
	-@rm -f $(CERTIFICATE)
	-@rm -f $(DESCRIPTOR)
	-@rm -rf $(PRODUCT).app
	-@rm -rf BlockLibrary
	-@rm -rf *.tmp
 

$(CONFIG): $(CONFIG).in
	$(SED) -e "s|@ENVIRONMENT_PATH@|$(shell pwd)/..|g" -e "s|@ADOBE_FLEX_PATH@|$(FLEX_SDK_PATH)|g" $< > $@
