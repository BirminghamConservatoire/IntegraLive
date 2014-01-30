/* libIntegra modular audio framework
 *
 * Copyright (C) 2007 Birmingham City University
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, 
 * USA.
 */


namespace integra_api
{
/**
\mainpage libIntegra Documentation

Welcome to libIntegra.

libIntegra is a modular framework for realtime processing of audio and midi.  

libIntegra is written in c++.  

libIntegra is cross-platform and open-source.

# What libIntegra does:

+ Manages a 'module graph' - a hierarchy of module instances.  

+ Provides an api for creating, controlling, querying, and receiving feedback from the module graph

+ Handles audio and midi I/O, via the open source libraries <a href="http://portaudio.com">PortAudio</a> and 
<a href="http://portmedia.sourceforge.net/portmidi">PortMidi</a>

+ Processes audio in realtime using <a href="http://libpd.cc">LibPD</a>

+ Loading and saving of '.integra' files.  The .integra file format stores module graphs, and also includes the 
following features:
  + Allows module instances to embed persistant external data files (for example, audio files used by a sampler).  
    This means that unlike typical DAW project files, a .integra file needs no external file dependencies, for  
    ease of transference/sharing.
  + Embeds the definition and implementation of modules themselves.  This means that if a .integra file 
    is transferred to another user who has a different set of modules (or different versions of the same 
    modules), libIntegra will load the embedded modules from the .integra file, and offer the exact original 
    functionality.  This is intended to solve the sustainability problems associated with maintaining 
    availability of 3rd party modules/plugins.

# What exactly is a module?

Integra modules consist of an interface and an implementation.  Module interfaces are defined using the 
<a href="http://www.integralive.org/tutorials/module-development-quick-start">Integra Module Creator</a> tool,
and module implementations are written in <a href="http://puredata.info">Pure Data</a>.  Integra Modules are stored 
in '.module' files, which contain both the module's interface and pd implementation.  For more information about modules, 
see the <a href="http://www.integralive.org/tutorials/module-development-guide/#what-is-a-module">module development guide</a>.
\note There are a few core control/logic modules which are implemented directly in libIntegra, not pd.  However, 
users of libIntegra can use any modules without needing to know whether they are implemented in pd or libIntegra.

# Anatomy of libIntegra

libIntegra resides in two namespaces: integra_api and integra_internal.  Users of the api should only ever need to 
use the classes in integra_api.  This is the only part of libIntegra which is covered by this documentation, and it 
is envisaged that binary distributions of the library would only include the integra_api headers.

The classes in integra_api can be split into the following categories:

## High level / entry-point to the system

CIntegraSession, CServerStartupInfo, CServerLock, IServer

## Interfaces for querying modules and the module graph

These are all pure virtual interface classes, they are never directly instantiated, they are used to retrieve information.

Querying the module graph:

+ INode, INodeEndpoint

Querying module interfaces:

+ IInterfaceDefinition, IInterfaceInfo, IEndpointDefinition, IControlInfo, IStateInfo, IConstraint, IValueScale,
IStreamInfo, IWidgetDefinition, IWidgetPosition, IImplementationInfo

## Classes to represent atomic units of information

These classes can be instantiated by users of the api, and are frequently passed around as arguments:

+ CPath
+ CValue, CIntegerValue, CFloatValue, CStringValue

## Interfaces to represent commands

These classes represent input from users of the api:

+ ICommand, INewCommand, IDeleteCommand, ISetCommand, IRenameCommand, IMoveCommand, ILoadCommand, ISaveCommand

And the outputs from these commands:

+ CCommandResult, CNewCommandResult, CLoadCommandResult

## Module Management

+ IModuleManager

And its outputs:

+ CModuleInstallResult, CModuleUninstallResult, CLoadModuleInDevelopmentResult

## Providing feedback to users of the api

+ INotificationSink
+ CPollingNotificationSink

## Enumerations

+ CCommandSource
+ CError

## Static Helper Classes

+ CGuidHelper
+ CStringHelper
+ CTrace


# Typical Workflow

Let's imagine a realtime audio processing application with an event-driven gui which uses 
libIntegra as its audio engine.  The following table indicates how different parts of the 
application might interact with libIntegra:

| Application                  | libIntegra    
| ---------------------------- | ------------- --------------------------------------------------------------------------------------------------------
| Startup		               | Populate a CServerStartupInfo, Create a CIntegraSession, call CIntegraSession::start_session.
| Updating views               | Call CIntegraSession::get_server, use the methods on IServer to query libIntegra and update views.
| Responding to user input     | Call CIntegraSession::get_server, use IServer::process_command to update libIntegra as required.
| Idle pump or continual timer | Use CPollingNotificationSink to poll for changes to libIntegra's internal state, update views accordingly. 
| Shutdown                     | call CIntegraSession::end_session.


# Threading

Please see CServerLock for a discussion of threading in libIntegra

# Special Modules

Because of libIntegra's modular architecture, much of the core libIntegra functionality involves dealing with modules
in a generic way.  Modules themselves have the facility to contain inbuilt documentation in markdown format, so it would
be redundant to exhaustively document all the 'shipped with libIntegra' modules here.

However, there are a handful of special control/logic modules whose behaviour is hardcoded into libIntegra, and without 
which it would be impossible to use libIntegra in a meaningful way.  So it is worth summarizing the functionality of
these modules here:

## Container

Allows other modules to be placed inside, so that hierarchies of modules can be constructed.  Contains logic to only 
activate descendant non-container modules when every container in a descendant's ancestor chain is active.  In other words, 
the 'active' flags of a chain of containers are akin to switches wired in series.

## Connection

Allows module endpoints to be connected.  Connections between audio I/O endpoints allow the audio signal to flow between 
modules.  Connections between control endpoints allow modules to interact with each other.  Connection 'source' and 'target' 
properties use relative paths, so that the modules within any Container can only refer to their siblings and descendants.  
This means that the behaviour within each Container is self-contained, allowing for saving/loading/transferring of sub-branches 
within a module tree.

## Scaler

Performs interpolation from an input range to an output range.  This allows controls with diverse ranges to be mapped to each 
other, typically with a configuration such as [source endpoint] -> Connection -> Scaler -> Connection [target endpoint]

## Player

Provides a tick counter (playhead) with ability to start, stop, loop.

## Scene

Defines a segment of time which Player instances can refer to in order to jump to pre-planned time positions and play/loop settings

## Envelope, ControlPoint

These provide interpolation over time series.  ControlPoints located within an Envelope define a function in terms of time.
Envelope provides an ability to set a tick value and obtain an output value.

## Script 

Allows module endpoints to be controlled programmatically by lua code.  Integra lua scripts can interact with libIntegra by 
getting and setting the value of module endpoints, to perform arbitrarily complex interactions.

## AudioSettings, MidiSettings

These modules allow selection of devices, device settings etc.  Note that they employ a 'shared instance' pattern.  However many 
instances of each settings module is created, all instances will share the same endpoint values, and setting any endpoint 
value on any instance will have the same effect as setting it on any other.


*/
}
