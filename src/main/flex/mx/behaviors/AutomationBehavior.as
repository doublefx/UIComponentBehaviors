package mx.behaviors
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	
	import mx.automation.IAutomationObject;
	import mx.core.UIComponent;
	
	public class AutomationBehavior implements IAutomationObject
	{
		private var uiComponent:UIComponent;
		
		public function AutomationBehavior(uiComponent:UIComponent)
		{
			this.uiComponent = uiComponent;
		}
		
		
		//--------------------------------------------------------------------------
		//
		//  Properties: Required to support automated testing
		//
		//--------------------------------------------------------------------------
		
		//----------------------------------
		//  automationDelegate
		//----------------------------------
		
		/**
		 *  @private
		 */
		private var _automationDelegate:IAutomationObject;
		
		/**
		 *  The delegate object that handles the automation-related functionality.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get automationDelegate():Object
		{
			return _automationDelegate;
		}
		
		/**
		 *  @private
		 */
		public function set automationDelegate(value:Object):void
		{
			_automationDelegate = value as IAutomationObject;
		}
		
		//----------------------------------
		//  automationName
		//----------------------------------
		
		/**
		 *  @private
		 *  Storage for the <code>automationName</code> property.
		 */
		private var _automationName:String = null;
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get automationName():String
		{
			if (_automationName)
				return _automationName;
			if (automationDelegate)
				return automationDelegate.automationName;
			
			return "";
		}
		
		/**
		 *  @private
		 */
		public function set automationName(value:String):void
		{
			_automationName = value;
		}
		
		/**
		 *  @copy mx.automation.IAutomationObject#automationValue
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get automationValue():Array
		{
			if (automationDelegate)
				return automationDelegate.automationValue;
			
			return [];
		}
		
		//----------------------------------
		//  showInAutomationHierarchy
		//----------------------------------
		
		/**
		 *  @private
		 *  Storage for the <code>showInAutomationHierarchy</code> property.
		 */
		private var _showInAutomationHierarchy:Boolean = true;
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get showInAutomationHierarchy():Boolean
		{
			return _showInAutomationHierarchy;
		}
		
		/**
		 *  @private
		 */
		public function set showInAutomationHierarchy(value:Boolean):void
		{
			_showInAutomationHierarchy = value;
		}
		
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function createAutomationIDPart(child:IAutomationObject):Object
		{
			if (automationDelegate)
				return automationDelegate.createAutomationIDPart(child);
			return null;
		}
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function createAutomationIDPartWithRequiredProperties(child:IAutomationObject,
																	 properties:Array):Object
		{
			if (automationDelegate)
				return automationDelegate.createAutomationIDPartWithRequiredProperties(child, properties);
			return null;
		}
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function resolveAutomationIDPart(criteria:Object):Array
		{
			if (automationDelegate)
				return automationDelegate.resolveAutomationIDPart(criteria);
			return [];
		}
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function getAutomationChildAt(index:int):IAutomationObject
		{
			if (automationDelegate)
				return automationDelegate.getAutomationChildAt(index);
			return null;
		}
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function getAutomationChildren():Array
		{
			if (automationDelegate)
				return automationDelegate.getAutomationChildren();
			return null;
		}
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get numAutomationChildren():int
		{
			if (automationDelegate)
				return automationDelegate.numAutomationChildren;
			return 0;
		}
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get automationTabularData():Object
		{
			if (automationDelegate)
				return automationDelegate.automationTabularData;
			return null;
		}
		
		//----------------------------------
		//  automationOwner
		//----------------------------------
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 4
		 */
		public function get automationOwner():DisplayObjectContainer
		{
			return uiComponent.owner;
		}
		
		//----------------------------------
		//  automationParent
		//----------------------------------
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 4
		 */
		public function get automationParent():DisplayObjectContainer
		{
			return uiComponent.parent;
		}
		
		//----------------------------------
		//  automationEnabled
		//----------------------------------
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 4
		 */
		public function get automationEnabled():Boolean
		{
			return uiComponent.enabled;
		}
		
		//----------------------------------
		//  automationVisible
		//----------------------------------
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 4
		 */
		public function get automationVisible():Boolean
		{
			return uiComponent.visible;
		}
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function replayAutomatableEvent(event:Event):Boolean
		{
			if (automationDelegate)
				return automationDelegate.replayAutomatableEvent(event);
			return false;
		}
	}
}