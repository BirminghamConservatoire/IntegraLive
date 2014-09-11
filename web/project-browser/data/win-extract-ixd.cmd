@echo off
cls
title Integra Project Extractor

echo ======================================================
echo  Integra Project Extractor
echo   * running in cwd  : %~dp0
echo   * running against : %*
echo ======================================================

if "%~1" == "" (
	echo  No projects were specified for extraction
	echo   - try running win-extract-ixd from the command line, specifying your project file as the first argument
	echo   - alternatively, you can drag your project file onto win-extract.cmd in Windows Explorer
	goto end
)

set skipped=0
set extracted=0
set indexed=0

echo Processing built-in modules:

REM BUILT-IN MODULE EXTRACTION
echo|set /p="* extracting "
for %%f in (..\..\..\modules\*.module) do (
	IF EXIST "Integra Live\%%~nf" (
		echo|set /p=.
		set /a skipped+=1
	) ELSE (
		7z x -r -o"Integra Live\%%~nf" %%f "*.iid" > nul
		echo|set /p=+
		set /a extracted+=1
	)
)
echo.
echo   DONE (%extracted% modules extracted, %skipped% skipped)

REM INITIALIZE MODULE INDEX
copy NUL modules.xml > nul
echo.
echo Initialising module index
echo ^<?xml version="1.0" encoding="UTF-8"?^> >> modules.xml
echo ^<?xml-stylesheet type="text/xsl" href="../xsl/module-list.xsl"?^> >> modules.xml
echo ^<IntegraModules^> >> modules.xml

REM INDEX BUILT-IN MODULES
echo|set /p="* indexing   "
echo 	^<!-- default modules included with Integra Live --^> >> modules.xml
echo 	^<collection src="Integra Live"^> >> modules.xml
for /d %%f in ("Integra Live\*") do (
	call win-extract-iid.cmd "%%~nf" "%%~f\integra_module_data\interface_definition.iid" >> modules.xml
	echo|set /p=+
	set /a indexed+=1
)
echo 	^</collection^> >> modules.xml
echo.
echo   DONE (%indexed% modules indexed)

echo.
echo ------------------------------------------------------
echo Processing file "%~1":

set project=%~n1
set src=%project: =+%

if "%~x1" neq ".integra" (
	echo * skipping non-.integra project
) else (
	REM EXTRACT PROJECT IXD
	echo * extracting IXD
	7z x -y -r -o"%project%" %1 "*.ixd" > nul
	echo   DONE
	
	REM EXTRACT PROJECT MODULE
	echo * extracting modules
	7z x -y -r -o"%project%" %1 "*.module" > nul
	echo   DONE
	
	set skipped=0
	set extracted=0
	
	for %%f in ("%project%\integra_data\implementation\*.module") do (
		IF EXIST "%project%\integra_data\implementation\%%~nf" (
			echo|set /p=.
			set /a skipped+=1
		) ELSE (
			echo|set /p=+
			7z x -r -o"%project%/integra_data/implementation/%%~nf" "%%f" "*.iid" > nul
			IF EXIST "%project%\integra_data\implementation\%%~nf" del "%%f"
			set /a extracted+=1
		)
	)
	echo.
	echo   DONE (%extracted% modules extracted, %skipped% skipped^)
	
	echo|set /p="* indexing   "
	echo 	^<!-- modules included with project "%project%" --^> >> modules.xml
	echo 	^<collection src="%src%"^> >> modules.xml
	for %%f in ("%project%\integra_data\implementation\*.module") do (
		call win-extract-iid.cmd "%%~nf" "%project%\integra_data\implementation\%%~nf\integra_module_data\interface_definition.iid" >> modules.xml
	)
	echo 	^</collection^> >> modules.xml
	echo.
	echo   DONE
	REM ARG-SPECIFIED MODULE EXTRACTION/INDEXING - END
)

echo.
echo Finalising module index
echo ^</IntegraModules^> >> modules.xml

IF EXIST "%~n1.modules.xml" del "%~n1.modules.xml"
ren modules.xml "%~n1.modules.xml"

:end
echo ======================================================
pause