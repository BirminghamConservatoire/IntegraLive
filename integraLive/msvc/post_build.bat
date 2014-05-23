ECHO Copying server binaries
	copy_server.bat %1
ECHO DONE
ECHO

ECHO Copying SDK binaries
	copy_sdk.bat ..\%1\
ECHO DONE
ECHO.

ECHO Copying documentation
	documentation_deployment\compileAllDocumentation.bat ..\%1\
ECHO DONE
ECHO.

ECHO Building GUI
	gui_autobuild\buildgui.bat ..\%1\gui
ECHO DONE
ECHO.

ECHO Building module creator
	module_creator_autobuild\buildmodulecreator.bat ..\%1\sdk\ModuleCreator
ECHO DONE
ECHO.

ECHO Copying modules
	copy_modules.bat ..\%1\
ECHO DONE
ECHO.

ECHO Copying GUI block library
	copy_block_library.bat ..\%1\gui\BlockLibrary
ECHO DONE
ECHO.

if %1 eq Debug
(
ECHO Copying GUI debug block library
	copy_block_library.bat ..\%1\gui-debug\BlockLibrary
ECHO DONE
ECHO.
)