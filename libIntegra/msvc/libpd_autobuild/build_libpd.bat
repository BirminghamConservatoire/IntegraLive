echo building libpd...

set olddirectory=%CD%

cd ../externals/libpd

make

cd libs

lib /machine:i386 /def:libpd.def

cd %olddirectory%