package backend;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput.FlxInputState;
import flixel.util.FlxSave;
import lime.ui.KeyCode;

class Controls {
	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx
	public static final default_keyBinds:Map<String, Array<FlxKey>> = [
		'note_left'		=> [D, LEFT],
		'note_down'		=> [F, DOWN],
		'note_up'		=> [J, UP],
		'note_right'	=> [K, RIGHT],
		
		'ui_up'			=> [W, UP],
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],
		
		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT]
	];

	public static final default_gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_up'		=> [DPAD_UP, Y],
		'note_right'	=> [DPAD_RIGHT, B],
		
		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		
		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START],
		'reset'			=> [BACK]
	];

	public static var keyBinds:Map<String, Array<Int>> = default_keyBinds;
	public static var gamepadBinds:Map<String, Array<Int>> = default_gamepadBinds;

	public static var controllerMode:Bool = false;

	static var _save:FlxSave;

	// general use
	public static function justPressed(name:String, ?allowGamepad:Bool = true):Bool {
		if (!allowGamepad) return keyJustPressed(name);
		return gamepadJustPressed(name) == true || keyJustPressed(name);
	}

	public static function pressed(name:String, ?allowGamepad:Bool = true):Bool {
		if (!allowGamepad) return keyPressed(name);
		return gamepadPressed(name) == true || keyPressed(name);
	}

	public static function released(name:String, ?allowGamepad:Bool = true):Bool {
		if (!allowGamepad) return keyReleased(name);
		return gamepadReleased(name) == true || keyReleased(name);
	}

	// keyboard specific
	public static function keyJustPressed(name:String) {
		return _getKeyStatus(name, JUST_PRESSED);
	}

	public static function keyPressed(name:String) {
		return _getKeyStatus(name, PRESSED);
	}

	public static function keyReleased(name:String) {
		return _getKeyStatus(name, JUST_RELEASED);
	}
	
	// gamepad specific
	public static function gamepadJustPressed(name:String):Bool {
		return _getGamepadStatus(name, JUST_PRESSED);
	}

	public static function gamepadPressed(name:String):Bool {
		return _getGamepadStatus(name, PRESSED);
	}

	public static function gamepadReleased(name:String):Bool {
		return _getGamepadStatus(name, JUST_RELEASED);
	}

	// backend functions to reduce repetitive code
	static function _getKeyStatus(name:String, state:FlxInputState):Bool {
		var binds:Array<FlxKey> = keyBinds[name];
		if (binds == null) {
			trace('Keybind "$name" doesn\'t exist.');
			return false;
		}

		var keyHasState:Bool = false;

		for (key in binds) {
			@:privateAccess
			if (FlxG.keys.getKey(key).hasState(state)) {
				keyHasState = true;
				controllerMode = false;
				break;
			}
		}

		return keyHasState;
	}

	static function _getGamepadStatus(name:String, state:FlxInputState):Bool {
		var binds:Array<FlxGamepadInputID> = gamepadBinds[name];
		if (binds == null) {
			trace('Gamepad bind "$name" doesn\'t exist.');
			return false;
		}

		var buttonHasState:Bool = false;

		for (button in binds) {
			@:privateAccess
			if (FlxG.gamepads.anyHasState(button, state)) {
				buttonHasState = true;
				controllerMode = true;
				break;
			}
		}

		return buttonHasState;
	}

	public static function save() {
		_save.data.keyboard = keyBinds;
		_save.data.gamepad = gamepadBinds;
		_save.flush();
	}

	public static function load() {
		if (_save == null) {
			_save = new FlxSave();
			_save.bind('controls', Util.getSavePath());
		}

		if (_save.data.keyboard != null) {
			var loadedKeys:Map<String, Array<FlxKey>> = _save.data.keyboard;
			for (control => keys in loadedKeys) {
				if (!keyBinds.exists(control)) continue;
				keyBinds.set(control, keys);
			}
		}

		if (_save.data.gamepad != null) {
			var loadedKeys:Map<String, Array<FlxGamepadInputID>> = _save.data.gamepad;
			for (control => keys in loadedKeys) {
				if (!gamepadBinds.exists(control)) continue;
				gamepadBinds.set(control, keys);
			}
		}

		reloadVolumeBinds();
	}

	public static function convertStrumKey(arr:Array<String>, key:FlxKey):Int {
		if (key == NONE) return -1;
		for (i in 0...arr.length) {
			for (possibleKey in keyBinds[arr[i]]) {
				if (key == possibleKey) return i;
			}
		}

		return -1;
	}

	// because openfl inlines it for some reason
    public static function convertLimeKeyCode(code:KeyCode):Int {
        @:privateAccess
        return openfl.ui.Keyboard.__convertKeyCode(code);
    }

	// null = both
	// false = keyboard only
	// true = controller only
	public static function reset(controller:Null<Bool>) {
		if (controller != true) {
			for (key in keyBinds.keys()) {
				if (!default_keyBinds.exists(key)) continue;
				keyBinds.set(key, default_keyBinds.get(key).copy());
			}
		}

		if (controller == false) return;

		for (button in gamepadBinds.keys()) {
			if (!default_gamepadBinds.exists(button)) continue;
			gamepadBinds.set(button, default_gamepadBinds.get(button).copy());
		}
	}

	public static function reloadVolumeBinds() {
		Main.muteKeys = keyBinds.get('volume_mute').copy();
		Main.volumeDownKeys = keyBinds.get('volume_down').copy();
		Main.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}

	public static function toggleVolumeKeys(?enabled:Bool = true) {
		final emptyArray = [];

		FlxG.sound.muteKeys = enabled ? Main.muteKeys : emptyArray;
		FlxG.sound.volumeDownKeys = enabled ? Main.volumeDownKeys : emptyArray;
		FlxG.sound.volumeUpKeys = enabled ? Main.volumeUpKeys : emptyArray;
	}
}