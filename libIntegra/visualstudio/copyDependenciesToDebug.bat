copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc.dll" "..\..\build\Debug\server\"
copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc_abyss.dll" "..\..\build\Debug\server\"
copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc_server.dll" "..\..\build\Debug\server\"
copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc_server_abyss.dll" "..\..\build\Debug\server\"
copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc_util.dll" "..\..\build\Debug\server\"
copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc_xmlparse.dll" "..\..\build\Debug\server\"
copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Debug-Win32\libxmlrpc_xmltok.dll" "..\..\build\Debug\server\"
copy "..\..\..\..\libIntegra_dependencies\libxml2-2.7.8.win32\bin\libxml2.dll" "..\..\build\Debug\server\"
copy "..\..\..\..\libIntegra_dependencies\pthreads-win32\lib\pthreadVC2.dll" "..\..\build\Debug\server\"
copy "..\..\..\..\libIntegra_dependencies\bin\iconv.dll" "..\..\build\Debug\server\"
copy "..\..\..\..\libIntegra_dependencies\zlib-1.2.5\bin\zlib1.dll" "..\..\build\Debug\server\"
copy "..\..\..\..\libIntegra_dependencies\lua-5.2.0\lua52.dll" "..\..\build\Debug\server\"

copy "..\data\CollectionSchema.xsd" "..\..\build\Debug\server\"
copy "..\data\id2guid.csv" "..\..\build\Debug\server"

rd /s /q ..\..\build\Debug\modules
mkdir ..\..\build\Debug\modules
xcopy "..\..\modules" "..\..\build\Debug\modules" /Y /Q

copy "..\..\host\Pd\Integra_Host.pd" "..\..\build\Debug\host\extra"

rd /s /q ..\..\build\Debug\gui\BlockLibrary
mkdir ..\..\build\Debug\gui\BlockLibrary
xcopy "..\..\modules\XML\collections\blocks" "..\..\build\Debug\gui\BlockLibrary" /E /Y /Q

rd /s /q ..\..\build\Debug\gui-debug\BlockLibrary
mkdir ..\..\build\Debug\gui-debug\BlockLibrary
xcopy "..\..\modules\XML\collections\blocks" "..\..\build\Debug\gui-debug\BlockLibrary" /E /Y /Q

CALL documentation_deployment\compileAllDocumentation.bat ..\..\build\Debug\
