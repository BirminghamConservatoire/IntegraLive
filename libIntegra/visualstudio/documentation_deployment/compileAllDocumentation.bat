echo off

rd /s /q %1\documentation
mkdir %1\documentation
mkdir %1\documentation\html

set olddirectory=%CD%

cd ..\..\documentation\markdown

for /r %%f in (*.md) do (
	CALL %olddirectory%\documentation_deployment\compileMarkdown.bat %%f %1\documentation\html\
)

cd ..\..\documentation\page-images

del shadow-*.png /q

for /r %%f in (*.png) do (
	CALL %olddirectory%\documentation_deployment\addDropShadow.bat %%f %olddirectory% 
)

xcopy "..\..\documentation\page-images" "%1\documentation\page-images\" /E /Y /Q


cd %olddirectory%