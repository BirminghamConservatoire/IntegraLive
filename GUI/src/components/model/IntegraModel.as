/* Integra Live graphical user interface
 *
 * Copyright (C) 2009 Birmingham City University
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA   02110-1301,
 * USA.
 */


package components.model
{
	import flash.geom.Rectangle;
	
	import __AS3__.vec.Vector;
	
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.StreamInfo;
	import components.model.interfaceDefinitions.WidgetDefinition;
	import components.model.preferences.AudioSettings;
	import components.model.preferences.MidiSettings;
	import components.model.userData.ColorScheme;
	import components.model.userData.LiveViewControl;
	import components.utils.Trace;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;

	
	public class IntegraModel
	{
		public function IntegraModel()
		{
			Assert.assertNull( _singleInstance );	//shouldn't create more than one model

			clearAll();
		}
		
		
		public static function get singleInstance():IntegraModel
		{
			if( !_singleInstance ) _singleInstance = new IntegraModel;
			return _singleInstance;
		} 

		//query methods

		public function get interfaceList():Vector.<String>		{ return _interfaceList; }

		public function get project():Project					{ return _project; }
		public function get isProjectModified():Boolean 		{ return _isProjectModified; }

		public function get audioSettings():AudioSettings 		{ return _audioSettings; }
		public function get midiSettings():MidiSettings 		{ return _midiSettings; }

		
		public function get filename():String { return _filename; }
		public function get currentInfo():Info { return _currentInfo; }
		public function get showInfoView():Boolean { return _showInfoView; }
		public function get projectLength():int { return _projectLength; }
		
		public function get alwaysUpgrade():Boolean { return _alwaysUpgrade; }
		
		public function getPathStringFromID( id:int ):String
		{
			var object:IntegraDataObject = getDataObjectByID( id );
			if( !object )
			{
				Assert.assertTrue( false );	//can't find object
				return null;	
			}
			
			if( object.parentID >= 0 )
			{
				return getPathStringFromID( object.parentID ) + "." + object.name;	
			}
			else
			{
				return object.name;
			}
		}


		public function getPathArrayFromID( id:int ):Array
		{
			var path:String = getPathStringFromID( id );
			if( !path )
			{
				Assert.assertTrue( false );
				return null;
			}
			
			return path.split( "." );
		}


		public function getIDFromPathArray( path:Array ):int
		{
			if( path.length == 0 )
			{
				Trace.error( "No path provided" );
				return -1;
			}
			
			var searchObject:IntegraDataObject = null;
			for each( var topLevelObject:IntegraDataObject in _topLevelObjects )
			{
				if( topLevelObject.name == path[ 0 ] )
				{
					searchObject = topLevelObject;
					break;
				}
			}
			
			if( !searchObject )
			{
				Trace.error( "top-level object " + path[ 0 ] + " not found" );
				return -1;
			}
			
			for( var level:int = 1; level < path.length; level++ )
			{
				if( !( searchObject is IntegraContainer || searchObject is Envelope || searchObject is Player ) )
				{
					Trace.error( "path not resolved" );
					return -1;	//path not resolved
				}
				
				var children:Object = null;
				if( searchObject is IntegraContainer ) children = ( searchObject as IntegraContainer ).children;
				if( searchObject is Envelope ) children = ( searchObject as Envelope ).controlPoints;
				if( searchObject is Player ) children = ( searchObject as Player ).scenes;
				
				Assert.assertNotNull( children );
				var found:Boolean = false;
				
				for each( var child:IntegraDataObject in children )
				{
					if( child.name == path[ level ] )
					{
						searchObject = child; 
						found = true;
						break;
					}
				}
				
				if( !found ) 
				{
					return -1;	//path not resolved
				}
			}

			return searchObject.id; 
		}
		

		public function getIDFromPathString( path:String ):int
		{
			return getIDFromPathArray( path.split( "." ) );
		}


		public function getDataObjectByID( id:int ):IntegraDataObject
		{
			Assert.assertTrue( _objectMap.hasOwnProperty( id ) );
			Assert.assertTrue( _objectMap[ id ] is IntegraDataObject );
			
			return _objectMap[ id ] as IntegraDataObject;
		}
		
		
		public function doesObjectExist( id:int ):Boolean
		{
			return _objectMap.hasOwnProperty( id );
		}
		
		
		public function getEndpointDefinition( objectID:int, endpointName:String ):EndpointDefinition
		{
			if( objectID < 0 ) 
			{
				return null;
			}
			
			var dataObject:IntegraDataObject = getDataObjectByID( objectID );
			Assert.assertNotNull( dataObject );
			
			return dataObject.interfaceDefinition.getEndpointDefinition( endpointName );
		}		
		
		
		public function isObjectSelected( objectID:int ):Boolean 
		{ 
			var parent:IntegraContainer = getParent( objectID ) as IntegraContainer;
			if( parent )
			{
				return parent.userData.isChildSelected( objectID );
			}
			
			return false;
		}

		
		public function getPrimarySelectedChildID( containerID:int ):int 
		{ 
			var container:IntegraContainer = getContainer( containerID ) as IntegraContainer;
			if( !container ) return -1;

			return container.userData.primarySelectedChildID;
		}
		
		
		public function get primarySelectedModule():ModuleInstance
		{
			var block:Block = primarySelectedBlock;
			if( !block )
			{
				return null;
			} 

			var primarySelectedChildID:int = block.userData.primarySelectedChildID;
			if( primarySelectedChildID < 0 )
			{
				return null;
			}
			
			var primarySelectedChild:IntegraDataObject = getDataObjectByID( primarySelectedChildID );
			if( primarySelectedChild is ModuleInstance )
			{
				return primarySelectedChild as ModuleInstance;
			}
			
			return null;	
		}


		public function get primarySelectedBlock():Block
		{
			var track:Track = selectedTrack;
			if( !track ) 
			{
				return null;
			}

			var primarySelectedChildID:int = track.userData.primarySelectedChildID;
			if( primarySelectedChildID < 0 )
			{
				return null;
			}
			
			if( !doesObjectExist( primarySelectedChildID ) )
			{
				return null;
			}

			var primarySelectedChild:IntegraDataObject = getDataObjectByID( primarySelectedChildID );
			if( primarySelectedChild is Block )
			{
				return primarySelectedChild as Block;
			}

			return null;	
		}


		public function get selectedEnvelope():Envelope
		{
			var block:Block = primarySelectedBlock;
			if( !block )
			{
				return null;
			} 

			var primarySelectedChildID:int = block.userData.primarySelectedChildID;
			if( primarySelectedChildID < 0 )
			{
				return null;
			}
			
			var primarySelectedChild:IntegraDataObject = getDataObjectByID( primarySelectedChildID );
			if( primarySelectedChild is Envelope )
			{
				return primarySelectedChild as Envelope;
			}
			
			return null;	
		}


		public function get selectedTrack():Track
		{
			var trackID:int = project.userData.primarySelectedChildID;
			if( trackID < 0 ) 
			{
				return null;
			}
			
			var dataObject:IntegraDataObject = getDataObjectByID( trackID );
			if( dataObject && dataObject is Track )
			{
				return dataObject as Track;
			}
			
			return null;	
		}


		public function get selectedScene():Scene
		{
			var sceneID:int = project.player.selectedSceneID;
			if( sceneID < 0 ) 
			{
				return null;
			}
			
			if( project.player.scenes.hasOwnProperty( sceneID ) )
			{
				return project.player.scenes[ sceneID ];
			}
			
			return null;	
		}
		
		
		public function get selectedContainer():IntegraContainer
		{
			var selectedBlock:Block = primarySelectedBlock;
			if( selectedBlock )
			{
				return selectedBlock;
			}
			else
			{
				var selectedTrack:Track = selectedTrack;
				if( selectedTrack )
				{
					return selectedTrack;
				}
				else
				{
					return project;
				}
			}
		}
		
		
		public function get selectedScript():Script
		{
			var id:int = getPrimarySelectedChildID( selectedContainer.id );

			if( id < 0 ) return null;
			
			if( !doesObjectExist( id ) ) return null;
			
			var dataObject:IntegraDataObject = getDataObjectByID( id );
			if( !dataObject || !( dataObject is Script ) ) return null;
			
			return dataObject as Script;
		}
		
		
		public function isModuleInstancePrimarySelected( instanceID:int ):Boolean
		{
			return( instanceID == getPrimarySelectedChildID( getBlockFromModuleInstance( instanceID ).id ) );	
		}


		public function isBlockPrimarySelected( blockID:int ):Boolean
		{
			var primarySelectedBlock:Block = primarySelectedBlock;
			if( !primarySelectedBlock ) 
			{
				return false;	
			}
			
			return( blockID == primarySelectedBlock.id );	
		}


		public function isTrackSelected( trackID:int ):Boolean
		{
			return ( trackID == getPrimarySelectedChildID( project.id ) );
		}


		public function getCoreInterfaceDefinitionByName( name:String ):InterfaceDefinition
		{
			if( _coreInterfaceDefinitionsByName.hasOwnProperty( name ) )
			{
				return _coreInterfaceDefinitionsByName[ name ] as InterfaceDefinition;
			}
			
			//not found
			return null;
		}

		
		public function getInterfaceDefinitionByModuleGuid( moduleGuid:String ):InterfaceDefinition
		{
			if( _interfaceDefinitionsByModuleGuid.hasOwnProperty( moduleGuid ) )
			{
				return _interfaceDefinitionsByModuleGuid[ moduleGuid ] as InterfaceDefinition;
			}

			//not found
			return null;
		}
		
		
		public function getInterfaceDefinitionsByOriginGuid( originGuid:String ):Vector.<InterfaceDefinition>
		{
			if( _interfaceDefinitionsByOriginGuid.hasOwnProperty( originGuid ) )
			{
				return _interfaceDefinitionsByOriginGuid[ originGuid ] as Vector.<InterfaceDefinition>;
			}
			
			//not found
			return null;			
		}

		
		public function getCoreInterfaceGuid( name:String ):String
		{
			if( _coreInterfaceDefinitionsByName.hasOwnProperty( name ) )
			{
				return _coreInterfaceDefinitionsByName[ name ].moduleGuid;
			}
			
			//not found
			Assert.assertTrue( false );
			return null;
		}
		

		public function getTrack( trackID:int ):Track
		{
			var object:IntegraDataObject = getDataObjectByID( trackID );
			if( object && object is Track )
			{
				return object as Track;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}


		public function getBlock( blockID:int ):Block 
		{
			var object:IntegraDataObject = getDataObjectByID( blockID );
			if( object && object is Block )
			{
				return object as Block;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}
		
		
		public function getContainer( containerID:int ):IntegraContainer
		{
			var object:IntegraDataObject = getDataObjectByID( containerID );
			if( object && object is IntegraContainer )
			{
				return object as IntegraContainer;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}


		public function getModuleInstance( instanceID:int ):ModuleInstance
		{
			var object:IntegraDataObject = getDataObjectByID( instanceID );
			if( object && object is ModuleInstance )
			{
				return object as ModuleInstance;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}


		public function getConnection( connectionID:int ):Connection
		{
			var object:IntegraDataObject = getDataObjectByID( connectionID );
			if( object && object is Connection )
			{
				return object as Connection;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}


		public function getScaler( scalerID:int ):Scaler
		{
			var object:IntegraDataObject = getDataObjectByID( scalerID );
			if( object && object is Scaler )
			{
				return object as Scaler;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}
		
		
		public function getEnvelope( envelopeID:int ):Envelope
		{
			var object:IntegraDataObject = getDataObjectByID( envelopeID );
			if( object && object is Envelope )
			{
				return object as Envelope;
			} 
			
			return null;
		}
		
		
		public function getEnvelopeTarget( envelopeID:int ):Connection
		{
			var container:IntegraContainer = getParent( envelopeID ) as IntegraContainer;
			Assert.assertNotNull( container );
			
			for each( var connection:Connection in container.connections )
			{
				if( connection.sourceObjectID == envelopeID && connection.sourceAttributeName == "currentValue" )
				{
					return connection;					
				} 
			}
			
			return null;		//envelope target not found
		}


		public function getControlPoint( controlPointID:int ):ControlPoint
		{
			var object:IntegraDataObject = getDataObjectByID( controlPointID );
			if( object && object is ControlPoint )
			{
				return object as ControlPoint;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}


		public function getScript( scriptID:int ):Script
		{
			var object:IntegraDataObject = getDataObjectByID( scriptID );
			if( object && object is Script )
			{
				return object as Script;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}

		
		public function getMidiControlInput( midiControlInputID:int ):MidiControlInput
		{
			var object:IntegraDataObject = getDataObjectByID( midiControlInputID );
			if( object && object is MidiControlInput )
			{
				return object as MidiControlInput;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}
		
		
		public function getModulePosition( moduleInstanceID:int, inventIfUnknown:Boolean = true ):Rectangle
		{
			var block:Block = getBlockFromModuleInstance( moduleInstanceID );
			Assert.assertNotNull( block );
			
			if( block.blockUserData.modulePositions.hasOwnProperty( moduleInstanceID ) )
			{
				return block.blockUserData.modulePositions[ moduleInstanceID ] as Rectangle;
			}
			else
			{
				if( inventIfUnknown )
				{
					var moduleInstance:ModuleInstance = getModuleInstance( moduleInstanceID );
					Assert.assertNotNull( moduleInstance );
					
					return block.blockUserData.getUnusedModulePosition( moduleInstance.interfaceDefinition );
				}
				else
				{
					return null;
				}
			}
		}


		public function getLiveViewControl( moduleID:int, controlInstanceName:String ):LiveViewControl
		{
			var block:Block = getBlockFromModuleInstance( moduleID );
			Assert.assertNotNull( block );
			
			var liveViewControlID:String = LiveViewControl.makeLiveViewControlID( moduleID, controlInstanceName );

			var liveViewControls:Object = block.blockUserData.liveViewControls; 
			if( !liveViewControls.hasOwnProperty( liveViewControlID ) )
			{
				return null;
			} 
			
			return liveViewControls[ liveViewControlID ];
		}
		
		
		public function hasLiveViewControls( moduleID:int ):Boolean
		{
			var module:ModuleInstance = getModuleInstance( moduleID );
			Assert.assertNotNull( module );
			
			for each( var widgetDefinition:WidgetDefinition in module.interfaceDefinition.widgets )
			{
				if( getLiveViewControl( moduleID, widgetDefinition.label ) )
				{
					return true;
				}
			} 
			
			return false;
		}
		
		
		public function getScene( sceneID:int ):Scene
		{
			if( !project.player.scenes.hasOwnProperty( sceneID ) )
			{
				return null;
			}
			
			return project.player.scenes[ sceneID ];
		}
		
		
		public function getTrackIndex( trackID:int ):int
		{
			var track:Track = getTrack( trackID );
			if( !track )
			{
				Assert.assertTrue( false );	//track not found
				return -1;
			}
			
			return project.orderedTracks.indexOf( track );
		}
		
		
		public function getEnvelopeFromControlPoint( controlPointID:int ):Envelope
		{
			var parent:Envelope = getParent( controlPointID ) as Envelope;
			if( parent )
			{
				return parent;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}		
		
		
		public function getBlockFromModuleInstance( instanceID:int ):Block
		{
			var parent:IntegraContainer = getParent( instanceID ) as IntegraContainer;
			if( parent && parent is Block )
			{
				return parent as Block;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}		


		public function getContainerFromConnection( connectionID:int ):IntegraContainer		
		{
			var parent:IntegraContainer = getParent( connectionID ) as IntegraContainer;
			if( parent )
			{
				return parent;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}		
		
		
		public function getContainerFromMidi( midiID:int ):IntegraContainer		
		{
			var parent:IntegraContainer = getParent( midiID ) as IntegraContainer;
			if( parent )
			{
				return parent;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}		


		public function getBlockFromEnvelope( envelopeID:int ):Block		
		{
			var parent:IntegraContainer = getParent( envelopeID ) as IntegraContainer;
			if( parent && parent is Block )
			{
				return parent as Block;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}		


		public function getTrackFromBlock( blockID:int ):Track
		{
			var parent:IntegraContainer = getParent( blockID ) as IntegraContainer;
			if( parent && parent is Track )
			{
				return parent as Track;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}
		
		
		public function getContainerFromScript( scriptID:int ):IntegraContainer
		{
			var parent:IntegraContainer = getParent( scriptID ) as IntegraContainer;
			if( parent  )
			{
				return parent;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}		

		
		public function getContainerFromScaler( scalerID:int ):IntegraContainer
		{
			var parent:IntegraContainer = getParent( scalerID ) as IntegraContainer;
			if( parent  )
			{
				return parent;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}		

		
		public function getContainerFromMidiControlInput( midiControlInputID:int ):IntegraContainer
		{
			var parent:IntegraContainer = getParent( midiControlInputID ) as IntegraContainer;
			if( parent  )
			{
				return parent;
			} 
			
			Assert.assertTrue( false );		//not found, or wrong type
			return null;
		}		
		

		public function getParent( id:int ):IntegraDataObject
		{
			var dataObject:IntegraDataObject = getDataObjectByID( id );
			if( !dataObject )
			{
				Assert.assertTrue( false );
				return null;
			}
			
			if( dataObject.parentID >= 0 )
			{
				var parentObject:IntegraDataObject = getDataObjectByID( dataObject.parentID );
				if( parentObject is Envelope && dataObject is ControlPoint ) 
				{
					return parentObject;
				}

				if( parentObject is Player && dataObject is Scene ) 
				{
					return parentObject;
				}
				
				if( parentObject is IntegraContainer )
				{
					return parentObject;
				}

				Assert.assertTrue( false );	//parent not found or unexpected type
				return null;
			}
			else
			{
				return null;			//it's a top level container, no parent	
			}
		}

		
		public function canSetAudioLink( sourceModuleID:int, sourceAttributeName:String, targetModuleID:int, targetAttributeName:String, existingConnectionID:int = -1 ):Boolean
		{
			var sourceModule:ModuleInstance = getModuleInstance( sourceModuleID );
			var targetModule:ModuleInstance = getModuleInstance( targetModuleID );
			var sourceContainer:IntegraContainer = getParent( sourceModuleID ) as IntegraContainer;
			var targetContainer:IntegraContainer = getParent( targetModuleID ) as IntegraContainer;
			
			
			if( !sourceModule || !targetModule || !sourceContainer || !targetContainer  )
			{
				Assert.assertTrue( false );		
				return false;		//can't find modules 
			}

			if( doesAudioConnectionExistInAncestorChain( sourceContainer, sourceModuleID, sourceAttributeName, targetModuleID, targetAttributeName ) )
			{
				return false;		//connection already exists
			}
			
			if( doesAudioConnectionExistInAncestorChain( targetContainer, sourceModuleID, sourceAttributeName, targetModuleID, targetAttributeName ) )
			{
				return false;		//connection already exists
			}
			
			
			if( sourceModuleID == targetModuleID ) 
			{
				return false;		//can't connect a module to itself	
			}
				
			return !isTargetUpstreamInAudioLinks( sourceModuleID, targetModuleID, existingConnectionID );
		}
		

		public function canSetScaledConnection( sourceObjectID:int, sourceAttributeName:String, targetObjectID:int, targetAttributeName:String, existingScalerID:int = -1 ):Boolean
		{
			if( sourceObjectID < 0 || targetObjectID < 0 || !sourceAttributeName || !targetAttributeName )
			{
				//the command is setting the connection to an unfinished state - this can't cause an illegal state!
				return true;
			}
			
			var sourceObject:IntegraDataObject = getDataObjectByID( sourceObjectID );
			var targetObject:IntegraDataObject = getDataObjectByID( targetObjectID );
			var sourceContainer:IntegraDataObject = getParent( sourceObjectID );
			if( !(sourceContainer is IntegraContainer) && !(sourceContainer is Player ) )
			{
				Assert.assertTrue( false );		
				return false;		 
			}
			
			var targetContainer:IntegraDataObject = getParent( targetObjectID );
			if( !(targetContainer is IntegraContainer) && !(targetContainer is Player ) )
			{
				Assert.assertTrue( false );		
				return false;		 
			}
			
			if( !sourceObject || !targetObject || !sourceContainer || !targetContainer )
			{
				Assert.assertTrue( false );		
				return false;		//can't find modules or parent 
			}

			if( doesScaledConnectionExistInAncestorChain( sourceContainer, sourceObjectID, sourceAttributeName, targetObjectID, targetAttributeName, existingScalerID ) )
			{
				return false;		//connection already exists
			}

			if( doesScaledConnectionExistInAncestorChain( targetContainer, sourceObjectID, sourceAttributeName, targetObjectID, targetAttributeName, existingScalerID ) )
			{
				return false;		//connection already exists
			}
			
			if( sourceObjectID == targetObjectID && sourceAttributeName == targetAttributeName ) 
			{
				return false;		//can't connect an attribute to itself	
			}

			return !isTargetUpstreamInScaledConnections( sourceObjectID, sourceAttributeName, targetObjectID, targetAttributeName, existingScalerID );
		} 


		public function isAudioLink( sourceObjectID:int, sourceAttributeName:String, targetObjectID:int, targetAttributeName:String ):Boolean
		{
			if( sourceObjectID < 0 || targetObjectID < 0 || !sourceAttributeName || !targetAttributeName ) 
			{
				return false;	
			}
			
			var sourceEndpoint:EndpointDefinition = getEndpointDefinition( sourceObjectID, sourceAttributeName );
			var targetEndpoint:EndpointDefinition = getEndpointDefinition( targetObjectID, targetAttributeName );
			
			if( !sourceEndpoint || !targetEndpoint )
			{
				Trace.error( "can't find endpoint definition" );
				return false;
			}

			if( sourceEndpoint.type != EndpointDefinition.STREAM || sourceEndpoint.streamInfo.streamDirection != StreamInfo.DIRECTION_OUTPUT )
			{
				return false;
			}

			if( targetEndpoint.type != EndpointDefinition.STREAM || targetEndpoint.streamInfo.streamDirection != StreamInfo.DIRECTION_INPUT )
			{
				return false;
			}

			return true;
		} 

		
		public function getContainerColor( containerID:int ):uint
		{
			var color:uint = ( project.projectUserData.colorScheme == ColorScheme.DARK ) ? 0xffffff : 0x606060;

			if( !doesObjectExist( containerID ) ) return color;
			
			var active:Boolean = true;
			
			var container:IntegraContainer = getContainer( containerID );
				
			while( true )
			{
				if( container is Track )
				{
					color = ( container as Track ).trackUserData.color;
				}
				
				if( !container.active )
				{
					active = false;
				}
				
				if( container.parentID < 0 ) 
				{
					break;
				}
				else
				{
					container = getContainer( container.parentID );	
				}
			}
			
			if( active ) 
			{
				return color;
			}
			else
			{
				return Utilities.makeGreyscale( color );
			}
		}
		
		
		public function isEqualOrAncestor( candidateAncestorID:int, candidateDescendantID:int ):Boolean
		{
			for( var iterator:int = candidateDescendantID; iterator >= 0; iterator = getDataObjectByID( iterator ).parentID )
			{
				if( iterator == candidateAncestorID ) return true;
			}
			
			return false;
		}
		
		
		public function isConnectionTarget( objectID:int, endpointName:String, upstreamObjects:Vector.<IntegraDataObject> = null ):Boolean
		{
			var isConnectionTarget:Boolean = false;
			
			//walk parent chain looking for connections that target this attribute
			for( var parent:IntegraDataObject = getParent( objectID ); parent; parent = getParent( parent.id ) )
			{
				if( parent is IntegraContainer )
				{
					for each( var connection:Connection in ( parent as IntegraContainer ).connections )
					{
						if( connection.targetObjectID != objectID || connection.targetAttributeName != endpointName )
						{
							continue;
						}
						
						if( connection.sourceObjectID < 0 || connection.sourceAttributeName == null ) 
						{
							continue;
						}
						
						if( upstreamObjects )
						{
							var connectionSource:IntegraDataObject = getDataObjectByID( connection.sourceObjectID );
							upstreamObjects.push( connectionSource );
						}
						
						isConnectionTarget = true;
					}
				}
			}
			
			return isConnectionTarget;
		}
		
		
		public function areThereAnyUpgradableModules( searchRoot:IntegraDataObject ):Boolean
		{
			if( searchRoot is IntegraContainer )
			{
				var container:IntegraContainer = searchRoot as IntegraContainer;
				for each( var child:IntegraDataObject in container.children )
				{
					if( areThereAnyUpgradableModules( child ) )
					{
						return true;
					}
				}
			}
			else
			{
				var interfaceDefinition:InterfaceDefinition = searchRoot.interfaceDefinition;
				var interfaceDefinitions:Vector.<InterfaceDefinition> = getInterfaceDefinitionsByOriginGuid( interfaceDefinition.originGuid );
				Assert.assertTrue( interfaceDefinitions && interfaceDefinitions.length > 0 );
				
				if( interfaceDefinition != interfaceDefinitions[ 0 ] )
				{
					return true;
				}
			}
			
			return false;
		}		
		
		
		public function getUpstreamMidiControlInput( targetID:int, targetEndpointName:String ):MidiControlInput
		{
			var upstreamObjects:Vector.<IntegraDataObject> = new Vector.<IntegraDataObject>; 
			if( isConnectionTarget( targetID, targetEndpointName, upstreamObjects ) )
			{
				for each( var upstreamObject:IntegraDataObject in upstreamObjects )
				{
					if( upstreamObject is Scaler )
					{
						var scaler:Scaler = upstreamObject as Scaler;
						if( scaler.midiControlInput )
						{
							return scaler.midiControlInput;
						}
					}
				}
			}
			
			return null;			
		}

		
		//modification methods 
		public function clearAll():void
		{
			_interfaceList = new Vector.<String>;
			_coreInterfaceDefinitionsByName = new Object;
			_interfaceDefinitionsByModuleGuid = new Object;
			_interfaceDefinitionsByOriginGuid = new Object;
			
			clearInstances();
		}
		
		
		public function clearInstances():void
		{
			_objectMap = new Object();
			_topLevelObjects = new Vector.<IntegraDataObject>;
			_nextID = 1;

			_project = new Project();
			_project.id = generateNewID();
			_project.name = Project.defaultProjectName;
			initializeInterfaceDefinition( _project );
			_objectMap[ _project.id ] = _project;
			_topLevelObjects.push( _project );
			
			//create project player 
			var player:Player = new Player();
			player.id = generateNewID();
			player.name = Player.defaultPlayerName;
			initializeInterfaceDefinition( player );
			addDataObject( _project.id, player );
			
			//create project midi monitor
			var midiMonitor:MidiRawInput = new MidiRawInput();
			midiMonitor.id = generateNewID();
			midiMonitor.name = MidiRawInput.defaultName;
			initializeInterfaceDefinition( midiMonitor );
			addDataObject( _project.id, midiMonitor );
			
			//create settings objects
			_audioSettings = new AudioSettings();
			_audioSettings.id = generateNewID();
			_audioSettings.name = AudioSettings.defaultObjectName; 
			initializeInterfaceDefinition( _audioSettings );
			_objectMap[ _audioSettings.id ] = _audioSettings;
			_topLevelObjects.push( _audioSettings );

			_midiSettings = new MidiSettings();
			_midiSettings.id = generateNewID();
			_midiSettings.name = MidiSettings.defaultObjectName; 
			initializeInterfaceDefinition( _midiSettings );
			_objectMap[ _midiSettings.id ] = _midiSettings;
			_topLevelObjects.push( _midiSettings );
			
			_isProjectModified = false;
		}

		
		public function set projectModified( projectModified:Boolean ):void { _isProjectModified = projectModified; }
		
		
		public function addInterfaceDefinition( interfaceDefinition:InterfaceDefinition ):void
		{
			Assert.assertFalse( _interfaceDefinitionsByModuleGuid.hasOwnProperty( interfaceDefinition.moduleGuid ) );
			
			_interfaceDefinitionsByModuleGuid[ interfaceDefinition.moduleGuid ] = interfaceDefinition;

			if( _interfaceDefinitionsByOriginGuid.hasOwnProperty( interfaceDefinition.originGuid ) )
			{
				var sameOriginList:Vector.<InterfaceDefinition> = _interfaceDefinitionsByOriginGuid[ interfaceDefinition.originGuid ] as Vector.<InterfaceDefinition>;
				Assert.assertNotNull( sameOriginList );
				
				sameOriginList.push( interfaceDefinition );
				sameOriginList.sort( originListCompareFunction );
			}
			else
			{
				sameOriginList = new Vector.<InterfaceDefinition>;
				sameOriginList.push( interfaceDefinition );
				
				_interfaceDefinitionsByOriginGuid[ interfaceDefinition.originGuid ] = sameOriginList;
			}
			
			
			if( interfaceDefinition.isCore )
			{
				if( _coreInterfaceDefinitionsByName.hasOwnProperty( interfaceDefinition.interfaceInfo.name ) )
				{
					Assert.assertTrue( interfaceDefinition.moduleSource != InterfaceDefinition.MODULE_SHIPPED_WITH_INTEGRA );
					return;
				}
				
				_coreInterfaceDefinitionsByName[ interfaceDefinition.interfaceInfo.name ] = interfaceDefinition;
			}
		}
		
		
		public function handleModuleSourcesChanged( moduleGuids:Array, previousModuleSource:String, newModuleSource:String ):void
		{
			for each( var moduleGuid:String in moduleGuids )
			{
				var interfaceDefinition:InterfaceDefinition = getInterfaceDefinitionByModuleGuid( moduleGuid );
				if( !interfaceDefinition )
				{
					Trace.error( "Can't find embedded module", moduleGuid );
					continue;
				}
				
				if( interfaceDefinition.moduleSource != previousModuleSource )
				{
					Trace.error( "Unexpected module source", moduleGuid, interfaceDefinition.moduleSource );
					continue;
				}
				
				interfaceDefinition.moduleSource = newModuleSource;
			}
		}
		
		
		public function removeInterfaceDefinitions( removedModuleGuids:Array ):void
		{
			var removedGuidMap:Object = new Object;
			
			//remove from module id map
			for each( var moduleGuid:String in removedModuleGuids )
			{
				removedGuidMap[ moduleGuid ] = 1;
				
				Assert.assertTrue( _interfaceDefinitionsByModuleGuid.hasOwnProperty( moduleGuid ) );
				delete _interfaceDefinitionsByModuleGuid[ moduleGuid ];
			}
			
			//remove from interface list
			for( var i:int = _interfaceList.length - 1; i >= 0; i-- ) 
			{
				if( removedGuidMap.hasOwnProperty( _interfaceList[ i ] ) )
				{
					_interfaceList.splice( i, 1 );
				}
			}
			
			//remove from origin list
			for( var originGuid:String in _interfaceDefinitionsByOriginGuid )
			{
				var originList:Vector.<InterfaceDefinition> = _interfaceDefinitionsByOriginGuid[ originGuid ];
				
				for( i = originList.length - 1; i >= 0; i-- ) 
				{
					if( removedGuidMap.hasOwnProperty( originList[ i ].moduleGuid ) )
					{
						originList.splice( i, 1 );
					}
				}
				
				if( originList.length == 0 )
				{
					delete _interfaceDefinitionsByOriginGuid[ originGuid ];
				}
			}
			
			//assert that module isn't in core list
			for each( var coreInterface:InterfaceDefinition in _coreInterfaceDefinitionsByName )
			{
				Assert.assertFalse( removedGuidMap.hasOwnProperty( coreInterface.moduleGuid ) );
			}
		}
		
		

		public function generateNewID():int
		{
			var id:int = _nextID;
			_nextID++;
			return id;
		}
		
		
		public function addDataObject( parentID:int, newObject:IntegraDataObject ):Boolean
		{
			var newID:int = newObject.id;
			if( newID < 0 || _objectMap.hasOwnProperty( newID ) )
			{
				Assert.assertTrue( false );		//new object must have a positive id which is not yet in use
				return false;
			}
			
			var parent:IntegraDataObject = getDataObjectByID( parentID );
			if( parent is IntegraContainer )
			{
				var container:IntegraContainer = parent as IntegraContainer;
				if( container.children.hasOwnProperty( newID ) )
				{
					Assert.assertTrue( false );		
					return false;
				}
		
				for each( var existingChild:IntegraDataObject in container.children )
				{
					if( existingChild.name == newObject.name )
					{	
						Assert.assertTrue( false );	//new object's name must be unique amongst siblings
						return false;
					}
				} 		
				
				container.children[ newID ] = newObject;
				container.childrenChanged();
			}
			
			if( parent is Envelope )
			{
				var envelope:Envelope = parent as Envelope;
				if( !newObject is ControlPoint || envelope.controlPoints.hasOwnProperty( newID ) )
				{
					Assert.assertTrue( false );		
					return false;
				}
		
				for each( var existingControlPoint:ControlPoint in envelope.controlPoints )
				{
					if( existingControlPoint.name == newObject.name )
					{	
						Assert.assertTrue( false );	//new object's name must be unique amongst siblings
						return false;
					}
				} 		
				
				envelope.controlPoints[ newID ] = newObject;
			}

			if( parent is Player )
			{
				var player:Player = parent as Player;
				if( !newObject is Scene || player.scenes.hasOwnProperty( newID ) )
				{
					Assert.assertTrue( false );		
					return false;
				}
				
				for each( var existingScene:Scene in player.scenes )
				{
					if( existingScene.name == newObject.name )
					{	
						Assert.assertTrue( false );	//new object's name must be unique amongst siblings
						return false;
					}
				} 		
				
				player.scenes[ newID ] = newObject;
			}
			
			if( !newObject.interfaceDefinition )
			{
				initializeInterfaceDefinition( newObject );
			}			
			
			newObject.parentID = parentID;
			_objectMap[ newID ] = newObject;
			return true;
		}


		public function removeDataObject( objectID:int ):Boolean
		{
			var object:IntegraDataObject = getDataObjectByID( objectID );
			if( !object )
			{
				Assert.assertTrue( false );		//object not found
				return false;
			}
			
			if( object is IntegraContainer )
			{
				var container:IntegraContainer = object as IntegraContainer;
				if( !Utilities.isObjectEmpty( container.children ) )
				{
					Assert.assertTrue( false );		//can't remove a non-empty container
					return false;
				}
			}

			if( object is Envelope )
			{
				var envelope:Envelope = object as Envelope;
				if( !Utilities.isObjectEmpty( envelope.controlPoints ) )
				{
					Assert.assertTrue( false );		//can't remove a non-empty envelope
					return false;
				}
			}

			if( object is Player )
			{
				var player:Player = object as Player;
				if( !Utilities.isObjectEmpty( player.scenes ) )
				{
					Assert.assertTrue( false );		//can't remove a non-empty player
					return false;
				}
			}

			var parent:IntegraDataObject = getParent( objectID );
			if( parent is IntegraContainer )
			{
				var parentContainer:IntegraContainer = parent as IntegraContainer;
				Assert.assertTrue( parentContainer.children.hasOwnProperty( objectID ) );
				delete parentContainer.children[ objectID ];
				
				parentContainer.childrenChanged();
			}
			
			if( parent is Envelope )
			{
				var parentEnvelope:Envelope = parent as Envelope;
				Assert.assertTrue( parentEnvelope.controlPoints.hasOwnProperty( objectID ) );
				delete parentEnvelope.controlPoints[ objectID ];
			}

			if( parent is Player )
			{
				var parentPlayer:Player = parent as Player;
				Assert.assertTrue( parentPlayer.scenes.hasOwnProperty( objectID ) );
				delete parentPlayer.scenes[ objectID ];
			}

			delete _objectMap[ objectID ];
			return true;
		}


		public function reparentDataObject( objectID:int, newParentID:int ):Boolean
		{
			var object:IntegraDataObject = getDataObjectByID( objectID );
			if( !object )
			{
				Assert.assertTrue( false );		//object not found
				return false;
			}			

			//add reference to new parent
			var newParent:IntegraDataObject = getDataObjectByID( newParentID );
			if( newParent is IntegraContainer )
			{
				var container:IntegraContainer = newParent as IntegraContainer;
				if( container.children.hasOwnProperty( objectID ) )
				{
					Assert.assertTrue( false );		//already has a child with this object id
					return false;
				}
		
				for each( var existingChild:IntegraDataObject in container.children )
				{
					if( existingChild.name == object.name )
					{	
						Assert.assertTrue( false );	//object's name must be unique amongst new siblings
						return false;
					}
				} 		
				
				container.children[ objectID ] = object;
				container.childrenChanged();
			}
			
			if( newParent is Envelope )
			{
				var envelope:Envelope = newParent as Envelope;
				if( !object is ControlPoint || envelope.controlPoints.hasOwnProperty( objectID ) )
				{
					Assert.assertTrue( false );		//already has a child with this object id, or object is wrong type
					return false;
				}
		
				for each( var existingControlPoint:ControlPoint in envelope.controlPoints )
				{
					if( existingControlPoint.name == object.name )
					{	
						Assert.assertTrue( false );	//object's name must be unique amongst new siblings
						return false;
					}
				} 		
				
				envelope.controlPoints[ objectID ] = object;
			}

			if( newParent is Player )
			{
				var player:Player = newParent as Player;
				if( !object is Scene || player.scenes.hasOwnProperty( objectID ) )
				{
					Assert.assertTrue( false );		//already has a child with this object id, or object is wrong type
					return false;
				}
				
				for each( var existingScene:Scene in player.scenes )
				{
					if( existingScene.name == object.name )
					{	
						Assert.assertTrue( false );	//object's name must be unique amongst new siblings
						return false;
					}
				} 		
				
				player.scenes[ objectID ] = object;
			}

			
			//remove reference from previous parent
			var previousParent:IntegraDataObject = getParent( objectID );
			if( previousParent is IntegraContainer )
			{
				var parentContainer:IntegraContainer = previousParent as IntegraContainer;
				Assert.assertTrue( parentContainer.children.hasOwnProperty( objectID ) );
				delete parentContainer.children[ objectID ];
				parentContainer.childrenChanged();
			}
			
			if( previousParent is Envelope )
			{
				var parentEnvelope:Envelope = previousParent as Envelope;
				Assert.assertTrue( parentEnvelope.controlPoints.hasOwnProperty( objectID ) );
				delete parentEnvelope.controlPoints[ objectID ];
			}

			if( previousParent is Player )
			{
				var parentPlayer:Player = previousParent as Player;
				Assert.assertTrue( parentPlayer.scenes.hasOwnProperty( objectID ) );
				delete parentPlayer.scenes[ objectID ];
			}
			
			//update object's own parent id
			object.parentID = newParentID;
			
			return true;
		}
		
		
		public function updateProjectLength():void
		{
			const minProjectSeconds:int = 60;
			const extraSeconds:int = 10;
			
			_projectLength = minProjectSeconds * project.player.rate;
			var extraTicks:int = extraSeconds * project.player.rate;
			
			for each( var track:Track in project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					_projectLength = Math.max( _projectLength, block.end + extraTicks );
				}
			}
			
			for each( var scene:Scene in project.player.scenes )
			{
				_projectLength = Math.max( _projectLength, scene.end + extraTicks );
			}
		}
		

		public function set filename( filename:String ):void { _filename = filename; }
		public function set currentInfo( currentInfo:Info ):void { _currentInfo = currentInfo; }
		public function set showInfoView( showInfoView:Boolean ):void { _showInfoView = showInfoView; }
		public function set alwaysUpgrade( alwaysUpgrade:Boolean ):void { _alwaysUpgrade = alwaysUpgrade; }
		
		//private helper methods

		
		private function initializeInterfaceDefinition( object:IntegraDataObject ):void
		{
			object.interfaceDefinition = getCoreInterfaceDefinitionByName( object.serverInterfaceName );
		}

		
		private function doesScaledConnectionExistInAncestorChain( container:IntegraDataObject, sourceObjectID:int, sourceAttributeName:String, targetObjectID:int, targetAttributeName:String, scalerIDToIgnore:int ):Boolean
		{
			if( container is IntegraContainer ) 
			{
				for each( var existingScaler:Scaler in ( container as IntegraContainer ).scalers )
				{
					if( existingScaler.id == scalerIDToIgnore )
					{
						continue;
					}
					
					if( existingScaler.upstreamConnection.sourceObjectID == sourceObjectID && 
						existingScaler.upstreamConnection.sourceAttributeName == sourceAttributeName &&
						existingScaler.downstreamConnection.targetObjectID == targetObjectID && 
						existingScaler.downstreamConnection.targetAttributeName == targetAttributeName )
					{
						return true;	
					} 
				}
			}
			
			var parentContainer:IntegraContainer = getParent( container.id ) as IntegraContainer;
			if( parentContainer )
			{
				if( doesScaledConnectionExistInAncestorChain( parentContainer, sourceObjectID, sourceAttributeName, targetObjectID, targetAttributeName, scalerIDToIgnore ) )
				{
					return true;
				}
			}
			
			return false;
		}

		
		private function doesAudioConnectionExistInAncestorChain( container:IntegraContainer, sourceObjectID:int, sourceAttributeName:String, targetObjectID:int, targetAttributeName:String ):Boolean
		{
			for each( var existingConnection:Connection in container.connections )
			{
				if( existingConnection.sourceObjectID == sourceObjectID && 
					existingConnection.sourceAttributeName == sourceAttributeName &&
					existingConnection.targetObjectID == targetObjectID && 
					existingConnection.targetAttributeName == targetAttributeName )
				{
					return true;	
				} 
			}
			
			var parentContainer:IntegraContainer = getParent( container.id ) as IntegraContainer;
			if( parentContainer )
			{
				if( doesAudioConnectionExistInAncestorChain( parentContainer, sourceObjectID, sourceAttributeName, targetObjectID, targetAttributeName ) )
				{
					return true;
				}
			}
			
			return false;
		}
		

		private function isTargetUpstreamInAudioLinks( sourceObjectID:int, targetObjectID:int, connectionToIgnoreID:int, visitedNodes:Object = null ):Boolean
		{
			if( !visitedNodes )
			{
				visitedNodes = new Object;
			}

			visitedNodes[ sourceObjectID ] = 1;
			
			var upstreamConnections:Vector.<Connection> = getUpstreamAudioConnections( sourceObjectID );

			for each( var upstreamConnection:Connection in upstreamConnections )
			{
				if( upstreamConnection.id == connectionToIgnoreID )
				{
					continue;
					
				}
				var connectionSourceID:int = upstreamConnection.sourceObjectID;
				 
				if( connectionSourceID == targetObjectID )
				{
					return true;
				}
				
				if( visitedNodes.hasOwnProperty( connectionSourceID ) )
				{
					continue;
				}
				
				if( isTargetUpstreamInAudioLinks( connectionSourceID, targetObjectID, connectionToIgnoreID, visitedNodes ) )
				{
					return true;
				}
			}

			return false;
		}


		private function getUpstreamAudioConnections( objectID:int ):Vector.<Connection>
		{
			var results:Vector.<Connection> = new Vector.<Connection>; 
			
			for( var container:IntegraContainer = getParent( objectID ) as IntegraContainer; container; container = getParent( container.id ) as IntegraContainer )
			{
				var connectionsInThisContainer:Object = container.connections;

				for each( var connection:Connection in connectionsInThisContainer )
				{
					if( !isAudioLink( connection.sourceObjectID, connection.sourceAttributeName, connection.targetObjectID, connection.targetAttributeName ) )
					{
						continue;
					}
				
					if( connection.targetObjectID == objectID )
					{
						results.push( connection );
					}
				}
			}
			
			return results;
		}


		private function isTargetUpstreamInScaledConnections( sourceObjectID:int, sourceAttributeName:String, targetObjectID:int, targetAttributeName:String, scalerToIgnoreID:int, visitedNodes:Object = null ):Boolean
		{
			if( !visitedNodes )
			{
				visitedNodes = new Object;
			}

			visitedNodes[ String( sourceObjectID ) + sourceAttributeName ] = 1;
			
			var upstreamScaledConnections:Vector.<Scaler> = getUpstreamScaledConnections( sourceObjectID, sourceAttributeName );

			for each( var scaler:Scaler in upstreamScaledConnections )
			{
				if( scaler.id == scalerToIgnoreID )
				{
					continue;
				}
				
				var connectionSourceID:int = scaler.upstreamConnection.sourceObjectID;
				var connectionSourceAttributeName:String = scaler.upstreamConnection.sourceAttributeName;
				 
				if( connectionSourceID < 0 || connectionSourceAttributeName == null )
				{
					continue;
				}
				
				if( connectionSourceID == targetObjectID && connectionSourceAttributeName == targetAttributeName )
				{
					return true;
				}
				
				if( visitedNodes.hasOwnProperty( String( connectionSourceID ) + connectionSourceAttributeName ) )
				{
					continue;
				}
				
				if( isTargetUpstreamInScaledConnections( connectionSourceID, connectionSourceAttributeName, targetObjectID, targetAttributeName, scalerToIgnoreID, visitedNodes ) )
				{
					return true;
				}
			}

			return false;
		}


		private function getUpstreamScaledConnections( objectID:int, attributeName:String ):Vector.<Scaler>
		{
			var results:Vector.<Scaler> = new Vector.<Scaler>; 

			for( var container:IntegraContainer = getParent( objectID ) as IntegraContainer; container; container = getParent( container.id ) as IntegraContainer )
			{
				var scalersInThisContainer:Object = container.scalers;
			
				for each( var scaler:Scaler in scalersInThisContainer )
				{
					if( scaler.downstreamConnection.targetObjectID == objectID && scaler.downstreamConnection.targetAttributeName == attributeName )
					{
						results.push( scaler );
					}
				}
			}
			
			return results;
		}

		
		private function originListCompareFunction( a:InterfaceDefinition, b:InterfaceDefinition ):Number
		{
			Assert.assertEquals( a.originGuid, b.originGuid );

			var sourcePriority:Object = new Object;
			sourcePriority[ InterfaceDefinition.MODULE_SHIPPED_WITH_INTEGRA ] = 2;
			sourcePriority[ InterfaceDefinition.MODULE_THIRD_PARTY ] = 1;
			sourcePriority[ InterfaceDefinition.MODULE_EMBEDDED ] = 0;
			
			var sourcePriorityA:Number = sourcePriority[ a.moduleSource ];
			var sourcePriorityB:Number = sourcePriority[ b.moduleSource ];
			
			if( sourcePriorityA > sourcePriorityB ) return -1;
			if( sourcePriorityB > sourcePriorityA ) return 1;

			return ( a.interfaceInfo.modifiedDate.getTime() > b.interfaceInfo.modifiedDate.getTime() ) ? -1 : 1;
		}
		

		private var _interfaceList:Vector.<String>;
		private var _interfaceDefinitionsByModuleGuid:Object;
		private var _interfaceDefinitionsByOriginGuid:Object;
		private var _coreInterfaceDefinitionsByName:Object;
		
		private var _project:Project;
		private var _isProjectModified:Boolean;
		
		private var _projectLength:int = 0;
		private var _filename:String = null;
		private var _currentInfo:Info = null;
		private var _showInfoView:Boolean = true;
		private var _alwaysUpgrade:Boolean = false;
		
		
		private var _audioSettings:AudioSettings;
		private var _midiSettings:MidiSettings;

		private var _nextID:int;
		
		private var _topLevelObjects:Vector.<IntegraDataObject>;
		private var _objectMap:Object;
		
		private static var _singleInstance:IntegraModel = null;
	}
}
