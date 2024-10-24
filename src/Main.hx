package;

import debug.FPSCounter;


import flixel.input.keyboard.FlxKey;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;

#if linux
import lime.graphics.Image;
#end

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#end

import backend.Highscore;

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

class Main extends Sprite {
	public static var fpsCounter:FPSCounter;

	public static var psychEngineVersion:String = '1.0';
	public static var baseGameVersion:String = '0.3.0';

	public static var initState:Class<FlxState> = TitleState;

	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public function new() {
		super();

		Settings.load();
		addChild(new FlxGame(0, 0, InitState, 60, 60, true, false));

		addChild(fpsCounter = new FPSCounter(10, 3, 0xFFFFFF));
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		fpsCounter.visible = Settings.data.fpsCounter;

		FlxG.sound.volume = Settings.data.volume;

		#if linux
		Lib.current.stage.window.setIcon(Image.fromFile("icon.png"));
		#end
		
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function (_, _) {
		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
			}

			if (FlxG.game != null) resetSpriteCache(FlxG.game);
		});

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end
	}

	inline static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		    sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void {
		var errMsg:String = '${e.error}\n\n';
		var date:String = '${Date.now()}'.replace(":", "'");

		for (stackItem in CallStack.exceptionStack(true)) {
			switch (stackItem) {
				case FilePos(_, file, line, _): errMsg += 'Called from $file:$line\n';
				default: Sys.println(stackItem);
			}
		}

		// if you're modding source
		// please either remove this line, or replace the link to your mod's github repo
		// so that the original repo doesn't get false issues
		errMsg += "\nPlease report this error to the GitHub page: https://github.com/Rudyrue/custom-psych";

		if (!FileSystem.exists("./crash/")) FileSystem.createDirectory("./crash/");

		File.saveContent('./crash/$date.txt', 'errMsg\n');
		Sys.println('\n$errMsg');

		Application.current.window.alert(errMsg, "Error!");
		DiscordClient.shutdown();
		Sys.exit(1);
	}
	#end
}