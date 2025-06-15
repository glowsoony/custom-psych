package funkin.backend;

import flixel.system.ui.FlxSoundTray;
import openfl.display.Bitmap;
import openfl.utils.Assets;

// totally didn't steal this from base game ahhahahefahfsdhahhashfahhasfhahahahahahahahashahahahahaa
class FunkinSoundTray extends FlxSoundTray {
	var graphicScale:Float = 0.30;
	var lerpYPos:Float = 0;
	var alphaTarget:Float = 0;

	var volumeMaxSound:String;

	public function new() {
		super();
		removeChildren();

		var bg:Bitmap = new Bitmap(Assets.getBitmapData(Paths.get("images/soundtray/volumebox.png")));
		bg.scaleX = graphicScale;
		bg.scaleY = graphicScale;
		bg.smoothing = true;
		addChild(bg);

		y = -height;
		visible = false;

		// makes an alpha'd version of all the bars (bar_10.png)
		var backingBar:Bitmap = new Bitmap(Assets.getBitmapData(Paths.get("images/soundtray/bars_10.png")));
		backingBar.x = 9;
		backingBar.y = 5;
		backingBar.scaleX = graphicScale;
		backingBar.scaleY = graphicScale;
		backingBar.smoothing = true;
		addChild(backingBar);
		backingBar.alpha = 0.4;

		_bars = [];
		for (i in 1...11) {
			var bar:Bitmap = new Bitmap(Assets.getBitmapData(Paths.get('images/soundtray/bars_$i.png')));
			bar.x = 9;
			bar.y = 5;
			bar.scaleX = graphicScale;
			bar.scaleY = graphicScale;
			bar.smoothing = true;
			addChild(bar);
			_bars.push(bar);
		}

		y = -height;
		screenCenter();

		volumeUpSound = Paths.get("sounds/soundtray/Volup.ogg");
		volumeDownSound = Paths.get("sounds/soundtray/Voldown.ogg");
		volumeMaxSound = Paths.get("sounds/soundtray/VolMAX.ogg");
	}

	override function update(MS:Float):Void {
		y = FlxMath.lerp(y, lerpYPos, 0.1);
		alpha = FlxMath.lerp(alpha, alphaTarget, 0.25);

		var shouldHide:Bool = !FlxG.sound.muted && FlxG.sound.volume > 0;

		// Animate sound tray thing
		if (_timer > 0) {
			if (shouldHide) _timer -= (MS * 0.001);
			alphaTarget = 1;
		} else if (y >= -height) {
			lerpYPos = -height - 10;
			alphaTarget = 0;
		}

		if (y <= -height) {
			visible = false;
			active = false;

			#if FLX_SAVE
			// Save sound preferences
			if (FlxG.save.isBound) {
				FlxG.save.data.mute = FlxG.sound.muted;
				FlxG.save.data.volume = FlxG.sound.volume;
				FlxG.save.flush();
			}
			#end
		}
	}

	override function show(up:Bool = false):Void {
		_timer = 1;
		lerpYPos = 10;
		visible = true;
		active = true;
		var globalVolume:Int = Math.round(FlxG.sound.volume * 10);

		if (FlxG.sound.muted || FlxG.sound.volume == 0) {
			globalVolume = 0;
		}

		if (!silent) {
			var sound:String = up ? volumeUpSound : volumeDownSound;

			if (globalVolume == 10) sound = volumeMaxSound;

			if (sound != null) FlxG.sound.load(sound).play();
		}

		for (i in 0..._bars.length) {
			_bars[i].visible = i < globalVolume;
		}
	}
}
