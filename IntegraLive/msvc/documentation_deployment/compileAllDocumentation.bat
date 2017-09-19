echo off

if exist %1\documentation goto SKIPDOCUMENTATION

mkdir %1\documentation
mkdir %1\documentation\html

set olddirectory=%CD%

cd ..\..\documentation\markdown

for /F "delims=" %%d in ('dir /ad /on /b /s') do (
	pushd %%d
	for %%f in (*.md) do (
		CALL "%olddirectory%\documentation_deployment\compileMarkdown.bat" %%f "%olddirectory%\%1\documentation\html\"
	)
	popd
)

REM cd ..\..\documentation\page-images

REM del shadow-*.png /q

REM for /f "delims=" %%f in ('dir /on /b /s *.png') do (
REM	CALL "%olddirectory%\documentation_deployment\addDropShadow.bat" "%%f" %olddirectory% 
REM )


cd %olddirectory%


xcopy "..\..\documentation\page-images" "%1\documentation\page-images\" /E /Y /Q


:SKIPDOCUMENTATION
