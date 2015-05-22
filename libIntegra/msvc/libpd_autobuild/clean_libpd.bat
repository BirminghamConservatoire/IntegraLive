echo cleaning libpd...

set olddirectory=%CD%

cd ../externals/libpd

make clean

cd %olddirectory%