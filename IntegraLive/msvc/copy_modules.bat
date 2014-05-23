REM copies modules.  Expects parameter 1 to contain output directory

if exist %1\modules rd /s /q %1\modules
mkdir %1\modules

xcopy "..\..\modules" "%1\modules" /E /Y /Q


