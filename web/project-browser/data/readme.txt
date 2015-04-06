This folder contains data files used by the project browser web application. These consist of IXD/IID files taken from built-in modules (in the /modules folder of the local codebase) and specific projects (or blocks) from an optionally specified .integra file.

In Windows¹, these data files can be generated dynamically by running the win-extract-ixd utility.
 * Invoked without arguments, it will parse the contents of relative path '../../../modules', extracting each module's IID data into the local 'Integra Live' folder (assuming that module isn't already represented there).
 * Invoked with a single argument in the form '{name}.integra' (representing the name of a superficially valid² .integra block/project file) it will perform the default action (as above) before extracting the specified file's contents into a local folder '{name}', and generating an index file '{name}.modules.xml' that enumerates the file's potential module dependencies (both built-in and embedded).
 * This can be achieved via the Windows Explorer by dragging and dropping a .integra file onto the 'win-extract-ixd.cmd' icon.

Sample files are included for reference:
 * ./Integra Live/{module name}/ - each containing the unzipped contents of /modules/{module name}.module
 * ./SpectralDelay/ - containing the unzipped contents of /blocks/SpectralDelay.integra
 * ./SpectralDelay.modules.xml - the dynamically generated index of this block's potential module dependencies 
 
 ¹ No *nix-specific version of this utility has been implemented to date. However, equivalent logic can be found embedded within the PHP script '../validate.php'.
 ² In this context, the only explicit validation requirement is that the file is a zip-container with a specific internal file structure. This extraction is specifically designed as a precursor to the second-order validation process through which we confirm it actually contains IXD/IID files representing well-formed, valid and self-consistent XML data.
 