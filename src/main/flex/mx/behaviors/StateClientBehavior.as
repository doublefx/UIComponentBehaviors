package mx.behaviors
{
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	
	import mx.core.EventPriority;
	import mx.core.IStateClient2;
	import mx.core.UIComponent;
	import mx.core.UIComponentGlobals;
	import mx.core.mx_internal;
	import mx.effects.EffectManager;
	import mx.effects.IEffect;
	import mx.effects.IEffectInstance;
	import mx.events.ChildExistenceChangedEvent;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.events.StateChangeEvent;
	import mx.geom.RoundedRectangle;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	import mx.states.State;
	import mx.states.Transition;
	
	use namespace mx_internal;
	
	
	public class StateClientBehavior implements IStateClient2
	{
		private var uiComponent:UIComponent;
		
		/**
		 * @private
		 * These variables cache the transition state from/to information for
		 * the transition currently running. This information is used when
		 * determining what to do with a new transition that interrupts the
		 * running transition.
		 */
		private var transitionFromState:String;
		private var transitionToState:String;
		
		
		
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
		[Bindable("unused")]
		
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
		
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		public function StateClientBehavior(uiComponent:UIComponent)
		{
			this.uiComponent = uiComponent;
		}
		
		//--------------------------------------------------------------------------
		//
		//  Variables: Effects
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  @private
		 *  Sprite used to display an overlay.
		 */
		mx_internal var effectOverlay:UIComponent;
		
		/**
		 *  @private
		 *  Color used for overlay.
		 */
		mx_internal var effectOverlayColor:uint;
		
		/**
		 *  @private
		 *  Counter to keep track of the number of current users
		 *  of the overlay.
		 */
		mx_internal var effectOverlayReferenceCount:int = 0;
		
		//--------------------------------------------------------------------------
		//
		//  Properties: States
		//
		//--------------------------------------------------------------------------
		
		//----------------------------------
		//  currentState
		//----------------------------------
		
		/**
		 *  @private
		 *  Storage for the currentState property.
		 */
		private var _currentState:String;
		
		/**
		 *  @private
		 *  Pending current state name.
		 */
		private var requestedCurrentState:String;
		
		/**
		 *  @private
		 *  Flag to play state transition
		 */
		private var playStateTransition:Boolean = true;
		
		/**
		 *  @private
		 *  Flag that is set when the currentState has changed and needs to be
		 *  committed.
		 *  This property name needs the initial underscore to avoid collisions
		 *  with the "currentStateChange" event attribute.
		 */
		private var _currentStateChanged:Boolean;
		
		[Bindable("currentStateChange")]
		
		/**
		 *  The current view state of the component.
		 *  Set to <code>""</code> or <code>null</code> to reset
		 *  the component back to its base state.
		 *
		 *  <p>When you use this property to set a component's state,
		 *  Flex applies any transition you have defined.
		 *  You can also use the <code>setCurrentState()</code> method to set the
		 *  current state; this method can optionally change states without
		 *  applying a transition.</p>
		 *
		 *  @see #setCurrentState()
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get currentState():String
		{
			return _currentStateChanged ? requestedCurrentState : _currentState;
		}
		
		/**
		 *  @private
		 */
		public function set currentState(value:String):void
		{
			// We have a deferred state change currently queued up, let's override
			// the originally requested state with the newly requested. Otherwise
			// we'll synchronously assign our new state.
			if (_currentStateDeferred != null)
				_currentStateDeferred = value;
			else
				setCurrentState(value, true);
		}
		
		/**
		 *  @private
		 *  Backing variable for currentStateDeferred property
		 */
		private var _currentStateDeferred:String;
		
		/**
		 *  @private
		 *  Version of currentState property that defers setting currentState
		 *  until commitProperties() time. This is used by SetProperty.remove()
		 *  to avoid causing state transitions when currentState is being rolled
		 *  back in a state change operation just to be set immediately after to the
		 *  actual new currentState value. This avoids unnecessary, and sometimes
		 *  incorrect, use of transitions based on this transient state of currentState.
		 */
		mx_internal function get currentStateDeferred():String
		{
			return (_currentStateDeferred != null) ? _currentStateDeferred : currentState;
		}
		
		/**
		 *  @private
		 */
		mx_internal function set currentStateDeferred(value:String):void
		{
			_currentStateDeferred = value;
			if (value != null)
				uiComponent.invalidateProperties();
		}
		
		
		//----------------------------------
		//  states
		//----------------------------------
		
		private var _states:Array /* of State */ = [];
		
		[ArrayElementType("mx.states.State")]
		
		/**
		 *  The view states that are defined for this component.
		 *  You can specify the <code>states</code> property only on the root
		 *  of the application or on the root tag of an MXML component.
		 *  The compiler generates an error if you specify it on any other control.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get states():Array
		{
			return _states;
		}
		
		/**
		 *  @private
		 */
		public function set states(value:Array):void
		{
			_states = value;
		}
		
		//----------------------------------
		//  transitions
		//----------------------------------
		
		/**
		 *  @private
		 *  Transition currently playing.
		 */
		private var _currentTransition:Transition;
		
		private var _transitions:Array /* of Transition */ = [];
		
		[ArrayElementType("mx.states.Transition")]
		
		/**
		 *  An Array of Transition objects, where each Transition object defines a
		 *  set of effects to play when a view state change occurs.
		 *
		 *  @see mx.states.Transition
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get transitions():Array
		{
			return _transitions;
		}
		
		/**
		 *  @private
		 */
		public function set transitions(value:Array):void
		{
			_transitions = value;
		}
		
		//----------------------------------
		//  effectsStarted
		//----------------------------------
		
		/**
		 *  The list of effects that are currently playing on the component,
		 *  as an Array of EffectInstance instances.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function get activeEffects():Array
		{
			return _effectsStarted;
		}
		
		//--------------------------------------------------------------------------
		//
		//  Methods: States
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  Set the current state.
		 *
		 *  @param stateName The name of the new view state.
		 *
		 *  @param playTransition If <code>true</code>, play
		 *  the appropriate transition when the view state changes.
		 *
		 *  @see #currentState
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function setCurrentState(stateName:String,
										playTransition:Boolean = true):void
		{
			// Flex 4 has no concept of an explicit base state, so ensure we
			// fall back to something appropriate.
			stateName = isBaseState(stateName) ? getDefaultState() : stateName;
			
			// Only change if the requested state is different. Since the root
			// state can be either null or "", we need to add additional check
			// to make sure we're not going from null to "" or vice-versa.
			if (stateName != currentState &&
				!(isBaseState(stateName) && isBaseState(currentState)))
			{
				requestedCurrentState = stateName;
				// Don't play transition if we're just getting started
				// In Flex4, there is no "base state", so if isBaseState() is true
				// then we're just going into our first real state
				playStateTransition =
					(this is IStateClient2) && isBaseState(currentState) ?
					false :
					playTransition;
				if (uiComponent.initialized)
				{
					commitCurrentState();
				}
				else
				{
					_currentStateChanged = true;
					uiComponent.invalidateProperties();
				}
			}
		}
		
		/**
		 *  @copy mx.core.IStateClient2#hasState()
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function hasState(stateName:String):Boolean
		{
			return (getState(stateName, false) != null);
		}
		
		/**
		 *  @private
		 *  Returns true if the passed in state name is the 'base' state, which
		 *  is currently defined as null or ""
		 */
		private function isBaseState(stateName:String):Boolean
		{
			return !stateName || stateName == "";
		}
		
		/**
		 *  @private
		 *  Returns the default state. For Flex 4 and later we return the base
		 *  the first defined state, otherwise (Flex 3 and earlier), we return
		 *  the base (null) state.
		 */
		private function getDefaultState():String
		{
			return (this is IStateClient2 && (states.length > 0)) ? states[0].name : null;
		}
		
		mx_internal function commitProperties():void
		{
			// Handle a deferred state change request.
			if (_currentStateDeferred != null)
			{
				var newState:String = _currentStateDeferred;
				_currentStateDeferred = null;
				currentState = newState;
			}
			
			// Typically state changes occur immediately, but during
			// component initialization we defer until commitProperties to 
			// reduce a bit of the startup noise.
			if (_currentStateChanged && !uiComponent.initialized)
			{
				_currentStateChanged = false;
				commitCurrentState();
			}
		}
		
		// Used by commitCurrentState() to avoid hard-linking against Effect
		private static var effectType:Class;
		private static var effectLoaded:Boolean = false;
		
		/**
		 *  @private
		 *  Commit a pending current state change.
		 */
		private function commitCurrentState():void
		{
			var nextTransition:Transition =
				playStateTransition ?
				getTransition(_currentState, requestedCurrentState) :
				null;
			var commonBaseState:String = findCommonBaseState(_currentState, requestedCurrentState);
			var event:StateChangeEvent;
			var oldState:String = _currentState ? _currentState : "";
			var destination:State = getState(requestedCurrentState);
			var prevTransitionEffect:Object;
			var tmpPropertyChanges:Array;
			
			// First, make sure we've loaded the Effect class - some of the logic 
			// below requires it
			if (nextTransition && !effectLoaded)
			{
				effectLoaded = true;
				if (ApplicationDomain.currentDomain.hasDefinition("mx.effects.Effect"))
					effectType = Class(ApplicationDomain.currentDomain.
						getDefinition("mx.effects.Effect"));
			}
			
			// Stop any transition that may still be playing
			var prevTransitionFraction:Number;
			if (_currentTransition)
			{
				// Remove the event listener, we don't want to trigger it as it
				// dispatches FlexEvent.STATE_CHANGE_COMPLETE and we are
				// interrupting _currentTransition instead.
				_currentTransition.effect.removeEventListener(EffectEvent.EFFECT_END, transition_effectEndHandler);
				
				// 'stop' interruptions take precedence over autoReverse behavior
				if (nextTransition && _currentTransition.interruptionBehavior == "stop")
				{
					prevTransitionEffect = _currentTransition.effect;
					prevTransitionEffect.transitionInterruption = true;
					// This logic stops the effect from applying the end values
					// so that we can capture the interrupted values correctly
					// in captureStartValues() below. Save the values in the
					// tmp variable because stop() clears out propertyChangesArray
					// from the effect.
					tmpPropertyChanges = prevTransitionEffect.propertyChangesArray;
					prevTransitionEffect.applyEndValuesWhenDone = false;
					prevTransitionEffect.stop();
					prevTransitionEffect.applyEndValuesWhenDone = true;
				}
				else
				{
					if (_currentTransition.autoReverse &&
						transitionFromState == requestedCurrentState &&
						transitionToState == _currentState)
					{
						if (_currentTransition.effect.duration == 0)
							prevTransitionFraction = 0;
						else
							prevTransitionFraction =
								_currentTransition.effect.playheadTime /
								getTotalDuration(_currentTransition.effect);
					}
					_currentTransition.effect.end();
				}
				
				// The current transition is being interrupted, dispatch an event
				if (hasEventListener(FlexEvent.STATE_CHANGE_INTERRUPTED))
					dispatchEvent(new FlexEvent(FlexEvent.STATE_CHANGE_INTERRUPTED));
				_currentTransition = null;
			}
			
			// Initialize the state we are going to.
			initializeState(requestedCurrentState);
			
			// Capture transition start values
			if (nextTransition)
				nextTransition.effect.captureStartValues();
			
			// Now that we've captured the start values, apply the end values of
			// the effect as normal. This makes sure that objects unaffected by the
			// next transition have their correct end values from the previous
			// transition
			if (tmpPropertyChanges)
				prevTransitionEffect.applyEndValues(tmpPropertyChanges,
					prevTransitionEffect.targets);
			
			// Dispatch currentStateChanging event
			if (hasEventListener(StateChangeEvent.CURRENT_STATE_CHANGING))
			{
				event = new StateChangeEvent(StateChangeEvent.CURRENT_STATE_CHANGING);
				event.oldState = oldState;
				event.newState = requestedCurrentState ? requestedCurrentState : "";
				dispatchEvent(event);
			}
			
			// If we're leaving the base state, send an exitState event
			if (isBaseState(_currentState) && hasEventListener(FlexEvent.EXIT_STATE))
				dispatchEvent(new FlexEvent(FlexEvent.EXIT_STATE));
			
			// Remove the existing state
			removeState(_currentState, commonBaseState);
			_currentState = requestedCurrentState;
			
			// Check for state specific styles
			uiComponent.stateChanged(oldState, _currentState, true);
			
			// If we're going back to the base state, dispatch an
			// enter state event, otherwise apply the state.
			if (isBaseState(currentState))
			{
				if (hasEventListener(FlexEvent.ENTER_STATE))
					dispatchEvent(new FlexEvent(FlexEvent.ENTER_STATE));
			}
			else
				applyState(_currentState, commonBaseState);
			
			// Dispatch currentStateChange
			if (hasEventListener(StateChangeEvent.CURRENT_STATE_CHANGE))
			{
				event = new StateChangeEvent(StateChangeEvent.CURRENT_STATE_CHANGE);
				event.oldState = oldState;
				event.newState = _currentState ? _currentState : "";
				dispatchEvent(event);
			}
			
			if (nextTransition)
			{
				var reverseTransition:Boolean =
					nextTransition && nextTransition.autoReverse &&
					(nextTransition.toState == oldState ||
						nextTransition.fromState == _currentState);
				// Force a validation before playing the transition effect
				UIComponentGlobals.layoutManager.validateNow();
				_currentTransition = nextTransition;
				transitionFromState = oldState;
				transitionToState = _currentState;
				// Tell the effect whether it is running in interruption mode, in which
				// case it should grab values from the states instead of from current
				// property values
				Object(nextTransition.effect).transitionInterruption =
					(prevTransitionEffect != null);
				nextTransition.effect.addEventListener(EffectEvent.EFFECT_END,
					transition_effectEndHandler);
				nextTransition.effect.play(null, reverseTransition);
				if (!isNaN(prevTransitionFraction) &&
					nextTransition.effect.duration != 0)
					nextTransition.effect.playheadTime = (1 - prevTransitionFraction) *
						getTotalDuration(nextTransition.effect);
			}
			else
			{
				// Dispatch an event that the transition has completed.
				if (hasEventListener(FlexEvent.STATE_CHANGE_COMPLETE))
					dispatchEvent(new FlexEvent(FlexEvent.STATE_CHANGE_COMPLETE));
			}
		}
		
		// Used by getTotalDuration() to avoid hard-linking against
		// CompositeEffect
		private static var compositeEffectType:Class;
		private static var compositeEffectLoaded:Boolean = false;
		
		/**
		 * @private
		 * returns the 'total' duration of an effect. This value
		 * takes into account any startDelay and repetition data.
		 * For CompositeEffect objects, it also accounts for the
		 * total duration of that effect's children.
		 */
		private function getTotalDuration(effect:IEffect):Number
		{
			// TODO (chaase): we should add timing properties to some
			// interface to avoid these hacks
			var duration:Number = 0;
			var effectObj:Object = Object(effect);
			if (!compositeEffectLoaded)
			{
				compositeEffectLoaded = true;
				if (ApplicationDomain.currentDomain.hasDefinition("mx.effects.CompositeEffect"))
					compositeEffectType = Class(ApplicationDomain.currentDomain.
						getDefinition("mx.effects.CompositeEffect"));
			}
			if (compositeEffectType && (effect is compositeEffectType))
				duration = effectObj.compositeDuration;
			else
				duration = effect.duration;
			var repeatDelay:int = ("repeatDelay" in effect) ?
				effectObj.repeatDelay : 0;
			var repeatCount:int = ("repeatCount" in effect) ?
				effectObj.repeatCount : 0;
			var startDelay:int = ("startDelay" in effect) ?
				effectObj.startDelay : 0;
			// Now add in startDelay/repeat info
			duration =
				duration * repeatCount +
				(repeatDelay * (repeatCount - 1)) +
				startDelay;
			return duration;
		}
		
		/**
		 *  @private
		 */
		private function transition_effectEndHandler(event:EffectEvent):void
		{
			_currentTransition = null;
			
			// Dispatch an event that the transition has completed.
			if (hasEventListener(FlexEvent.STATE_CHANGE_COMPLETE))
				dispatchEvent(new FlexEvent(FlexEvent.STATE_CHANGE_COMPLETE));
		}
		
		/**
		 *  @private
		 *  Returns the state with the specified name, or null if it doesn't exist.
		 *  If multiple states have the same name the first one will be returned.
		 */
		private function getState(stateName:String, throwOnUndefined:Boolean=true):State
		{
			if (!states || isBaseState(stateName))
				return null;
			
			// Do a simple linear search for now. This can
			// be optimized later if needed.
			for (var i:int = 0; i < states.length; i++)
			{
				if (states[i].name == stateName)
					return states[i];
			}
			
			if (throwOnUndefined)
			{
				var message:String = resourceManager.getString(
					"core", "stateUndefined", [ stateName ]);
				throw new ArgumentError(message);
			}
			return null;
		}
		
		/**
		 *  @private
		 *  Find the deepest common state between two states. For example:
		 *
		 *  State A
		 *  State B basedOn A
		 *  State C basedOn A
		 *
		 *  findCommonBaseState(B, C) returns A
		 *
		 *  If there are no common base states, the root state ("") is returned.
		 */
		private function findCommonBaseState(state1:String, state2:String):String
		{
			var firstState:State = getState(state1);
			var secondState:State = getState(state2);
			
			// Quick exit if either state is the base state
			if (!firstState || !secondState)
				return "";
			
			// Quick exit if both states are not based on other states
			if (isBaseState(firstState.basedOn) && isBaseState(secondState.basedOn))
				return "";
			
			// Get the base states for each state and walk from the top
			// down until we find the deepest common base state.
			var firstBaseStates:Array = getBaseStates(firstState);
			var secondBaseStates:Array = getBaseStates(secondState);
			var commonBase:String = "";
			
			while (firstBaseStates[firstBaseStates.length - 1] ==
				secondBaseStates[secondBaseStates.length - 1])
			{
				commonBase = firstBaseStates.pop();
				secondBaseStates.pop();
				
				if (!firstBaseStates.length || !secondBaseStates.length)
					break;
			}
			
			// Finally, check to see if one of the states is directly based on the other.
			if (firstBaseStates.length &&
				firstBaseStates[firstBaseStates.length - 1] == secondState.name)
			{
				commonBase = secondState.name;
			}
			else if (secondBaseStates.length &&
				secondBaseStates[secondBaseStates.length - 1] == firstState.name)
			{
				commonBase = firstState.name;
			}
			
			return commonBase;
		}
		
		/**
		 *  @private
		 *  Returns the base states for a given state.
		 *  This Array is in high-to-low order - the first entry
		 *  is the immediate basedOn state, the last entry is the topmost
		 *  basedOn state.
		 */
		private function getBaseStates(state:State):Array
		{
			var baseStates:Array = [];
			
			// Push each basedOn name
			while (state && state.basedOn)
			{
				baseStates.push(state.basedOn);
				state = getState(state.basedOn);
			}
			
			return baseStates;
		}
		
		/**
		 *  @private
		 *  Remove the overrides applied by a state, and any
		 *  states it is based on.
		 */
		private function removeState(stateName:String, lastState:String):void
		{
			var state:State = getState(stateName);
			
			if (stateName == lastState)
				return;
			
			// Remove existing state overrides.
			// This must be done in reverse order
			if (state)
			{
				// Dispatch the "exitState" event
				state.dispatchExitState();
				
				var overrides:Array = state.overrides;
				
				for (var i:int = overrides.length; i; i--)
					overrides[i-1].remove(uiComponent);
				
				// Remove any basedOn deltas last
				if (state.basedOn != lastState)
					removeState(state.basedOn, lastState);
			}
		}
		
		/**
		 *  @private
		 *  Apply the overrides from a state, and any states it
		 *  is based on.
		 */
		private function applyState(stateName:String, lastState:String):void
		{
			var state:State = getState(stateName);
			
			if (stateName == lastState)
				return;
			
			if (state)
			{
				// Apply "basedOn" overrides first
				if (state.basedOn != lastState)
					applyState(state.basedOn, lastState);
				
				// Apply new state overrides
				var overrides:Array = state.overrides;
				
				for (var i:int = 0; i < overrides.length; i++)
					overrides[i].apply(uiComponent);
				
				// Dispatch the "enterState" event
				state.dispatchEnterState();
			}
		}
		
		/**
		 *  @private
		 *  Initialize the state, and any states it is based on
		 */
		private function initializeState(stateName:String):void
		{
			var state:State = getState(stateName);
			
			while (state)
			{
				state.initialize();
				state = getState(state.basedOn);
			}
		}
		
		/**
		 *  @private
		 *  Find the appropriate transition to play between two states.
		 */
		private function getTransition(oldState:String, newState:String):Transition
		{
			var result:Transition = null;   // Current candidate
			var priority:int = 0;           // Priority     fromState   toState
			//    1             *           *
			//    2          reverse        *
			//    3             *        reverse
			//    4          reverse     reverse
			//    5           match         *
			//    6             *         match
			//    7           match       match
			
			if (!transitions)
				return null;
			
			if (!oldState)
				oldState = "";
			
			if (!newState)
				newState = "";
			
			for (var i:int = 0; i < transitions.length; i++)
			{
				var t:Transition = transitions[i];
				
				if (t.fromState == "*" && t.toState == "*" && priority < 1)
				{
					result = t;
					priority = 1;
				}
				else if (t.toState == oldState && t.fromState == "*" && t.autoReverse && priority < 2)
				{
					result = t;
					priority = 2;
				}
				else if (t.toState == "*" && t.fromState == newState && t.autoReverse && priority < 3)
				{
					result = t;
					priority = 3;
				}
				else if (t.toState == oldState && t.fromState == newState && t.autoReverse && priority < 4)
				{
					result = t;
					priority = 4;
				}
				else if (t.fromState == oldState && t.toState == "*" && priority < 5)
				{
					result = t;
					priority = 5;
				}
				else if (t.fromState == "*" && t.toState == newState && priority < 6)
				{
					result = t;
					priority = 6;
				}
				else if (t.fromState == oldState && t.toState == newState && priority < 7)
				{
					result = t;
					priority = 7;
					
					// Can't get any higher than this, let's go.
					break;
				}
			}
			// If Transition does not contain an effect, then don't return it
			// because there is no transition effect to run
			if (result && !result.effect)
				result = null;
			
			return result;
		}
		
		
		
		//--------------------------------------------------------------------------
		//
		//  Methods: Effects
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  For each effect event, registers the EffectManager
		 *  as one of the event listeners.
		 *  You typically never need to call this method.
		 *
		 *  @param effects The names of the effect events.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function registerEffects(effects:Array /* of String */):void
		{
			var n:int = effects.length;
			for (var i:int = 0; i < n; i++)
			{
				// Ask the EffectManager for the event associated with this effectTrigger
				var event:String = EffectManager.getEventForEffectTrigger(effects[i]);
				
				if (event != null && event != "")
				{
					addEventListener(event, EffectManager.eventHandler,
						false, EventPriority.EFFECT);
				}
			}
		}
		
		/**
		 *  @private
		 *
		 *  Adds an overlay object that's always on top of our children.
		 *  Calls createOverlay(), which returns the overlay object.
		 *  Currently used by the Dissolve and Resize effects.
		 *
		 *  Returns the overlay object.
		 */
		mx_internal function addOverlay(color:uint,
										targetArea:RoundedRectangle = null):void
		{
			if (!effectOverlay)
			{
				effectOverlayColor = color;
				effectOverlay = new UIComponent();
				effectOverlay.name = "overlay";
				// Have to set visibility immediately
				// to make sure we avoid flicker
				effectOverlay.$visible = true;
				
				fillOverlay(effectOverlay, color, targetArea);
				
				attachOverlay();
				
				if (!targetArea)
					addEventListener(ResizeEvent.RESIZE, overlay_resizeHandler);
				
				effectOverlay.x = 0;
				effectOverlay.y = 0;
				
				uiComponent.invalidateDisplayList();
				
				effectOverlayReferenceCount = 1;
			}
			else
			{
				effectOverlayReferenceCount++;
			}
			
			dispatchEvent(new ChildExistenceChangedEvent(ChildExistenceChangedEvent.OVERLAY_CREATED, true, false, effectOverlay));
		}
		
		/**
		 *  @private
		 *  Fill an overlay object which is always the topmost child.
		 *  Used by the Dissolve effect.
		 *  Never call this function directly.
		 *  It is called internally by addOverlay().
		 *
		 *  The overlay object is filled with a solid rectangle that has the
		 *  same width and height as the component.
		 */
		mx_internal function fillOverlay(overlay:UIComponent, color:uint,
										 targetArea:RoundedRectangle = null):void
		{
			if (!targetArea)
				targetArea = new RoundedRectangle(0, 0, uiComponent.getUnscaledWidth(), uiComponent.getUnscaledHeight(), 0);
			
			var g:Graphics = overlay.graphics;
			g.clear();
			g.beginFill(color);
			
			g.drawRoundRect(targetArea.x, targetArea.y,
				targetArea.width, targetArea.height,
				targetArea.cornerRadius * 2,
				targetArea.cornerRadius * 2);
			g.endFill();
		}
		
		/**
		 *  @private
		 *  Removes the overlay object added by addOverlay().
		 */
		mx_internal function removeOverlay():void
		{
			if (effectOverlayReferenceCount > 0 && --effectOverlayReferenceCount == 0 && effectOverlay)
			{
				removeEventListener(ResizeEvent.RESIZE, overlay_resizeHandler);
				
				if (super.getChildByName("overlay"))
					uiComponent.$removeChild(effectOverlay);
				
				effectOverlay = null;
			}
		}
		/**
		 *  @private
		 *  Resize the overlay when the components size changes
		 *
		 */
		private function overlay_resizeHandler(event:Event):void
		{
			fillOverlay(effectOverlay, effectOverlayColor, null);
		}
		
		/**
		 *  @private
		 */
		mx_internal var _effectsStarted:Array = [];
		
		/**
		 *  @private
		 */
		mx_internal var _affectedProperties:Object = {};
		
		/**
		 *  Contains <code>true</code> if an effect is currently playing on the component.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		private var _isEffectStarted:Boolean = false;
		mx_internal function get isEffectStarted():Boolean
		{
			return _isEffectStarted;
		}
		mx_internal function set isEffectStarted(value:Boolean):void
		{
			_isEffectStarted = value;
		}
		
		private var preventDrawFocus:Boolean = false;
		
		/**
		 *  Called by the effect instance when it starts playing on the component.
		 *  You can use this method to perform a modification to the component as part
		 *  of an effect. You can use the <code>effectFinished()</code> method
		 *  to restore the modification when the effect ends.
		 *
		 *  @param effectInst The effect instance object playing on the component.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function effectStarted(effectInst:IEffectInstance):void
		{
			// Check that the instance isn't already in our list
			_effectsStarted.push(effectInst);
			
			var aProps:Array = effectInst.effect.getAffectedProperties();
			for (var j:int = 0; j < aProps.length; j++)
			{
				var propName:String = aProps[j];
				if (_affectedProperties[propName] == undefined)
				{
					_affectedProperties[propName] = [];
				}
				
				_affectedProperties[propName].push(effectInst);
			}
			
			isEffectStarted = true;
			// Hide the focus ring if the target already has one drawn
			if (effectInst.hideFocusRing)
			{
				preventDrawFocus = true;
				uiComponent.drawFocus(false);
			}
		}
		
		
		private var _endingEffectInstances:Array = [];
		
		/**
		 *  Called by the effect instance when it stops playing on the component.
		 *  You can use this method to restore a modification to the component made
		 *  by the <code>effectStarted()</code> method when the effect started,
		 *  or perform some other action when the effect ends.
		 *
		 *  @param effectInst The effect instance object playing on the component.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function effectFinished(effectInst:IEffectInstance):void
		{
			_endingEffectInstances.push(effectInst);
			uiComponent.invalidateProperties();
			
			// weak reference
			UIComponentGlobals.layoutManager.addEventListener(
				FlexEvent.UPDATE_COMPLETE, updateCompleteHandler, false, 0, true);
		}
		
		/**
		 *  Ends all currently playing effects on the component.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public function endEffectsStarted():void
		{
			var len:int = _effectsStarted.length;
			for (var i:int = 0; i < len; i++)
			{
				_effectsStarted[i].end();
			}
		}
		
		/**
		 *  @private
		 */
		private function updateCompleteHandler(event:FlexEvent):void
		{
			UIComponentGlobals.layoutManager.removeEventListener(
				FlexEvent.UPDATE_COMPLETE, updateCompleteHandler);
			processEffectFinished(_endingEffectInstances);
			_endingEffectInstances = [];
		}
		
		/**
		 *  @private
		 */
		private function processEffectFinished(effectInsts:Array):void
		{
			// Find the instance in our list.
			for (var i:int = _effectsStarted.length - 1; i >= 0; i--)
			{
				for (var j:int = 0; j < effectInsts.length; j++)
				{
					var effectInst:IEffectInstance = effectInsts[j];
					if (effectInst == _effectsStarted[i])
					{
						// Remove the effect from our array.
						var removedInst:IEffectInstance = _effectsStarted[i];
						_effectsStarted.splice(i, 1);
						
						// Remove the affected properties from our internal object
						var aProps:Array = removedInst.effect.getAffectedProperties();
						for (var k:int = 0; k < aProps.length; k++)
						{
							var propName:String = aProps[k];
							if (_affectedProperties[propName] != undefined)
							{
								for (var l:int = 0; l < _affectedProperties[propName].length; l++)
								{
									if (_affectedProperties[propName][l] == effectInst)
									{
										_affectedProperties[propName].splice(l, 1);
										break;
									}
								}
								
								if (_affectedProperties[propName].length == 0)
									delete _affectedProperties[propName];
							}
						}
						break;
					}
				}
			}
			
			isEffectStarted = _effectsStarted.length > 0 ? true : false;
			if (effectInst && effectInst.hideFocusRing)
			{
				preventDrawFocus = false;
			}
		}
		
		/**
		 *  @private
		 */
		mx_internal function getEffectsForProperty(propertyName:String):Array
		{
			return _affectedProperties[propertyName] != undefined ?
				_affectedProperties[propertyName] :
				[];
		}
		
		
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			uiComponent.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			uiComponent.addEventListener(type, listener, useCapture);
		}
		
		public function dispatchEvent(event:Event):Boolean
		{
			return uiComponent.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean
		{
			return uiComponent.hasEventListener(type);
		}
		
		public function willTrigger(type:String):Boolean
		{
			return uiComponent.willTrigger(type);
		}
	}
}