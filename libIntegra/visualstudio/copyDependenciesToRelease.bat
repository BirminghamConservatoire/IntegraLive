copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc_abyss.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc_server.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc_server_abyss.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc_util.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc_xmlparse.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc_xmltok.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\libxml2-2.7.8.win32\bin\libxml2.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\pthreads-win32\lib\pthreadVC2.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\bin\iconv.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\zlib-1.2.5\bin\zlib1.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\lua-5.2.0\lua52.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\fftw-3.3.3\libfftw3f-3.dll" "..\..\build\Debug\server\"
copy "..\..\libIntegra_dependencies\\portaudio\build\msvc\Win32\Release\portaudio_x86.dll" "..\..\build\Release\server\"
copy "..\..\libIntegra_dependencies\libsndfile\bin\libsndfile-1.dll" "..\..\build\Debug\server\"
copy "..\externals\libpd\libs\libpd.dll" "..\..\build\Release\server\"

copy "..\data\CollectionSchema.xsd" "..\..\build\Release\server\"
copy "..\data\id2guid.csv" "..\..\build\Release\server"

if exist ..\..\build\Release\modules rd /s /q ..\..\build\Release\modules
mkdir ..\..\build\Release\modules
xcopy "..\..\modules" "..\..\build\Release\modules" /Y /Q

if exist ..\..\build\Release\SDK\templates rd /s /q ..\..\build\Release\SDK\templates
mkdir ..\..\build\Release\SDK\templates
xcopy "..\..\SDK\templates" "..\..\build\Release\SDK\templates" /Y /Q /S
copy "..\..\SDK\license.txt" "..\..\build\Release\SDK\"

CALL documentation_deployment\compileAllDocumentation.bat ..\..\build\Release\