echo off

setlocal EnableDelayedExpansion

set filename=%~nx1
set filetitle=%~n1

set absolute_path=%1
set relative_to_path=%CD%
set local_path=!absolute_path:*%relative_to_path%\=!
set directory_name=!local_path:\%filename%=!

mkdir %2\%directory_name%

set targetfile=%2\%directory_name%\%filetitle%.htm

set headerfile=%CD%\%filetitle%\header.html

if exist %headerfile% (
	pandoc --include-in-header=%headerfile% --template=template.pandoc --toc --standalone --ascii -f markdown -t html -o %targetfile% %1
) else (
	pandoc --standalone --ascii -f markdown -t html -o %targetfile% %1
)

echo compiled documentation page: %targetfile%