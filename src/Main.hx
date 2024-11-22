package;

import backend.FPSCounter;

import flixel.FlxGame;
import flixel.FlxState;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import states.TitleState;

import external.DefinesMacro;

#if linux
import lime.graphics.Image;
#end

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#end

import flixel.input.keyboard.FlxKey;
import openfl.Lib;
import backend.DiscordClient;

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
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

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if linux
		Lib.current.stage.window.setIcon(Image.fromFile("icon.png"));
		#end

		Settings.load();
		addChild(new FlxGame(0, 0, InitState, 60, 60, true, false));

		addChild(fpsCounter = new FPSCounter(10, 10, 12));
		fpsCounter.visible = Settings.data.fpsCounter;

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		
		if (FlxG.save.data.volume != null) FlxG.sound.volume = FlxG.save.data.volume;

		// shader coords fix
		// by ne_eo
		FlxG.signals.gameResized.add(function (_, _) {
		    if (FlxG.cameras != null) {
				for (cam in FlxG.cameras.list) {
					if (cam == null || cam.filters == null) continue;
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

		errMsg += '\nExtra Info:\n';
		errMsg += 'Operating System: ${Util.getOperatingSystem()}\nTarget: ${Util.getTarget()}\n\n';

		final defines:Map<String, Dynamic> = DefinesMacro.defines;
		errMsg += 'Haxe: ${defines['haxe']}\nFlixel: ${defines['flixel']}\nOpenFL: ${defines['openfl']}\nLime: ${defines['lime']}';

		if (!FileSystem.exists('./crash/')) FileSystem.createDirectory('./crash/');

		File.saveContent('./crash/$date.txt', '$errMsg\n');
		Sys.println('\n$errMsg');

		lime.app.Application.current.window.alert(errMsg, "Error!");
		DiscordClient.shutdown();
		Sys.exit(1);
	}
	#end
}