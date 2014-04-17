REM creates sdk directory.  Copies templates and license into it.  This batch file expects parameter 1 to be the output folder

if not exist %1\SDK mkdir %1\SDK

if exist %1\SDK\templates rd /s /q %1\SDK\templates
mkdir %1\SDK\templates
xcopy "..\..\SDK\templates" "%1\SDK\templates" /Y /Q /S

copy "..\..\SDK\license.txt" "%1\SDK\"

