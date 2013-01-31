@echo off

rem this batch file stamps the version number from the VERSION file into the exe or dll located at parameter %1

set /p version= <../../FULLVERSION

versioning\StampVer.exe -f"%version%.0" -p"%version%.0" %1

