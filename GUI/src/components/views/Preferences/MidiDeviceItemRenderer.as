package components.views.Preferences
{
	import mx.controls.listClasses.ListBase;
	import mx.controls.listClasses.ListItemRenderer;
	
	public class MidiDeviceItemRenderer extends ListItemRenderer
	{
		public function MidiDeviceItemRenderer()
		{
			super();
		}
		
		
		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			if( ListBase( owner ).isItemSelected( data ) )
			{
				//draw a tick
				graphics.lineStyle( 2, getStyle( "color" ) );
				graphics.moveTo( height * 0.25, height * 0.5 );
				graphics.lineTo( height * 0.5, height * 0.75 );
				graphics.lineTo( height * 0.75, height * 0.25 );
			}
		}
	}
}