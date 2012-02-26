package flexUnitTests.Behaviors
{
	import flexunit.framework.Assert;
	
	import mx.core.UIComponent;
	
	import spark.components.VGroup;	
	
	public class InstanciationBehaviorsTest
	{		
		private static const NB_INSTANCES_TO_CREATE:int = 1;
		
		[Before]
		public function setUp():void
		{
		}
		
		[After]
		public function tearDown():void
		{
		}
		
		[BeforeClass]
		public static function setUpBeforeClass():void
		{
		}
		
		[AfterClass]
		public static function tearDownAfterClass():void
		{
		}
		
		[Test]
		public function testDefaultUIComponent():void
		{
			var uiAr:Array = new Array();
			for (var i:int; i<NB_INSTANCES_TO_CREATE; i++)
			{
				uiAr[i] = new UIComponent();
				Assert.assertNotNull(uiAr[i]);
			}
		}
		
		[Test]
		public function testDefaultVGroup():void
		{
			var uiAr:Array = new Array();
			for (var i:int; i<NB_INSTANCES_TO_CREATE; i++)
			{
				uiAr[i] = new VGroup();
				Assert.assertNotNull(uiAr[i]);
			}
		}
	}
}