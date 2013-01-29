package components.controller.userDataCommands
{
	import components.controller.Command;
	import components.controller.IntegraController;
	import components.controller.UserDataCommand;
	import components.model.IntegraModel;
	import components.model.userData.TimelineState;
	import components.views.Timeline.Timeline;
	import components.views.MouseCapture;
	
	import flexunit.framework.Assert;

	public class DoTimelineAutoscroll extends UserDataCommand
	{
		public function DoTimelineAutoscroll()
		{
			super();
		}
				
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return !MouseCapture.instance.hasCapture;
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			//scrolls when playhead is more than this proportion through visible timeline
			const timelineLeftProportion:Number = 0.1;	 
			const timelineRightProportion:Number = 0.8;	 
			
			var timelineState:TimelineState = model.project.userData.timelineState;
			
			var playheadPixels:Number = timelineState.ticksToPixels( model.project.player.playPosition );
			
			var newScroll:Number = timelineState.scroll;
			
			var timelineLeftPixels:Number = Timeline.timelineWidth * timelineLeftProportion;
			var timelineRightPixels:Number = Timeline.timelineWidth * timelineRightProportion;
			
			if( playheadPixels < timelineLeftPixels || playheadPixels > timelineRightPixels )
			{
				newScroll = Math.max( 0, model.project.player.playPosition - timelineLeftPixels / timelineState.zoom );
			}
			
			if( newScroll != timelineState.scroll )
			{
				var newTimelineState:TimelineState = new TimelineState;
				newTimelineState.copyFrom( timelineState );
				
				newTimelineState.scroll = newScroll;
				
				controller.processCommand( new SetTimelineState( newTimelineState ) );
			}
		}

		
		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void 
		{ 
			//no objects' user data is directly affected by this command, because it doesn't implement 'execute'	
		}
		
	}
}