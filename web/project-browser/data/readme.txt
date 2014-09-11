This folder contains data files used by the project browser, consisting of IXD/IID files for specific projects and associated modules.

In Windows, these can be generated dynamically by running the win-extract-ixd utility against any valid .integra file.

Sample files are included for reference:
 * ./SpectralDelay/ - containing the unzipped contents of /blocks/SpectralData.integra
 * ./SpectralDelay.modules.xml - a dynamically generated dependency index based on ./SpectralData/.integra
 * ./Integra Live/{module name}/ - each containing the unzipped contents of /modules/{module name}.module
