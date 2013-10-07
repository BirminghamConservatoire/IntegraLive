package components.views.ModuleManager
{
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import components.controller.serverCommands.UpgradeModules;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.ControlInfo;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;

	public class ModuleManagementInfoGenerator
	{
		public function ModuleManagementInfoGenerator()
		{
			_model = IntegraModel.singleInstance;
		}
		
		
		public function getInstanceNames( interfaceDefinition:InterfaceDefinition ):String
		{
			return getInstanceNamesRecursive( _model.project, interfaceDefinition );
		}

		
		public function getModuleSwitchReport( versionInUse:InterfaceDefinition, targetVersion:InterfaceDefinition ):String
		{
			var output:String = getModuleSwitchSummary( versionInUse, targetVersion );

			output += "##Summary of Changes:";

			output += getDifferences( versionInUse, targetVersion );
			
			return output;
		}
		
		
		public function getUpgradeReport( command:UpgradeModules ):String
		{
			if( command.upgradedObjectIDs.length == 0 )
			{
				return "Nothing needs to be upgraded."; 
			}
			
			var markdown:String = "The following modules have been upgraded\n\n";
			
			for each( var upgradedObjectID:int in command.upgradedObjectIDs )
			{
				markdown += "* "+ getEscapedObjectPath( upgradedObjectID ) + "\n"; 
			}

			markdown += "##Upgrade Details\n\n";
			
			for each( var upgradedModuleGuid:String in command.upgradedModuleGuids )
			{
				var previousVersion:InterfaceDefinition = _model.getInterfaceDefinitionByModuleGuid( upgradedModuleGuid );
				markdown += "##![](app:/icons/module_32x32x32.png) " + previousVersion.interfaceInfo.label + "\n\n";
				
				var upgradedVersion:InterfaceDefinition = _model.getInterfaceDefinitionsByOriginGuid( previousVersion.originGuid )[ 0 ];
				Assert.assertTrue( previousVersion != upgradedVersion );
				
				markdown += getModuleUpgradeSummary( previousVersion, upgradedVersion, command.searchObjectID );
				
				markdown += "###Summary of Changes:\n\n";
				markdown += getDifferences( previousVersion, upgradedVersion );
				markdown += "\n\n";
			}

			if( command.backupName )
			{
				markdown += "##Backup\n\n";
				markdown += "In case the upgrade has caused any problems, the pre-upgrade project was saved to __" + command.backupName + "__\n\n";
			}
			
			return markdown;
		}
		
		
		private function getModuleSwitchSummary( versionInUse:InterfaceDefinition, targetVersion:InterfaceDefinition ):String
		{
			return "The __" 
						+ versionInUse.moduleSourceLabel 
						+ "__ version of the __" 
						+ versionInUse.interfaceInfo.label 
						+ "__ module (updated " 
						+ versionInUse.interfaceInfo.modifiedDateLabel 
						+ ") in the project __"
						+ getEscapedObjectPath( IntegraModel.singleInstance.project.id )
						+ "__ will be swapped for the __"
						+ targetVersion.moduleSourceLabel 
						+ "__ version (updated "
						+ targetVersion.interfaceInfo.modifiedDateLabel
						+ ")\n\n";
		}
		
		
		private function getModuleUpgradeSummary( previousVersion:InterfaceDefinition, upgradedVersion:InterfaceDefinition, searchObjectID:int ):String
		{
			var locationDescription:String = "";

			var searchObject:IntegraDataObject = _model.getDataObjectByID( searchObjectID );
			if( searchObject is IntegraContainer )
			{
				locationDescription = "in the ";
				locationDescription += Utilities.getClassNameFromObject( searchObject ).toLowerCase();
				locationDescription += " __";
				locationDescription += getEscapedObjectPath( searchObjectID );
				locationDescription += "__ ";
			}
			
			var summary:String = "The __";
			summary += previousVersion.moduleSourceLabel;
			summary += "__ version of the __";
			summary += previousVersion.interfaceInfo.label; 
			summary += "__ module (updated ";
			summary += previousVersion.interfaceInfo.modifiedDateLabel;
			summary += ") "; 
			summary += locationDescription;
			summary += "has been upgraded to the __";
			summary += upgradedVersion.moduleSourceLabel;
			summary += "__ version (updated "
			summary += upgradedVersion.interfaceInfo.modifiedDateLabel
			summary += ")\n\n";	
			
			return summary;
		}		
		
		
		private function getDifferences( fromVersion:InterfaceDefinition, toVersion:InterfaceDefinition ):String
		{
			var output:String = "";
			
			if( fromVersion.interfaceInfo.label != toVersion.interfaceInfo.label ) 
			{
				output += "\n* Label changed";
			}

			if( fromVersion.interfaceInfo.description != toVersion.interfaceInfo.description ) 
			{
				output += "\n* Description changed";
			}

			if( fromVersion.interfaceInfo.author != toVersion.interfaceInfo.author ) 
			{
				output += "\n* Author changed";
			}
						
			if( !areArraysEqual( fromVersion.interfaceInfo.tags, toVersion.interfaceInfo.tags ) ) 
			{
				output += "\n* Tags changed";
			}
			
			output += getEndpointListDifferences( fromVersion.endpoints, toVersion.endpoints );
			
			if( !areArraysEqual( fromVersion.widgets, toVersion.widgets ) )
			{
				output += "\n* Widget layout changed";
			}
			
			if( fromVersion.implementationChecksum != toVersion.implementationChecksum )
			{
				output += "\n* Implementation changed";
			}
			
			return output;
			
		}
		
		
		private function getEndpointListDifferences( fromEndpoints:Vector.<EndpointDefinition>, endpointList2:Vector.<EndpointDefinition> ):String
		{
			var output:String = "";
			var fromEndpointSet:Object = new Object;
			var toEndpointSet:Object = new Object;
			var endpoint:EndpointDefinition;
			for each( endpoint in fromEndpoints ) fromEndpointSet[ endpoint.name ] = endpoint;
			for each( endpoint in endpointList2 ) toEndpointSet[ endpoint.name ] = endpoint;

			for each( endpoint in toEndpointSet )
			{
				if( !fromEndpointSet.hasOwnProperty( endpoint.name ) )
				{
					output += "\n* Added endpoint " + getBriefEndpointDescription( endpoint );
				}
			}
			
			for each( endpoint in fromEndpointSet )
			{
				if( !toEndpointSet.hasOwnProperty( endpoint.name ) )
				{
					output += "\n* Removed endpoint " + getBriefEndpointDescription( endpoint );
				}
			}

			for each( endpoint in toEndpointSet )
			{
				if( fromEndpointSet.hasOwnProperty( endpoint.name ) )
				{
					output += getEndpointDifferences( fromEndpointSet[ endpoint.name ], toEndpointSet[ endpoint.name ] );
				}
			}
			
			return output;
		}
		
		
		private function getEndpointDifferences( fromEndpoint:EndpointDefinition, toEndpoint:EndpointDefinition ):String
		{
			var differences:String = getDeepObjectDifferences( fromEndpoint, toEndpoint );
			if( differences.length == 0 )
			{
				return "";
			}
			
			return "\n* Endpoint '" + fromEndpoint.name + "' changed (" + differences + ")";
		}
		
		
		private function getBriefEndpointDescription( endpoint:EndpointDefinition ):String
		{
			var output:String = "'" + endpoint.name + "' (";
			
			switch( endpoint.type )
			{
				case EndpointDefinition.CONTROL:
					switch( endpoint.controlInfo.type )
					{
						case ControlInfo.BANG:
							output += ControlInfo.BANG;
							break;
						
						case ControlInfo.STATE:
							output += endpoint.controlInfo.stateInfo.type;
							break;
						
						default:
							Assert.assertTrue( false );
					}
					break;
					
				case EndpointDefinition.STREAM:
					output += endpoint.streamInfo.streamType + " " + endpoint.streamInfo.streamDirection;
					break;
				
				default:
					Assert.assertTrue( false );
					break;
					
			}
			
			output += ")";
			return output;
		}
		
		
		private function getDeepObjectDifferences( object1:Object, object2:Object, differencesAlreadyFound:Object = null ):String
		{
			var className:String = Utilities.getClassNameFromObject( object1 );
			Assert.assertTrue( className == Utilities.getClassNameFromObject( object2 ) );
			
			if( !differencesAlreadyFound ) 
			{
				differencesAlreadyFound = new Object;
			}
			
			var output:String = "";
			
			//just looks at getter methods for now			
			var commandAccessors:XMLList = describeType( object1 )..accessor;
			
			for each( var accessor:XML in commandAccessors )
			{
				if( accessor.@access == "writeonly" )
				{
					continue;	//skip if no getter is defined
				}
				
				var getterName:String = accessor.@name;
				
				var value1:Object = object1[ getterName ];
				var value2:Object = object2[ getterName ];
				
				var foundDifference:Boolean = false;
				
				if( !value1 || !value2 )
				{
					foundDifference = !( !value1 && !value2 );
				}					
				else
				{
					var className1:String = Utilities.getClassNameFromObject( value1 );
					var className2:String = Utilities.getClassNameFromObject( value2 );
					if( className1 != className2 )
					{
						foundDifference = true;
					}
					else
					{
						if( value1 is Number || value1 is String || value1 is Boolean )
						{
							foundDifference = ( value1 != value2 );
						}
						else
						{
							if( isArrayOrVector( value1 ) )
							{
								foundDifference = !areArraysEqual( value1, value2 );
							}
							else
							{
								if( className1 == Utilities.getClassNameFromClass( Object ) )
								{
									foundDifference = !areMapsEqual( value1, value2 );
								}
								else
								{
									var childDifferences:String = getDeepObjectDifferences( value1, value2, differencesAlreadyFound );
									if( childDifferences.length > 0 )
									{
										if( output.length > 0 ) output += ", ";
										output += childDifferences;
									}
								}
							}
						}
					}
				}

				
				if( foundDifference )
				{
					if( !differencesAlreadyFound.hasOwnProperty( getterName ) )
					{
						differencesAlreadyFound[ getterName ] = 1;
						if( output.length > 0 ) output += ", ";
						output += getterName;
					}
				}
			}
			
			return output;
		}
		
		
		private function getInstanceNamesRecursive( dataObject:IntegraDataObject, interfaceDefinition:InterfaceDefinition ):String
		{
			var output:String = "";
			
			if( dataObject.interfaceDefinition == interfaceDefinition )
			{
				output += "* " + getEscapedObjectPath( dataObject.id ) + "\n";
			}
			
			if( dataObject is IntegraContainer )
			{
				var container:IntegraContainer = dataObject as IntegraContainer;
				for each( var child:IntegraDataObject in container.children )
				{
					output += getInstanceNamesRecursive( child, interfaceDefinition );
				}
			}
			
			return output;
		}
		
		
		private function getVersionInUseLabel( version:InterfaceDefinition, versions:Vector.<InterfaceDefinition> ):String
		{
			if( versions.length == 1 ) 
			{
				Assert.assertTrue( version == versions[ 0 ] );
				return "Version in use"; 
			}
			else
			{
				var index:int = versions.indexOf( version );
				Assert.assertTrue( index >= 0 );
				return "Version in use " + String( index + 1 );
			}
		}
		
		
		private function anyDifferences( toCompare:Vector.<InterfaceDefinition>, compareProperty:String ):Boolean
		{
			Assert.assertTrue( toCompare.length >= 1 );
			
			var value:Object = getDeepProperty( toCompare[ 0 ], compareProperty ); 
			for( var i:int = 1; i < toCompare.length; i++ )
			{
				if( value != getDeepProperty( toCompare[ i ], compareProperty ) ) return true;
			}

			return false;			
		}
		
		
		private function getDeepProperty( object:Object, deepProperty:String ):Object
		{
			var indexOfFirstDot:int = deepProperty.indexOf( "." );
			if( indexOfFirstDot < 0 )
			{
				if( !object.hasOwnProperty( deepProperty ) ) 
				{
					return null;
				}

				return object[ deepProperty ];
			}

			var subObject:String = deepProperty.substring( 0, indexOfFirstDot );
			if( !object.hasOwnProperty( subObject ) )
			{
				return null;
			}

			var subProperty:String = deepProperty.substring( indexOfFirstDot + 1 );
			return getDeepProperty( object[ subObject ], subProperty );
		}
		
		
		private function areDeepObjectsEqual( object1:Object, object2:Object ):Boolean
		{
			if( !object1 || !object2 )
			{
				return ( !object1 && !object2 );
			}
			
			var className1:String = Utilities.getClassNameFromObject( object1 );
			var className2:String = Utilities.getClassNameFromObject( object2 );
			
			if( className1 != className2 ) return false;
			
			if( object1 is String || object1 is Number )
			{
				return ( object1 == object2 );
			}
			
			if( isArrayOrVector( object1 ) )
			{
				return areArraysEqual( object1, object2 );
			}
			
			if( className1 == Utilities.getClassNameFromClass( Object ) )
			{
				return areMapsEqual( object1, object2 );
			}

			return areGettersEqual( object1, object2 );
		}
		
		
		private function areMapsEqual( map1:Object, map2:Object ):Boolean
		{
			for( var key:String in map1 )
			{
				if( !map2.hasOwnProperty( key ) ) return false;
				if( !areDeepObjectsEqual( map1[ key ], map2[ key ] ) ) return false; 
			}
			
			for( key in map2 )
			{
				if( !map1.hasOwnProperty( key ) ) return false;
			}

			return true;
		}

		
		private function areGettersEqual( object1:Object, object2:Object ):Boolean
		{
			Assert.assertNotNull( object1 );
			Assert.assertNotNull( object2 );
			var className:String = Utilities.getClassNameFromObject( object1 );
			Assert.assertTrue( className == Utilities.getClassNameFromObject( object2 ) );
			
			var commandAccessors:XMLList = describeType( object1 )..accessor;
			
			for each( var accessor:XML in commandAccessors )
			{
				if( accessor.@access == "writeonly" )
				{
					continue;	//skip if no getter is defined
				}
				
				var getterName:String = accessor.@name;

				if( !areDeepObjectsEqual( object1[ getterName ], object2[ getterName ] ) ) 
				{
					return false;
				}
			}
			
			return true;
		}
		
		
		//declared as objects so that we can use typed vectors
		private function areArraysEqual( array1:Object, array2:Object ):Boolean
		{
			if( array1.length != array2.length ) return false;
			
			for( var i:int = 0; i < array1.length; i++ )
			{
				if( !areDeepObjectsEqual( array1[ i ], array2[ i ] ) )  return false;
			}
			
			return true;
		}
		
		
		private function isArrayOrVector( object:Object ):Boolean
		{
			if( object is Array ) return true;
			
			const vectorFinder:String = "__AS3__.vec::Vector.<";
			var qualifiedClassName:String = getQualifiedClassName( object );
			
			return( qualifiedClassName.substr( 0, vectorFinder.length ) == vectorFinder );			
		}
		
		
		private function getEscapedObjectPath( objectID:int ):String
		{
			const source:String = "_";
			const target:String = "&#95;";
			
			var name:String = _model.getPathStringFromID( objectID );
			
			var underscoreIndex:int = 0;
			
			while( true )
			{
				underscoreIndex = name.indexOf( source, underscoreIndex );
				if( underscoreIndex < 0 ) break;
				
				name = name.substr( 0, underscoreIndex ) + target + name.substr( underscoreIndex + 1 );
				underscoreIndex += target.length;
			}
			
			return name;
		}

		
		private var _model:IntegraModel;
	}
}