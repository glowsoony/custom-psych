package objects;

import flixel.graphics.FlxGraphic;

class Countdown extends FunkinSprite {
	public dynamic function onStart():Void {}
	public dynamic function onTick(tick:Int):Void {
		switch (tick) {
			case 4: FlxG.sound.play(Paths.sound('intro3'));
			case 3: FlxG.sound.play(Paths.sound('intro2'));
			case 2: FlxG.sound.play(Paths.sound('intro1'));
			case 1: FlxG.sound.play(Paths.sound('introGo'));
		}
	}
	public dynamic function onFinish():Void {}

	public var ticks:Int = 4;
	public var timer:FlxTimer;
	public var finished:Bool = true;

	public function new(?x:Float, ?y:Float) {
		super(x, y);
		final graphic:FlxGraphic = Paths.image('countdown');
		loadGraphic(graphic, true, graphic.width, Std.int(graphic.height * (1 / ticks)));

		animation.frameIndex = -1; // ????

		alpha = 0;
		active = true;
	}

	public function start():Void {
		if (timer != null) stop();

		finished = false;
		active = true;
		onStart();

		timer = new FlxTimer().start((Conductor.crotchet * 0.001) / Conductor.rate, function(_) {
			onTick(timer.loopsLeft);

			if (timer.loopsLeft > 0) {
				animation.frameIndex++;
				alpha = 1;
			} else {
				finished = true;
				active = false;
				alpha = 0;
				onFinish();
			}
		}, ticks + 1);
	}

	override function update(elapsed:Float):Void {
		if (finished) return;
		alpha -= elapsed / (Conductor.crotchet * 0.001);
	}

	public function stop():Void {
		if (timer == null) return;
		timer.cancel();
	}
}