package backend;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import flixel.util.FlxStringUtil;

import external.memory.Memory;

class FPSCounter extends Sprite {
	// the background for the counter
	// so that the counter isn't hard to read on bright backgrounds
	public var background:Bitmap;
	public var text:TextField;

	// the rate at which the counter updates in milliseconds
	final pollingRate:Int = 1000;

	final font:String = 'assets/fonts/Nunito-Medium.ttf';

	public static var gcMemoryInBytes(get, never):Float;
	static function get_gcMemoryInBytes():Float {
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#else
		return openfl.system.System.totalMemory;
		#end
	}

	public static var appMemoryInBytes(get, never):Float;
	static function get_appMemoryInBytes():Float return Memory.getCurrentUsage();

	var lastFrameTime:Float;
	var curFrameTime:Float;
	var currentFPS:Int;

	public function new(x:Float, y:Float, size:Int) {
		super();

		addChild(background = new Bitmap(new BitmapData(1, 1, true, 0x99000000)));
		background.x = x - 5;
		background.y = y - 5;

        addChild(text = new TextField());
        text.autoSize = LEFT;
		text.x = x;
		text.y = y;
        text.wordWrap = text.mouseEnabled = text.selectable = false;
        text.defaultTextFormat = new TextFormat(font, size, 0xFFFFFFF, JUSTIFY);
	}

	// thanks rapper for giving me the frametime code
	override function __enterFrame(delta:Float):Void {
		lastFrameTime += delta;
		curFrameTime = 0.02 * delta + (1 - 0.02) * curFrameTime;
		currentFPS = Math.floor(1 / curFrameTime * 1000);

		lastFrameTime -= lastFrameTime > pollingRate ? pollingRate : return;
		updateText();

		background.width = text.width + 10;
		background.height = text.height + 10;
	}

	public dynamic function updateText() {
		final appMemory:String = Util.formatBytes(appMemoryInBytes);
		final gcMemory:String = Util.formatBytes(gcMemoryInBytes);

		// y'all are nerds smh.........................................
		text.text = '$currentFPS FPS\nRAM: APP: $appMemory / GC: $gcMemory';
	}
}