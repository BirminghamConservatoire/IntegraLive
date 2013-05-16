package
{
	import flash.geom.Point;

	public class WidgetDefinition
	{
		public var name:String;
		
		public var attributes:Vector.<String> = new Vector.<String>;
		
		public var defaultSize:Point = new Point;
		public var minimumSize:Point = new Point;
		public var maximumSize:Point = new Point;
	}
}