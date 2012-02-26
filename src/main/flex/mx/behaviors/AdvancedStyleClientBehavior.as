package mx.behaviors
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.text.TextFormatAlign;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.FlexVersion;
	import mx.core.IChildList;
	import mx.core.IRawChildrenContainer;
	import mx.core.IUITextField;
	import mx.core.UIComponent;
	import mx.core.UITextFormat;
	import mx.core.mx_internal;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.IAdvancedStyleClient;
	import mx.styles.ISimpleStyleClient;
	import mx.styles.IStyleClient;
	import mx.styles.IStyleManager2;
	import mx.styles.StyleProtoChain;
	import mx.utils.ColorUtil;
	import mx.utils.StringUtil;
	
	use namespace mx_internal;
	
	public class AdvancedStyleClientBehavior implements IAdvancedStyleClient
	{
		private var uiComponent:UIComponent;
		
		/**
		 *  @private
		 *  Temporarily stores the values of styles specified with setStyle() until
		 *  moduleFactory is set.
		 */
		private var deferredSetStyles:Object;
		
		//--------------------------------------------------------------------------
		//
		//  Variables: Styles
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  @private
		 */
		mx_internal var cachedTextFormat:UITextFormat;
		
		
		//----------------------------------
		//  resourceManager
		//----------------------------------
		
		/**
		 *  @private
		 *  Storage for the resourceManager property.
		 */
		private var _resourceManager:IResourceManager = ResourceManager.getInstance();
		
		/**
		 *  @private
		 *  This metadata suppresses a trace() in PropertyWatcher:
		 *  "warning: unable to bind to property 'resourceManager' ..."
		 */
		
		/**
		 *  A reference to the object which manages
		 *  all of the application's localized resources.
		 *  This is a singleton instance which implements
		 *  the IResourceManager interface.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		protected function get resourceManager():IResourceManager
		{
			return _resourceManager;
		}
		
		
		//----------------------------------
		//  conructor
		//----------------------------------
		
		public function AdvancedStyleClientBehavior(uiComponent:UIComponent)
		{
			this.uiComponent = uiComponent;
		}
		
		
		
		//--------------------------------------------------------------------------
		//
		//  Properties: Styles
		//
		//--------------------------------------------------------------------------
		
		
		//----------------------------------
		//  styleName
		//----------------------------------
		
		/**
		 *  @private
		 *  Storage for the styleName property.
		 */
		private var _styleName:Object /* String, CSSStyleDeclaration, or UIComponent */;
		
		/**
		 *  The class style used by this component. This can be a String, CSSStyleDeclaration
		 *  or an IStyleClient.
		 *
		 *  <p>If this is a String, it is the name of one or more whitespace delimited class
		 *  declarations in an <code>&lt;fx:Style&gt;</code> tag or CSS file. You do not include the period
		 *  in the <code>styleName</code>. For example, if you have a class style named <code>".bigText"</code>,
		 *  set the <code>styleName</code> property to <code>"bigText"</code> (no period).</p>
		 *
		 *  <p>If this is an IStyleClient (typically a UIComponent), all styles in the
		 *  <code>styleName</code> object are used by this component.</p>
		 *
		 *  @default null
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get styleName():Object /* String, CSSStyleDeclaration, or UIComponent */
		{
			return _styleName;
		}
		
		/**
		 *  @private
		 */
		public function set styleName(value:Object /* String, CSSStyleDeclaration, or UIComponent */):void
		{
			if (_styleName === value)
				return;
			
			_styleName = value;
			
			// If inheritingStyles is undefined, then this object is being
			// initialized and we haven't yet generated the proto chain.
			// To avoid redundant work, don't bother to create
			// the proto chain here.
			if (inheritingStyles == StyleProtoChain.STYLE_UNINITIALIZED)
				return;
			
			regenerateStyleCache(true);
			
			initThemeColor();
			
			styleChanged("styleName");
			
			notifyStyleChangeInChildren("styleName", true);
		}
		
		//----------------------------------
		//  inheritingStyles
		//----------------------------------
		
		/**
		 *  @private
		 *  Storage for the inheritingStyles property.
		 */
		private var _inheritingStyles:Object = StyleProtoChain.STYLE_UNINITIALIZED;
		
		/**
		 *  The beginning of this component's chain of inheriting styles.
		 *  The <code>getStyle()</code> method simply accesses
		 *  <code>inheritingStyles[styleName]</code> to search the entire
		 *  prototype-linked chain.
		 *  This object is set up by <code>initProtoChain()</code>.
		 *  Developers typically never need to access this property directly.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get inheritingStyles():Object
		{
			return _inheritingStyles;
		}
		
		/**
		 *  @private
		 */
		public function set inheritingStyles(value:Object):void
		{
			_inheritingStyles = value;
		}
		
		//----------------------------------
		//  nonInheritingStyles
		//----------------------------------
		
		/**
		 *  @private
		 *  Storage for the nonInheritingStyles property.
		 */
		private var _nonInheritingStyles:Object =
			StyleProtoChain.STYLE_UNINITIALIZED;
		
		/**
		 *  The beginning of this component's chain of non-inheriting styles.
		 *  The <code>getStyle()</code> method simply accesses
		 *  <code>nonInheritingStyles[styleName]</code> to search the entire
		 *  prototype-linked chain.
		 *  This object is set up by <code>initProtoChain()</code>.
		 *  Developers typically never need to access this property directly.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get nonInheritingStyles():Object
		{
			return _nonInheritingStyles;
		}
		
		/**
		 *  @private
		 */
		public function set nonInheritingStyles(value:Object):void
		{
			_nonInheritingStyles = value;
		}
		
		//----------------------------------
		//  styleDeclaration
		//----------------------------------
		
		/**
		 *  @private
		 *  Storage for the styleDeclaration property.
		 */
		private var _styleDeclaration:CSSStyleDeclaration;
		
		/**
		 *  Storage for the inline inheriting styles on this object.
		 *  This CSSStyleDeclaration is created the first time that
		 *  the <code>setStyle()</code> method
		 *  is called on this component to set an inheriting style.
		 *  Developers typically never need to access this property directly.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get styleDeclaration():CSSStyleDeclaration
		{
			return _styleDeclaration;
		}
		
		/**
		 *  @private
		 */
		public function set styleDeclaration(value:CSSStyleDeclaration):void
		{
			_styleDeclaration = value;
		}
		
		////////////////////////////////////////////////
		
		public function get id():String
		{
			return uiComponent.id;
		}
		
		
		
		//----------------------------------
		//  styleManager
		//----------------------------------
		
		
		/**
		 *  Returns the StyleManager instance used by this component.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		public function get styleManager():IStyleManager2
		{
			return uiComponent.styleManager;
		}
		
		//--------------------------------------------------------------------------
		//
		//  Methods: Styling
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  The state to be used when matching CSS pseudo-selectors. By default
		 *  this is the <code>currentState</code>.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 2.5
		 *  @productversion Flex 4.5
		 */
		protected function get currentCSSState():String
		{
			return uiComponent.currentState;
		}
		
		/**
		 *  A component's parent is used to evaluate descendant selectors. A parent
		 *  must also be an IAdvancedStyleClient to participate in advanced style
		 *  declarations.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get styleParent():IAdvancedStyleClient
		{
			// Implemented in UIComponent for optimization.
			//return uiComponent.parent as IAdvancedStyleClient;
			return null;
		}
		
		public function set styleParent(parent:IAdvancedStyleClient):void
		{
			
		}
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function matchesCSSState(cssState:String):Boolean
		{
			// Implemented in UIComponent for optimization.
			//return uiComponent.matchesCSSState(cssState);
			return false;
		}
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function matchesCSSType(cssType:String):Boolean
		{
			// Implemented in UIComponent for optimization.
			//return uiComponent.matchesCSSType(cssType);
			return false;
		}
		
		/**
		 *  @inheritDoc
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 2.5
		 *  @productversion Flex 4.6
		 */
		public function hasCSSState():Boolean
		{
			// Implemented in UIComponent for optimization.
			//return uiComponent.hasCSSState();
			return false;
		}
		
		/**
		 *  @private
		 *  Sets up the inheritingStyles and nonInheritingStyles objects
		 *  and their proto chains so that getStyle() can work.
		 */
		//  Note that initProtoChain is 99% copied into DataGridItemRenderer
		mx_internal function initProtoChain():void
		{
			StyleProtoChain.initProtoChain(uiComponent);
		}
		
		/**
		 *  Finds the type selectors for this UIComponent instance.
		 *  The algorithm walks up the superclass chain.
		 *  For example, suppose that class MyButton extends Button.
		 *  A MyButton instance first looks for a MyButton type selector
		 *  then, it looks for a Button type selector.
		 *  then, it looks for a UIComponent type selector.
		 *  (The superclass chain is considered to stop at UIComponent, not Object.)
		 *
		 *  @return An Array of type selectors for this UIComponent instance.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function getClassStyleDeclarations():Array
		{
			return StyleProtoChain.getClassStyleDeclarations(uiComponent);
		}
		
		/**
		 *  Builds or rebuilds the CSS style cache for this component
		 *  and, if the <code>recursive</code> parameter is <code>true</code>,
		 *  for all descendants of this component as well.
		 *
		 *  <p>The Flex framework calls this method in the following
		 *  situations:</p>
		 *
		 *  <ul>
		 *    <li>When you add a UIComponent to a parent using the
		 *    <code>addChild()</code> or <code>addChildAt()</code> methods.</li>
		 *    <li>When you change the <code>styleName</code> property
		 *    of a UIComponent.</li>
		 *    <li>When you set a style in a CSS selector using the
		 *    <code>setStyle()</code> method of CSSStyleDeclaration.</li>
		 *  </ul>
		 *
		 *  <p>Building the style cache is a computation-intensive operation,
		 *  so avoid changing <code>styleName</code> or
		 *  setting selector styles unnecessarily.</p>
		 *
		 *  <p>This method is not called when you set an instance style
		 *  by calling the <code>setStyle()</code> method of UIComponent.
		 *  Setting an instance style is a relatively fast operation
		 *  compared with setting a selector style.</p>
		 *
		 *  <p>You do not need to call or override this method.</p>
		 *
		 *  @param recursive Recursively regenerates the style cache for
		 *  all children of this component.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function regenerateStyleCache(recursive:Boolean):void
		{
			// Regenerate the proto chain for this object
			initProtoChain();
			
			var childList:IChildList =
				uiComponent is IRawChildrenContainer ?
				IRawChildrenContainer(uiComponent).rawChildren :
				IChildList(uiComponent);
			
			// Recursively call this method on each child.
			var n:int = childList.numChildren;
			
			for (var i:int = 0; i < n; i++)
			{
				var child:Object = childList.getChildAt(i);
				
				if (child is IStyleClient)
				{
					// Does this object already have a proto chain?
					// If not, there's no need to regenerate a new one.
					if (IStyleClient(child).inheritingStyles !=
						StyleProtoChain.STYLE_UNINITIALIZED)
					{
						IStyleClient(child).regenerateStyleCache(recursive);
					}
				}
				else if (child is IUITextField)
				{
					// Does this object already have a proto chain?
					// If not, there's no need to regenerate a new one.
					if (IUITextField(child).inheritingStyles)
						StyleProtoChain.initTextField(IUITextField(child));
				}
			}
			
			// Call this method on each non-visual StyleClient
			if (advanceStyleClientChildren != null)
			{
				for (var styleClient:Object in advanceStyleClientChildren)
				{
					var iAdvanceStyleClientChild:IAdvancedStyleClient = styleClient
						as IAdvancedStyleClient;
					
					if (iAdvanceStyleClientChild &&
						iAdvanceStyleClientChild.inheritingStyles !=
						StyleProtoChain.STYLE_UNINITIALIZED)
					{
						iAdvanceStyleClientChild.regenerateStyleCache(recursive);
					}
				}
			}
		}
		/**
		 *  This method is called when a state changes to check whether
		 *  state-specific styles apply to this component. If there is a chance
		 *  of a matching CSS pseudo-selector for the current state, the style
		 *  cache needs to be regenerated for this instance and, potentially all
		 *  children, if the <code>recursive</code> param is set to <code>true</code>.
		 *
		 *  @param oldState The name of th eold state.
		 *
		 *  @param newState The name of the new state.
		 *
		 *  @param recursive Set to <code>true</code> to perform a recursive check.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion Flex 4
		 */
		protected function stateChanged(oldState:String, newState:String, recursive:Boolean):void
		{
			// This test only checks for pseudo conditions on the subject of the selector.
			// Pseudo conditions on ancestor selectors are not detected - eg:
			//    List ScrollBar:inactive #track
			// The track styles will not change when the scrollbar is in the inactive state.
			if (currentCSSState && oldState != newState &&
				(styleManager.hasPseudoCondition(oldState) ||
					styleManager.hasPseudoCondition(newState)))
			{
				regenerateStyleCache(recursive);
				initThemeColor();
				styleChanged(null);
				notifyStyleChangeInChildren(null, recursive);
			}
		}
		
		mx_internal function stateChanged(oldState:String, newState:String, recursive:Boolean):void
		{
			protected::stateChanged(oldState, newState, recursive);
		}
		
		[Bindable(style="true")]
		/**
		 *  Gets a style property that has been set anywhere in this
		 *  component's style lookup chain.
		 *
		 *  <p>This same method is used to get any kind of style property,
		 *  so the value returned can be a Boolean, String, Number, int,
		 *  uint (for an RGB color), Class (for a skin), or any kind of object.
		 *  Therefore the return type is simply specified as ~~.</p>
		 *
		 *  <p>If you are getting a particular style property, you
		 *  know its type and often want to store the result in a
		 *  variable of that type.
		 *  No casting from ~~ to that type is necessary.</p>
		 *
		 *  <p>
		 *  <code>
		 *  var backgroundColor:uint = getStyle("backgroundColor");
		 *  </code>
		 *  </p>
		 *
		 *  <p>If the style property has not been set anywhere in the
		 *  style lookup chain, the value returned by <code>getStyle()</code>
		 *  is <code>undefined</code>.
		 *  Note that <code>undefined</code> is a special value that is
		 *  not the same as <code>false</code>, <code>""</code>,
		 *  <code>NaN</code>, <code>0</code>, or <code>null</code>.
		 *  No valid style value is ever <code>undefined</code>.
		 *  You can use the method
		 *  <code>IStyleManager2.isValidStyleValue()</code>
		 *  to test whether the value was set.</p>
		 *
		 *  @param styleProp Name of the style property.
		 *
		 *  @return Style value.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function getStyle(styleProp:String):*
		{
			// If a moduleFactory has not be set yet, first check for any deferred
			// styles. If there are no deferred styles or the styleProp is not in 
			// the deferred styles, the look in the proto chain.
			if (!uiComponent.moduleFactory)
			{
				if (deferredSetStyles && deferredSetStyles[styleProp] !== undefined)
					return deferredSetStyles[styleProp];
			}
			
			return (styleManager.inheritingStyles[styleProp] && _inheritingStyles[styleProp]) ?
				_inheritingStyles[styleProp] :
				_nonInheritingStyles[styleProp];
		}
		
		/**
		 *  Sets a style property on this component instance.
		 *
		 *  <p>This can override a style that was set globally.</p>
		 *
		 *  <p>Calling the <code>setStyle()</code> method can result in decreased performance.
		 *  Use it only when necessary.</p>
		 *
		 *  @param styleProp Name of the style property.
		 *
		 *  @param newValue New value for the style.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function setStyle(styleProp:String, newValue:*):void
		{
			// If there is no module factory then defer the set
			// style until a module factory is set.
			if (uiComponent.moduleFactory)
			{
				StyleProtoChain.setStyle(uiComponent, styleProp, newValue);
			}
			else
			{
				if (!deferredSetStyles)
					deferredSetStyles = new Object();
				deferredSetStyles[styleProp] = newValue;
			}
		}
		
		
		/**
		 *  @private
		 *  Set styles that were deferred because a module factory was not
		 *  set yet.
		 */
		mx_internal function setDeferredStyles():void
		{
			if (!deferredSetStyles)
				return;
			
			for (var styleProp:String in deferredSetStyles)
				StyleProtoChain.setStyle(this, styleProp, deferredSetStyles[styleProp]);
			
			deferredSetStyles = null;
		}
		
		/**
		 *  Deletes a style property from this component instance.
		 *
		 *  <p>This does not necessarily cause the <code>getStyle()</code> method
		 *  to return <code>undefined</code>.</p>
		 *
		 *  @param styleProp The name of the style property.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function clearStyle(styleProp:String):void
		{
			setStyle(styleProp, undefined);
		}
		
		/**
		 *  @private
		 */
		mx_internal var advanceStyleClientChildren:Dictionary = null;
		
		/**
		 *  Adds a non-visual style client to this component instance. Once
		 *  this method has been called, the style client will inherit style
		 *  changes from this component instance. Style clients that are
		 *  DisplayObjects must use the <code>addChild</code> or
		 *  <code>addChildAt</code> methods to be added to a
		 *  <code>UIComponent</code>.
		 *
		 *  As a side effect, this method will set the <code>styleParent</code>
		 *  property of the <code>styleClient</code> parameter to reference
		 *  this instance of the <code>UIComponent</code>.
		 *
		 *  If the <code>styleClient</code> parameter already has a
		 *  <code>styleParent</code>, this method will call
		 *  <code>removeStyleClient</code> from this previous
		 *  <code>styleParent</code>.
		 *
		 *
		 *  @param styleClient The <code>IAdvancedStyleClient</code> to
		 *  add to this component's list of non-visual style clients.
		 *
		 *  @throws ArgumentError if the <code>styleClient</code> parameter
		 *  is a <code>DisplayObject</code>.
		 *
		 *  @see removeStyleClient
		 *  @see mx.styles.IAdvancedStyleClient
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 4.5
		 */
		public function addStyleClient(styleClient:IAdvancedStyleClient):void
		{
			if(!(styleClient is DisplayObject))
			{
				if(styleClient.styleParent!=null)
				{
					var parentComponent:UIComponent = styleClient.styleParent as UIComponent;
					if (parentComponent)
						parentComponent.removeStyleClient(styleClient);
				}
				// Create a dictionary with weak references to the key
				if (advanceStyleClientChildren == null)
					advanceStyleClientChildren = new Dictionary(true);
				// Add the styleClient as a key in the dictionary. 
				// The value assigned to this key entry is currently not used.
				advanceStyleClientChildren[styleClient] = true;
				styleClient.styleParent=uiComponent;
				
				styleClient.regenerateStyleCache(true);
				
				styleClient.styleChanged(null);
			}
			else
			{
				var message:String = resourceManager.getString(
					"core", "badParameter", [ styleClient ]);
				throw new ArgumentError(message);
			}
		}
		
		/**
		 *  Removes a non-visual style client from this component instance.
		 *  Once this method has been called, the non-visual style client will
		 *  no longer inherit style changes from this component instance.
		 *
		 *  As a side effect, this method will set the
		 *  <code>styleParent</code> property of the <code>styleClient</code>
		 *  parameter to <code>null</code>.
		 *
		 *  If the <code>styleClient</code> has not been added to this
		 *  component instance, no action will be taken.
		 *
		 *  @param styleClient The <code>IAdvancedStyleClient</code> to remove
		 *  from this component's list of non-visual style clients.
		 *
		 *  @return The non-visual style client that was passed in as the
		 *  <code>styleClient</code> parameter.
		 *
		 *  @see addStyleClient
		 *  @see mx.styles.IAdvancedStyleClient
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 4.5
		 */
		public function removeStyleClient(styleClient:IAdvancedStyleClient):void
		{
			if(advanceStyleClientChildren &&
				advanceStyleClientChildren[styleClient])
			{
				delete advanceStyleClientChildren[styleClient];
				
				styleClient.styleParent = null;
				
				styleClient.regenerateStyleCache(true);
				
				styleClient.styleChanged(null);
			}
		}
		
		/**
		 *  Propagates style changes to the children.
		 *  You typically never need to call this method.
		 *
		 *  @param styleProp String specifying the name of the style property.
		 *
		 *  @param recursive Recursivly notify all children of this component.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function notifyStyleChangeInChildren(
			styleProp:String, recursive:Boolean):void
		{
			cachedTextFormat = null;
			
			var n:int = uiComponent.numChildren;
			for (var i:int = 0; i < n; i++)
			{
				var child:ISimpleStyleClient = uiComponent.getChildAt(i) as ISimpleStyleClient;
				
				if (child)
				{
					child.styleChanged(styleProp);
					
					// Always recursively call this function because of my
					// descendants might have a styleName property that points
					// to this object.  The recursive flag is respected in
					// Container.notifyStyleChangeInChildren.
					if (child is IStyleClient)
						IStyleClient(child).notifyStyleChangeInChildren(styleProp, recursive);
				}
			}
			
			if (advanceStyleClientChildren != null)
			{
				for (var styleClient:Object in advanceStyleClientChildren)
				{
					var iAdvanceStyleClientChild:IAdvancedStyleClient = styleClient
						as IAdvancedStyleClient;
					
					if (iAdvanceStyleClientChild)
					{
						iAdvanceStyleClientChild.styleChanged(styleProp);
					}
				}
			}
		}
		
		/**
		 *  @private
		 *  If this object has a themeColor style, which is not inherited,
		 *  then set it inline.
		 */
		mx_internal function initThemeColor():Boolean
		{
			if (FlexVersion.compatibilityVersion >= FlexVersion.VERSION_4_0)
				return true;
			
			var styleName:Object /* String or UIComponent */ = _styleName;
			
			var tc:Object;  // Can be number or string
			var rc:Number;
			var sc:Number;
			var i:int;
			
			// First look for locally-declared styles
			if (_styleDeclaration)
			{
				tc = _styleDeclaration.getStyle("themeColor");
				rc = _styleDeclaration.getStyle("rollOverColor");
				sc = _styleDeclaration.getStyle("selectionColor");
			}
			
			if (styleManager.hasAdvancedSelectors())
			{
				// Next look for matching selectors (working backwards, starting
				// with the most specific selector)
				if (tc === null || !styleManager.isValidStyleValue(tc))
				{
					var styleDeclarations:Array = StyleProtoChain.getMatchingStyleDeclarations(uiComponent);
					for (i = styleDeclarations.length - 1; i >= 0; i--)
					{
						var decl:CSSStyleDeclaration = styleDeclarations[i];
						if (decl)
						{
							tc = decl.getStyle("themeColor");
							rc = decl.getStyle("rollOverColor");
							sc = decl.getStyle("selectionColor");
						}
						
						if (tc !== null && styleManager.isValidStyleValue(tc))
							break;
					}
				}
			}
			else
			{
				// Next look for class selectors
				if ((tc === null || !styleManager.isValidStyleValue(tc)) &&
					(styleName && !(styleName is ISimpleStyleClient)))
				{
					var classSelector:Object =
						styleName is String ?
						styleManager.getMergedStyleDeclaration("." + styleName) :
						styleName;
					
					if (classSelector)
					{
						tc = classSelector.getStyle("themeColor");
						rc = classSelector.getStyle("rollOverColor");
						sc = classSelector.getStyle("selectionColor");
					}
				}
				
				// Finally look for type selectors
				if (tc === null || !styleManager.isValidStyleValue(tc))
				{
					var typeSelectors:Array = getClassStyleDeclarations();
					
					for (i = 0; i < typeSelectors.length; i++)
					{
						var typeSelector:CSSStyleDeclaration = typeSelectors[i];
						
						if (typeSelector)
						{
							tc = typeSelector.getStyle("themeColor");
							rc = typeSelector.getStyle("rollOverColor");
							sc = typeSelector.getStyle("selectionColor");
						}
						
						if (tc !== null && styleManager.isValidStyleValue(tc))
							break;
					}
				}
			}
			
			// If we have a themeColor but no rollOverColor or selectionColor, call
			// setThemeColor here which will calculate rollOver/selectionColor based
			// on the themeColor.
			if (tc !== null && styleManager.isValidStyleValue(tc) && isNaN(rc) && isNaN(sc))
			{
				setThemeColor(tc);
				return true;
			}
			
			return (tc !== null && styleManager.isValidStyleValue(tc)) && !isNaN(rc) && !isNaN(sc);
		}
		
		/**
		 *  @private
		 *  Calculate and set new roll over and selection colors based on theme color.
		 */
		mx_internal function setThemeColor(value:Object /* Number or String */):void
		{
			var newValue:Number;
			
			if (newValue is String)
				newValue = parseInt(String(value));
			else
				newValue = Number(value);
			
			if (isNaN(newValue))
				newValue = styleManager.getColorName(value);
			
			var newValueS:Number = ColorUtil.adjustBrightness2(newValue, 50);
			
			var newValueR:Number = ColorUtil.adjustBrightness2(newValue, 70);
			
			setStyle("selectionColor", newValueS);
			setStyle("rollOverColor", newValueR);
		}
		
		/**
		 *  Returns a UITextFormat object corresponding to the text styles
		 *  for this UIComponent.
		 *
		 *  @return UITextFormat object corresponding to the text styles
		 *  for this UIComponent.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function determineTextFormatFromStyles():UITextFormat
		{
			var textFormat:UITextFormat = cachedTextFormat;
			
			if (!textFormat)
			{
				var font:String =
					StringUtil.trimArrayElements(_inheritingStyles.fontFamily, ",");
				textFormat = new UITextFormat(uiComponent.getNonNullSystemManager(), font);
				textFormat.moduleFactory = uiComponent.moduleFactory;
				
				// Not all flex4 textAlign values are valid so convert to a valid one.
				var align:String = _inheritingStyles.textAlign;
				if (align == "start")
					align = TextFormatAlign.LEFT;
				else if (align == "end")
					align = TextFormatAlign.RIGHT;
				textFormat.align = align;
				textFormat.bold = _inheritingStyles.fontWeight == "bold";
				textFormat.color = uiComponent.enabled ?
					_inheritingStyles.color :
					_inheritingStyles.disabledColor;
				textFormat.font = font;
				textFormat.indent = _inheritingStyles.textIndent;
				textFormat.italic = _inheritingStyles.fontStyle == "italic";
				textFormat.kerning = _inheritingStyles.kerning;
				textFormat.leading = _nonInheritingStyles.leading;
				textFormat.leftMargin = _nonInheritingStyles.paddingLeft;
				textFormat.letterSpacing = _inheritingStyles.letterSpacing;
				textFormat.rightMargin = _nonInheritingStyles.paddingRight;
				textFormat.size = _inheritingStyles.fontSize;
				textFormat.underline =
					_nonInheritingStyles.textDecoration == "underline";
				
				textFormat.antiAliasType = _inheritingStyles.fontAntiAliasType;
				textFormat.gridFitType = _inheritingStyles.fontGridFitType;
				textFormat.sharpness = _inheritingStyles.fontSharpness;
				textFormat.thickness = _inheritingStyles.fontThickness;
				
				textFormat.useFTE =
					getTextFieldClassName() == "mx.core::UIFTETextField" ||
					getTextInputClassName() == "mx.controls::MXFTETextInput";
				
				if (textFormat.useFTE)
				{
					textFormat.direction = _inheritingStyles.direction;
					textFormat.locale = _inheritingStyles.locale;
				}
				
				cachedTextFormat = textFormat;
			}
			
			return textFormat;
		}
		
		
		/**
		 *  @private
		 *  Returns either "mx.core::UITextField" or "mx.core::UIFTETextField",
		 *  based on the version number and the textFieldClass style.
		 */
		mx_internal function getTextFieldClassName():String
		{
			var c:Class = getStyle("textFieldClass");
			
			if (!c || FlexVersion.compatibilityVersion < FlexVersion.VERSION_4_0)
				return "mx.core::UITextField";
			
			return getQualifiedClassName(c);
		}
		
		/**
		 *  @private
		 *  Returns either "mx.core::TextInput" or "mx.core::MXFTETextInput",
		 *  based on the version number and the textInputClass style.
		 */
		mx_internal function getTextInputClassName():String
		{
			var c:Class = getStyle("textInputClass");
			
			if (!c || FlexVersion.compatibilityVersion < FlexVersion.VERSION_4_0)
				return "mx.core::TextInput";
			
			return getQualifiedClassName(c);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		public function stylesInitialized():void
		{
			//Implemented in UIComponent for optimization
		}
		
		public function get className():String
		{
			//Implemented in UIComponent for optimization
			return null;
		}
		
		public function registerEffects(effects:Array):void
		{
			//Implemented in UIComponent for optimization
		}
		
		public function styleChanged(styleProp:String):void
		{
			//Implemented in UIComponent for optimization
			uiComponent.styleChanged(styleProp);
		}
	}
}