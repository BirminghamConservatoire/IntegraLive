echo building libpd...

set olddirectory=%CD%

cd ../externals/libpd

make

cd %olddirectory%