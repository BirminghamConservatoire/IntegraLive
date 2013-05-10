package
{
	import mx.containers.Accordion;
	
	public class MyAccordion extends Accordion
	{
		public function MyAccordion()
		{
			super();
		}
		
		override protected function measure():void
		{
			super.measure();

			/*
			emprirically, this bizarre tweak stops accordions with large numbers of children 
			from displaying	excessive amounts of whitespace below the selected child
			*/
			
			measuredHeight -= Math.max( 0, numChildren - 10 );
		}
	}
}