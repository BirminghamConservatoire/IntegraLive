package components.controller.userDataCommands
{
	import components.controller.Command;
	import components.controller.UserDataCommand;
	import components.model.IntegraModel;
	import components.model.userData.TimelineState;
	
	import flexunit.framework.Assert;

	public class SetTimelineState extends UserDataCommand
	{
		public function SetTimelineState( timelineState:TimelineState )
		{
			super();
			
			_timelineState = timelineState;
		}
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			if( _timelineState.deepCompare( model.project.userData.timelineState ) )
			{
				return false;
			}
			
			return true;
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new SetTimelineState( model.project.userData.timelineState ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			model.project.userData.timelineState = _timelineState;
		}
		
		
		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean
		{
			Assert.assertTrue( previousCommand is SetTimelineState );
			return true;
		}
		
		
		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( model.project.id );	
		}		
		
		
		private var _timelineState:TimelineState;
	}
}