REM copies block library to directory specified in parameter 1

if exist %1 rd /s /q %1
mkdir %1

xcopy "..\..\blocks" "%1" /E /Y /Q


