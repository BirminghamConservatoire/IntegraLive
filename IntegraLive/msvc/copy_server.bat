REM copy libIntegra and IntegraServer exe and dlls to output folder.  This batch file expects parameter 1 to be the configuration type (Debug|Release)

if exist ..\%1\server rd /s /q ..\%1\server
mkdir ..\%1\server
xcopy "..\..\server\bin\%1" "..\%1\server" /Y /Q
