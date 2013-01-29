
# ModuleCreator Integra Interface Creator
###################################################
#
# rather than modifying this Makefile, create a Make.config file
# in which you can adjust the following variables to your needs
#
# the variables you most likely will want to adjust are
# FLEX_SDK_PATH and AIR_SDK_PATH

PRODUCT="ModuleCreator"
CONFIG=app-config.xml
DESCRIPTOR=ModuleCreator-app.xml
ARGS=
SVNROOT=../../..

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

.PHONY: $(DESCRIPTOR) clean

all:  ModuleCreator.swf

run:
	$(ADL) $(ADL_FLAGS) $(DESCRIPTOR) -- $(ARGS)

ModuleCreator.swf: $(CONFIG)
	$(AMXMLC) $(AMXMLC_FLAGS) ModuleCreator.mxml

key:
	if [ ! -e $(CERTIFICATE) ]; then \
	    $(ADT) -certificate -cn SelfSigned 1024-RSA $(CERTIFICATE) integra;\
	fi

app: ModuleCreator.swf key
	$(ADT) -package -storetype pkcs12 -keystore $(CERTIFICATE) -storepass integra -target bundle ModuleCreator.app ModuleCreator-app.xml ModuleCreator.swf assets


air: ModuleCreator.swf key
	$(ADT) -package -storetype pkcs12 -keystore $(CERTIFICATE) -storepass integra ModuleCreator.air ModuleCreator-app.xml ModuleCreator.swf assets

clean:
	-@rm -f ModuleCreator.swf
	-@rm -f *.bak
	-@rm -f app-config.xml
	-@rm -f $(CERTIFICATE)
	-@rm -rf $(PRODUCT).app

$(CONFIG): $(CONFIG).in
	$(SED) -e "s|@ENVIRONMENT_PATH@|$(shell pwd)/..|g" -e "s|@ADOBE_FLEX_PATH@|$(FLEX_SDK_PATH)|g" $< > $@
