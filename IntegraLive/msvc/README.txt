IntegraLive.sln is a container to build IntegraLive and all dependencies.

IntegraLive.vcxproj doesn't build anything itself, except for in its post-build step, 
which calls batch files to build the gui and module creator tool, compile the documentation, 
and copy all necessary files into the ../Debug and ../Release output directories.