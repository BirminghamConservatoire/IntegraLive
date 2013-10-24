copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc_abyss.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc_server.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc_server_abyss.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc_util.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc_xmlparse.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc_xmltok.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\libxml2-2.7.8.win32\bin\libxml2.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\pthreads-win32\lib\pthreadVC2.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\bin\iconv.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\zlib-1.2.5\bin\zlib1.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\lua-5.2.0\lua52.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\\portaudio\build\msvc\Win32\Debug\portaudio_x86.dll" "..\..\build\Debug\server\"
copy "..\externals\libpd\libs\libpd.dll" "..\..\build\Debug\server\"

copy "..\data\CollectionSchema.xsd" "..\..\build\Debug\server\"
copy "..\data\id2guid.csv" "..\..\build\Debug\server"

if exist ..\..\build\Debug\modules rd /s /q ..\..\build\Debug\modules
mkdir ..\..\build\Debug\modules
xcopy "..\..\modules" "..\..\build\Debug\modules" /Y /Q

if exist ..\..\build\Debug\SDK\templates rd /s /q ..\..\build\Debug\SDK\templates
mkdir ..\..\build\Debug\SDK\templates
xcopy "..\..\SDK\templates" "..\..\build\Debug\SDK\templates" /Y /Q /S

if exist ..\..\build\Debug\gui-debug\BlockLibrary rd /s /q ..\..\build\Debug\gui-debug\BlockLibrary
mkdir ..\..\build\Debug\gui-debug\BlockLibrary
xcopy "..\..\blocks" "..\..\build\Debug\gui-debug\BlockLibrary" /E /Y /Q

CALL documentation_deployment\compileAllDocumentation.bat ..\..\build\Debug\
