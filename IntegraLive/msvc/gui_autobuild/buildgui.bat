echo building gui to %1, 

if exist %1 rd /s /q %1

set olddirectory=%CD%

set ADT="%AIR_SDK_PATH%/bin/adt"
set AMXMLC="%FLEX_SDK_PATH%/bin/amxmlc"

set CONFIG=app-config.xml
set AMXMLC_DEBUG=-compiler.verbose-stacktraces
set AMXMLC_FLAGS=%AMXMLC_DEBUG% -load-config %CONFIG%

cd ../../gui/src

rem tortuously escape the ADOBE_FLEX_PATH string 

set ENVIRONMENT_PATH=/..

set FLEX_PATH_FILE=flex_path.txt
set FLEX_PATH_FILE_ESCAPED=flex_path_escaped.txt
echo %FLEX_SDK_PATH%>%FLEX_PATH_FILE%
"%olddirectory%/gui_autobuild/sed" -e "s|\\|/|g" -e "s| |\\ |g" -e "s/*//;s/ *$//" %FLEX_PATH_FILE% > %FLEX_PATH_FILE_ESCAPED%

set /p ADOBE_FLEX_PATH=<%FLEX_PATH_FILE_ESCAPED%
del %FLEX_PATH_FILE%
del %FLEX_PATH_FILE_ESCAPED%

rem build app-config.xml

"%olddirectory%/gui_autobuild/sed" -e "s|@ENVIRONMENT_PATH@|%ENVIRONMENT_PATH%|g" -e "s|@ADOBE_FLEX_PATH@|%ADOBE_FLEX_PATH%|g" %CONFIG%.in > %CONFIG%

rem build IntegraLive-app.xml

set /p VERSION_NUMBER=<../../BASEVERSION
set /p VERSION_LABEL=<../../FULLVERSION
"%olddirectory%/gui_autobuild/sed" -e "s|<versionNumber>\(.*\)</versionNumber>|<versionNumber>%VERSION_NUMBER%</versionNumber>|g" -e "s|<versionLabel>\(.*\)</versionLabel>|<versionLabel>Version %VERSION_LABEL%</versionLabel>|g" IntegraLive-app.xml.in > IntegraLive-app.xml

rem build the swf

echo building swf...
call %AMXMLC% %AMXMLC_FLAGS% IntegraLive.mxml
echo built swf.

rem package it

echo packaging...
%ADT% -package -storetype pkcs12 -keystore integraCert.pfx -storepass integra -tsa "http://sha256timestamp.ws.symantec.com/sha256/timestamp" -target bundle "%olddirectory%\%1" IntegraLive-app.xml IntegraLive.swf icons assets
echo packaged.

del IntegraLive.swf

cd %olddirectory%

