echo cleaning libpd...

set olddirectory=%CD%

cd ../../../libpd

make clean

cd %olddirectory%