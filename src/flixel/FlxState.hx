package flixel;

import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.FlxSubState;

/**
 * This is the basic game "state" object - e.g. in a simple game you might have a menu state and a play state.
 * It is for all intents and purpose a fancy `FlxGroup`. And really, it's not even that fancy.
 */
@:keepSub // workaround for HaxeFoundation/haxe#3749
class FlxState extends FlxGroup {
	/**
	 * Determines whether or not this state is updated even when it is not the active state.
	 * For example, if you have your game state first, and then you push a menu state on top of it,
	 * if this is set to `true`, the game state would continue to update in the background.
	 * By default this is `true`, so transitions can still update the game without issues.
	 * Set this to `false` in your state if you don't want the game to update on substates at all.
	 */
	public var persistentUpdate:Bool = true;

	/**
	 * Determines whether or not this state is updated even when it is not the active state.
	 * For example, if you have your game state first, and then you push a menu state on top of it,
	 * if this is set to `true`, the game state would continue to be drawn behind the pause state.
	 * By default this is `true`, so background states will continue to be drawn behind the current state.
	 *
	 * If background states are not `visible` when you have a different state on top,
	 * you should set this to `false` for improved performance.
	 */
	public var persistentDraw:Bool = true;

	/**
	 * The natural background color the cameras default to. In `AARRGGBB` format.
	 */
	public var bgColor(get, set):FlxColor;

	@:noCompletion
	function get_bgColor():FlxColor return FlxG.cameras.bgColor;

	@:noCompletion
	function set_bgColor(Value:FlxColor):FlxColor return FlxG.cameras.bgColor = Value;

	public var substate:FlxSubState;
    
	/**
	 * This function is called after the game engine successfully switches states.
	 * Override this function, NOT the constructor, to initialize or set up your game state.
	 * We do NOT recommend initializing any flixel objects or utilizing flixel features in
	 * the constructor, unless you want some crazy unpredictable things to happen!
	 */
	public function create():Void {}

	override public function destroy():Void {
		super.destroy();
		if (substate != null) substate.close();
	}

	@:allow(flixel.FlxGame)
	function tryUpdate(elapsed:Float):Void {
		if (substate == null) {
			update(elapsed);
			return;
		}

		if (persistentUpdate) update(elapsed);
		if (substate.active) substate.update(elapsed);
	}

	override public function draw():Void {
		if (substate == null) {
			super.draw();
			return;
		}

		if (persistentDraw) super.draw();
		if (substate.visible) substate.draw();
	}

	public function resetSubstate() {
		if (substate == null) return;
		substate.destroy();
		substate = null;

		@:privateAccess
		FlxG.inputs.onStateSwitch();
	}

	public function openSubstate(_substate:FlxSubState):FlxSubState {
		if (_substate == null) {
			trace("openSubstate: First argument is null, please check if you're initializing your substate correctly.");
			return null;
		}

		resetSubstate();

		substate = _substate;
		substate.parent = this;

		@:privateAccess
		FlxG.inputs.onStateSwitch();

		substate.create();

		return substate;
	}

	public function closeSubstate() {
		if (substate == null) {
			trace('closeSubstate: There is no substate currently open.');
			return;
		}

		resetSubstate();
	}

	/**
	 * Called from `FlxG.switchState()`. If `false` is returned, the state
	 * switch is cancelled - the default implementation returns `true`.
	 *
	 * Useful for customizing state switches, e.g. for transition effects.
	 */
	public function switchTo(nextState:FlxState):Bool return true;

	/**
	 * This function is called whenever the window size has been changed.
	 *
	 * @param   Width    The new window width
	 * @param   Height   The new window Height
	 */
	public function onResize(Width:Int, Height:Int):Void {}

	/**
	 * This method is called after the game loses focus.
	 * Can be useful for third party libraries, such as tweening engines.
	 */
	public function onFocusLost():Void {}

	/**
	 * This method is called after the game receives focus.
	 * Can be useful for third party libraries, such as tweening engines.
	 */
	public function onFocus():Void {}
}
