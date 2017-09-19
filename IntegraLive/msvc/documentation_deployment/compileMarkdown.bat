echo off

setlocal EnableDelayedExpansion

set filename=%~nx1
set filetitle=%~n1

set absolute_path=%1
set relative_to_path=%CD%
REM set local_path=!absolute_path:*%relative_to_path%\=!
REM set directory_name=!local_path:\%filename%=!
for %%a in (.) do set directory_name=%%~na

set target_dir=%2
set target_dir=%target_dir:"=%

mkdir "%target_dir%\%directory_name%"

set targetfile=%target_dir%\%directory_name%\%filetitle%.htm


set headerfile=%CD%\%filetitle%\header.html

if exist "%headerfile%" (
	pandoc --include-in-header="%headerfile%" --template=template.pandoc --toc --standalone --ascii -f markdown -t html -o "%targetfile%" %1
) else (
	pandoc --standalone --ascii -f markdown -t html -o "%targetfile%" %1
)

echo compiled documentation page: %targetfile%
