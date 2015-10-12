REM copies Pd host to directory specified in parameter 1

if exist %1\host rd /s /q %1\host
mkdir %1\host

xcopy "..\..\host" "%1\host" /E /Y /Q
