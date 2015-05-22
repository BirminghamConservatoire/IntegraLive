REM copy dependencies to IntegraServer output folder.  This batch file expects parameter 1 to be the output folder, and paramter 2 to be the configuration type (Debug|Release)

xcopy "..\..\libIntegra\bin\%2" "%1" /Y /Q

copy "..\externals\xmlrpc-c\bin\%2-Win32\libxmlrpc.dll" "%1"
copy "..\externals\xmlrpc-c\bin\%2-Win32\libxmlrpc_abyss.dll" "%1"
copy "..\externals\xmlrpc-c\bin\%2-Win32\libxmlrpc_server.dll" "%1"
copy "..\externals\xmlrpc-c\bin\%2-Win32\libxmlrpc_server_abyss.dll" "%1"
copy "..\externals\xmlrpc-c\bin\%2-Win32\libxmlrpc_util.dll" "%1"
copy "..\externals\xmlrpc-c\bin\%2-Win32\libxmlrpc_xmlparse.dll" "%1"
copy "..\externals\xmlrpc-c\bin\%2-Win32\libxmlrpc_xmltok.dll" "%1"

