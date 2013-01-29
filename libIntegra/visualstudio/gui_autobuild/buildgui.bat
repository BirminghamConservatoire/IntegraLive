echo skipping autobuild of gui - not implemented yet!

echo off
rem this is as far as I got.  Complains it can't find JRE!
rem set ADL=%AIR_SDK_PATH%/bin/adl
rem set ADT=%AIR_SDK_PATH%/bin/adt
rem set AMXMLC=%FLEX_SDK_PATH%/bin/amxmlc

rem %AMXMLC% %AMXMLC_FLAGS% IntegraLive.mxml


rem now to create the debug file in META-INF/AIR

copy NUL %1\META-INF\AIR\debug