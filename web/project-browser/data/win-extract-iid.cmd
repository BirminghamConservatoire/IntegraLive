for /F "tokens=1-3 delims= " %%a in ('findstr "<InterfaceDeclaration" "%~2"') do (
	echo 		^<module name="%~1" %%b %%c/^>
)