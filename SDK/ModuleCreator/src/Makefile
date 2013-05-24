
# ModuleCreator Integra Interface Creator
###################################################
#
# rather than modifying this Makefile, create a Make.config file
# in which you can adjust the following variables to your needs
#
# the variables you most likely will want to adjust are
# FLEX_SDK_PATH and AIR_SDK_PATH

PRODUCT="Integra Module Creator"
SWFNAME="ModuleCreator"
CONFIG=app-config.xml
DESCRIPTOR=ModuleCreator-app.xml
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

.PHONY: $(DESCRIPTOR) clean

all:  $(SWFNAME).swf

run:
	$(ADL) $(ADL_FLAGS) $(DESCRIPTOR) -- $(ARGS)

$(SWFNAME).swf: $(CONFIG)
	$(AMXMLC) $(AMXMLC_FLAGS) ModuleCreator.mxml

key:
	if [ ! -e $(CERTIFICATE) ]; then \
	    $(ADT) -certificate -cn SelfSigned 1024-RSA $(CERTIFICATE) integra;\
	fi

app: $(SWFNAME).swf key
	$(ADT) -package -storetype pkcs12 -keystore $(CERTIFICATE) -storepass integra -target bundle $(PRODUCT).app ModuleCreator-app.xml $(SWFNAME).swf assets


air: $(SWFNAME).swf key
	$(ADT) -package -storetype pkcs12 -keystore $(CERTIFICATE) -storepass integra $(PRODUCT).air ModuleCreator-app.xml $(SWFNAME).swf assets

clean:
	-@rm -f $(SWFNAME).swf
	-@rm -f *.bak
	-@rm -f app-config.xml
	-@rm -f $(CERTIFICATE)
	-@rm -rf $(PRODUCT).app

$(CONFIG): $(CONFIG).in
	$(SED) -e "s|@ENVIRONMENT_PATH@|$(shell pwd)/..|g" -e "s|@ADOBE_FLEX_PATH@|$(FLEX_SDK_PATH)|g" $< > $@
