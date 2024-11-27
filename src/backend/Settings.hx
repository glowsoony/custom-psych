package backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

// Add a variable here and it will get automatically saved
@:structInit 
class SaveVariables {
	public var scrollDirection:String = 'Up';
	public var centeredNotes:Bool = false;
	public var opponentNotes:Bool = true;
	public var fpsCounter:Bool = true;
	public var flashingLights:Bool = true;
	public var autoPause:Bool = true;
	public var antialiasing:Bool = true;
	public var noteSkin:String = 'Default';
	public var splashSkin:String = 'Psych';
	public var splashAlpha:Float = 0.6;
	public var lowQuality:Bool = false;
	public var shaders:Bool = true;
	public var cacheOnGPU:Bool = false;
	public var framerate:Int = 60;
	public var camZooms:Bool = true;
	public var transitions:Bool = false;
	public var noteOffset:Int = 0;

	public var fullscreen:Bool = false;
	public var volume:Float = 1;

	public var stageBrightness:Int = 100;

	public var ghostTapping:Bool = true;
	public var timeBarType:String = 'Time Left';
	public var scoreZoom:Bool = true;
	public var resetButton:Bool = true;
	public var healthBarAlpha:Float = 1;
	public var hitsoundVolume:Float = 0;
	public var pauseMusic:String = 'Tea Time';
	public var checkForUpdates:Bool = true;
	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollSpeed' => 1.0,
		'scrollType' => 'Multiplicative', 
		'playbackRate' => 1.0,
		'healthGain' => 1.0,
		'healthLoss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false
	];

	public var comboPosition:Array<Float> = [300, 300];
	public var judgePosition:Array<Float> = [300, 200];
	public var ratingOffset:Float = 0.0;

	public var sickHitWindow:Int = 45;
	public var goodHitWindow:Int = 90;
	public var badHitWindow:Int = 135;
	public var shitHitWindow:Int = 180;

	public var guitarHeroSustains:Bool = true;
	public var discordRPC:Bool = true;
	public var loadingScreen:Bool = true;
	public var language:String = 'en-US';
}

class Settings {
	public static final default_data:SaveVariables = {};
	public static var data:SaveVariables = default_data;

	public static function save() {
		for (key in Reflect.fields(data))
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));

		FlxG.save.flush();
	}

	public static function load() {
		FlxG.save.bind('funkin', Util.getSavePath());

		for (key in Reflect.fields(data))
			if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key))
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));

		if (FlxG.save.data.framerate == null) {
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate * 2, 60, 240));
		}

		if (FlxG.save.data.gameplaySettings != null) {
			final map:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in map) data.gameplaySettings.set(name, value);
		}

		#if DISCORD_ALLOWED DiscordClient.check(); #end
	}

	public static inline function reset() {
		data = default_data;
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic {
		if (!customDefaultValue) defaultValue = default_data.gameplaySettings[name];
		return (data.gameplaySettings.exists(name) ? data.gameplaySettings[name] : defaultValue);
	}
}
