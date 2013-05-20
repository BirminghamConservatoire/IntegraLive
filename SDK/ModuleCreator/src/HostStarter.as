package
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.NativeProcessExitEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	
	import flashx.textLayout.tlf_internal;
	
	import flexunit.framework.Assert;
	
	import org.osmf.net.StreamType;

	public class HostStarter
	{
		public function HostStarter()
		{
		}
		
		
		public function startHost( modulePatch:File, endpoints:EndpointList ):void
		{
			Assert.assertTrue( NativeProcess.isSupported );

			if( _hostProcess )
			{
				AlertManager.show( "You are already editing the implementation in PD!\n\nForce close PD?", "Edit Patch", Alert.YES | Alert.NO, null, closeHostHandler );
				return;
			}
			
			var config:Config = Config.singleInstance;
			var hostPath:String = config.hostPath;
			
			Assert.assertNotNull( hostPath );
			
			var applicationDirectoryPath:String = File.applicationDirectory.nativePath;
			var applicationDirectory:File = new File( applicationDirectoryPath );
			
			var hostExecutable:File = applicationDirectory.resolvePath( hostPath );
			Assert.assertTrue( hostExecutable.exists && !hostExecutable.isDirectory );
			
			var hostStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			hostStartupInfo.executable = hostExecutable;

			if( !createHostPatch( modulePatch, endpoints ) )
			{
				trace( "error starting host" );
				removeHostPatch();
				return;
			}
			
			var hostArguments:Vector.<String> = config.hostArguments.concat();
			hostArguments.push( _hostPatch.nativePath ); 
			hostStartupInfo.arguments = hostArguments;
			hostStartupInfo.workingDirectory = hostExecutable.parent;
			
			_hostProcess = new NativeProcess;
			
			_hostProcess.addEventListener( NativeProcessExitEvent.EXIT, onHostExit );
			_hostProcess.addEventListener( Event.STANDARD_ERROR_CLOSE, onHostExit );
			_hostProcess.addEventListener( Event.STANDARD_OUTPUT_CLOSE, onHostExit );
			_hostProcess.start( hostStartupInfo );
		}
		
		
		public function killHost():void
		{
			if( _hostProcess )
			{
				_hostProcess.exit( true );
			}			
			
			removeHostPatch();
		}
		
		
		public function get isHostRunning():Boolean { return ( _hostProcess != null ); }
		
		
		private function onHostExit( event:Event ):void
		{
			_hostProcess = null;
			
			removeHostPatch();
		}		
		
		
		private function closeHostHandler( event:CloseEvent ):void
		{
			if( event.detail == Alert.YES )
			{
				if( _hostProcess )
				{
					_hostProcess.exit( true );
				}
			}
		}
		
		
		private function createHostPatch( modulePatch:File, endpoints:EndpointList ):Boolean
		{
			_hostPatchDirectory = File.createTempDirectory();
			deployHostDependencies();

			_hostPatch = _hostPatchDirectory.resolvePath( _hostPatchName );
			
			if( !modulePatch.exists || modulePatch.isDirectory ) 
			{
				trace( "Module patch doesn't exist " + modulePatch.nativePath );
				return false;
			}
			
			var _hostTemplate:File = File.applicationDirectory.resolvePath( _hostInputLocation + _hostTemplateName );
			if( !_hostTemplate.exists || _hostTemplate.isDirectory )
			{
				trace( "Can't open host template " + _hostTemplate.nativePath );
				return false;
			}
			
			var templateStream:FileStream = new FileStream();
			templateStream.open( _hostTemplate, FileMode.READ );
			var host:String = templateStream.readUTFBytes( _hostTemplate.size );
			templateStream.close();
			
			//replace module path
			var modulePath:String = modulePatch.parent.nativePath;
			modulePath = replaceAllInstances( modulePath, '\\', '/' );	//pd doesn't allow windows-style slashes
			modulePath = replaceAllInstances( modulePath, ' ', '\\ ' );	//slash-escape spaces
			host = replaceAllInstances( host, _templateHooks.modulePath , modulePath  );
			
			//replace module name
			var moduleName:String = modulePatch.name;
			if( modulePatch.extension )
			{
				moduleName = moduleName.substr( 0, moduleName.length - modulePatch.extension.length - 1 );
			}

			moduleName = replaceAllInstances( moduleName, ' ', '\\ ' );	//slash-escape spaces
			
			host = replaceAllInstances( host, _templateHooks.moduleName, moduleName );

			//module connections
			host = replaceAllInstances( host, _templateHooks.moduleConnections, generateModuleConnections( endpoints ) );

			//send values 
			host = replaceAllInstances( host, _templateHooks.endpointSendValues, generateSendValues( endpoints ) );
			
			var hostStream:FileStream = new FileStream();
			hostStream.open( _hostPatch, FileMode.WRITE );
			hostStream.writeUTFBytes( host );
			hostStream.close();

			return true;
		}
		
		
		private function deployHostDependencies():void
		{
			for each( var hostDependency:String in _hostDependencies )
			{
				var dependencyFile:File = File.applicationDirectory.resolvePath( _hostInputLocation + hostDependency );
				if( !dependencyFile.exists || dependencyFile.isDirectory )
				{
					trace( "Can't copy host dependency " + dependencyFile.nativePath );
					continue;
				}
				
				dependencyFile.copyTo( _hostPatchDirectory.resolvePath( hostDependency ) );
			}			
		}
		
		
		private function removeHostPatch():void
		{
			if( _hostPatchDirectory )
			{
				_hostPatchDirectory.deleteDirectory( true );
				_hostPatchDirectory = null;
				_hostPatch = null;
			}
		}
		
		
		private function replaceAllInstances( haystack:String, needle:String, replaceString:String ):String
		{
			var needleLength:int = needle.length;
			var replaceStringLength:int = replaceString.length;
			
			for( var index:int = haystack.indexOf( needle ); index >= 0; index = haystack.indexOf( needle, index ) )
			{
				var before:String = haystack.substr( 0, index );
				var after:String = haystack.substr( index + needleLength );
				
				haystack = before + replaceString + after;
				index += replaceStringLength;
			}
			
			return haystack;
		}
		
		
		private function generateModuleConnections( endpoints:EndpointList ):String
		{
			var numberOfInputs:int = 0;
			var numberOfOutputs:int = 0;
			
			for( var i:int = 0; i < endpoints.numberOfEndpoints; i++ )
			{
				var endpoint:Endpoint = endpoints.getEndpointAt( i );
				
				if( endpoint._endpointType.selectedItem != Endpoint.streamLabel )
				{
					continue;
				}

				var streamInfo:StreamInfo = endpoint._streamInfo;
				if( streamInfo._streamType.selectedItem != StreamInfo.audioLabel )
				{
					continue;
				}
				
				switch( streamInfo._streamDirection.selectedItem )
				{
					case StreamInfo.inputLabel:
						numberOfInputs++;
						break;
					
					case StreamInfo.outputLabel:
						numberOfOutputs++;
						break;
					
					default:
						trace( "unexpected stream direction: " + streamInfo._streamDirection.selectedItem );
						break;
				}
			}
			
			if( numberOfInputs > maxInputs )
			{
				trace( "Can't connect more than " + maxInputs + " inputs" );
				numberOfInputs = maxInputs;
			}

			if( numberOfOutputs > maxOutputs )
			{
				trace( "Can't connect more than " + maxOutputs + " outputs" );
				numberOfOutputs = maxOutputs;
			}
			
			var connections:String = "";
			
			for( i = 0; i < numberOfInputs; i++ )
			{
				connections += ( "#X connect 0 " + i + " 1 " + i + ";\n" ); 
			}

			for( i = 0; i < numberOfOutputs; i++ )
			{
				connections += ( "#X connect 1 " + i + " 2 " + i + ";\n" ); 
			}
			
			return connections;
		}

		
		private function generateSendValues( endpoints:EndpointList ):String
		{
			var sendValues:String = "";
			var controlY = controlYStart;
			
			for( var i:int = 0; i < endpoints.numberOfEndpoints; i++ )
			{
				var endpoint:Endpoint = endpoints.getEndpointAt( i );
				var endpointName:String = endpoint._endpointName.text;
				
				if( endpoint._endpointType.selectedItem != Endpoint.controlLabel )
				{
					continue;
				}
				
				var controlInfo:ControlInfo = endpoint._controlInfo;
				if( !controlInfo._isSentToHost.selected )
				{
					continue;
				}
				
				var controlType:String = null;
				var defaultValue:String = null;
				switch( controlInfo._controlType.selectedItem )
				{
					case ControlInfo._stateLabel:
						var stateInfo:StateInfo = controlInfo._stateInfo;
						switch( stateInfo._stateType.selectedItem )
						{
							case Globals.intType:
							case Globals.floatType:
								controlType = "float";
								break;
							
							case Globals.stringType:
								controlType = "symbol";
								break;
							
							default:
								trace( "Unexpected State Type: " + stateInfo._stateType.selectedItem );
								break;
						}
						
						defaultValue = stateInfo._default.text;
						break;
						
					case ControlInfo._bangLabel:
						controlType = "bang";
						defaultValue = "bang";
						break;
						
					default:
						trace( "Unexpected Control Type: " + controlInfo._controlType.selectedItem );
						break;
				}
				
				if( controlType == null || defaultValue == null )
				{
					trace( "Unable to generate send value for " + endpointName );
					continue;
				}
				
				var sendValue:String = "#X obj " + controlX + " " + controlY + " send-value " + controlType + " " + endpointName + " " + defaultValue + ";";
				sendValues += sendValue;
				sendValues += "\n";
				
				controlY += controlYSpacing;
			}
			
			return sendValues;
		}
		
		
		private var _hostPatchDirectory:File = null;
		private var _hostPatch:File = null;
		
		private var _hostProcess:NativeProcess = null;
		
		private static const _hostPatchName:String = "host.pd"
		
		private static const _hostInputLocation:String = "assets/host/";
			
		private static const _hostTemplateName:String = "host.pd_template";		
		
		private static const _hostDependencies:Array = [ "bang-box.pd", "float-box.pd", "send-value.pd", "symbol-box.pd" ];

		private static const _templateHooks:Object = 
			{
				modulePath: 		"/* MODULE PATH */",
				moduleName: 		"/* MODULE NAME */",
				moduleConnections: 	"/* MODULE CONNECTIONS */",
				endpointSendValues: "/* ENDPOINT SENDVALUE INSTANCES */"
			};
		
		private static const maxInputs:int = 8;
		private static const maxOutputs:int = 8;
		
		private static const controlX:int = 293;
		private static const controlYStart:int = 34;
		private static const controlYSpacing:int = 52;
		
	}
}