copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc.dll" "..\..\..\build\Release\server\"
copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc_abyss.dll" "..\..\..\build\Release\server\"
copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc_server.dll" "..\..\..\build\Release\server\"
copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc_server_abyss.dll" "..\..\..\build\Release\server\"
copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc_util.dll" "..\..\..\build\Release\server\"
copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc_xmlparse.dll" "..\..\..\build\Release\server\"
copy "..\..\..\..\libIntegra_dependencies\xmlrpc-c\bin\Release-Win32\libxmlrpc_xmltok.dll" "..\..\..\build\Release\server\"
copy "..\..\..\..\libIntegra_dependencies\libxml2-2.7.8.win32\bin\libxml2.dll" "..\..\..\build\Release\server\"
copy "..\..\..\..\libIntegra_dependencies\pthreads-win32\lib\pthreadVC2.dll" "..\..\..\build\Release\server\"
copy "..\..\..\..\libIntegra_dependencies\bin\iconv.dll" "..\..\..\build\Release\server\"
copy "..\..\..\..\libIntegra_dependencies\zlib-1.2.5\bin\zlib1.dll" "..\..\..\build\Release\server\"
copy "..\..\..\..\libIntegra_dependencies\lua-5.2.0\lua52.dll" "..\..\..\build\Release\server\"

copy "..\..\..\modules\trunk\XML\schemas\CollectionSchema.xsd" "..\..\..\build\Release\server\"

rd /s /q ..\..\..\build\Release\modules
mkdir ..\..\..\build\Release\modules
xcopy "..\..\..\modules\trunk" "..\..\..\build\Release\modules" /Y /Q

copy "..\..\..\host\trunk\Pd\Integra_Host.pd" "..\..\..\build\Release\host\extra"

copy "..\..\..\library\trunk\data\id2guid.csv" "..\..\..\build\Release\server"

rd /s /q ..\..\..\build\Release\gui\BlockLibrary
mkdir ..\..\..\build\Release\gui\BlockLibrary
xcopy "..\..\..\modules\trunk\XML\collections\blocks" "..\..\..\build\Release\gui\BlockLibrary" /E /Y /Q

CALL documentation_deployment\compileAllDocumentation.bat ..\..\..\build\Release\