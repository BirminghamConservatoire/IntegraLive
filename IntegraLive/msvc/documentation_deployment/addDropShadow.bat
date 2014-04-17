set filepath=%1
set filename=%~nx1
set homedirectory=%2

echo adding shadow: %filename%

CALL %homedirectory%\documentation_deployment\ImageMagick\convert.exe %filepath% ( +clone -background black -shadow 80x3+3+3 ) +swap -background none -layers merge +repage shadow-%filename%