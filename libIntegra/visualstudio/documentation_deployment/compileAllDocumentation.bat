echo off

rd /s /q %1\documentation
mkdir %1\documentation
mkdir %1\documentation\html

xcopy "..\..\..\documentation\trunk\page-images" "%1\documentation\page-images\" /E /Y /Q

set olddirectory=%CD%

cd ..\..\..\documentation\trunk\markdown

for /r %%f in (*.md) do (
	CALL %olddirectory%\documentation_deployment\compileMarkdown.bat %%f %1\documentation\html\
)

cd %olddirectory%