
# SHORTNAME Integra Module Creator
###################################################
#
# rather than modifying this Makefile, create a Make.config file
# in which you can adjust the following variables to your needs
#
# the variables you most likely will want to adjust are
# FLEX_SDK_PATH and AIR_SDK_PATH

PRODUCT="Module Creator"
CONFIG=app-config.xml
SHORTNAME=ModuleCreator
SWF=$(SHORTNAME).swf
DESCRIPTOR=$(SHORTNAME)-app.xml
PASSWORD=integra
ASSETS=assets
ARGS=

CERTIFICATE=integraCert.pfx

FLEX_SDK_PATH=
AIR_SDK_PATH=

ADL_FLAGS=-profile extendedDesktop #-nodebug
AMXMLC_DEBUG= -compiler.verbose-stacktraces
AMXMLC_FLAGS=$(AMXMLC_DEBUG) -load-config $(CONFIG)

# do not edit below this line
#####################################

-include Make.config

ADL=$(AIR_SDK_PATH)/bin/adl
ADT=$(AIR_SDK_PATH)/bin/adt
AMXMLC=$(FLEX_SDK_PATH)/bin/amxmlc

SED = sed
CURL = curl

BASEVERSION = $(shell cat $(SVNROOT)/BASEVERSION)
FULLVERSION = $(shell cat $(SVNROOT)/FULLVERSION)

.PHONY: $(DESCRIPTOR) clean

all:  $(SWF)

run:
	$(ADL) $(ADL_FLAGS) $(DESCRIPTOR) -- $(ARGS)

$(SWF): $(CONFIG) $(DESCRIPTOR)
	$(AMXMLC) $(AMXMLC_FLAGS) $(SHORTNAME).mxml

key:
	if [ ! -e $(CERTIFICATE) ]; then \
	    $(ADT) -certificate -cn SelfSigned 1024-RSA $(CERTIFICATE) $(PASSWORD);\
	fi

app: $(SWF) key
	$(ADT) -package -storetype pkcs12 -keystore $(CERTIFICATE) -storepass $(PASSWORD) -target bundle $(PRODUCT).app $(DESCRIPTOR) $(SWF) $(ASSETS)


air: $(SWF) key
	$(ADT) -package -storetype pkcs12 -keystore $(CERTIFICATE) -storepass $(PASSWORD) $(PRODUCT).air $(DESCRIPTOR) $(SWF) $(ASSETS)

clean:
	-@rm -f $(SWF)
	-@rm -f *.bak
	-@rm -f app-config.xml
	-@rm -f $(CERTIFICATE)
	-@rm -f $(DESCRIPTOR)
	-@rm -f $(CONFIG)
	-@rm -rf $(PRODUCT).app
	-@rm -rf *.tmp

$(DESCRIPTOR): $(DESCRIPTOR).in
	$(SED)  -e 's|x.x.x.xxxx|$(FULLVERSION)|g' -e 's|x.x.x|$(BASEVERSION)|g' $< > $@

$(CONFIG): $(CONFIG).in
	$(SED) -e "s|@ENVIRONMENT_PATH@|$(shell pwd)/..|g" -e "s|@ADOBE_FLEX_PATH@|$(FLEX_SDK_PATH)|g" $< > $@
