package objects;

import flixel.graphics.FlxGraphic;

class Countdown extends FunkinSprite {
	public dynamic function onStart():Void {}
	public dynamic function onTick(tick:Int):Void {
		switch (tick) {
			case 4: 
				FlxG.sound.play(Paths.sound('intro3'));
				animation.frameIndex = 0;
			case 3: 
				FlxG.sound.play(Paths.sound('intro2'));
				animation.frameIndex = 1;
			case 2: 
				FlxG.sound.play(Paths.sound('intro1'));
				animation.frameIndex = 2;
			case 1: 
				FlxG.sound.play(Paths.sound('introGo'));
				animation.frameIndex = 3;
		}
	}
	public dynamic function onFinish():Void {}

	public var ticks:Int = 4;
	public var finished:Bool = true;

	public function new(?x:Float, ?y:Float) {
		super(x, y);
		final graphic:FlxGraphic = Paths.image('countdown');
		loadGraphic(graphic, true, graphic.width, Std.int(graphic.height * (1 / ticks)));

		animation.frameIndex = -1; // ????

		alpha = 0;
		active = false;
		_lastTick = ticks + 1;
	}

	public function start():Void {
		finished = false;
		active = true;
		_time = (Conductor.crotchet * -(ticks + 1));
		onStart();
	}

	var _lastTick:Int;
	var _time:Float;
	override function update(elapsed:Float):Void {
		if (finished) return;
		alpha -= elapsed / (Conductor.crotchet * 0.001);

		_time += (elapsed * 1000) * Conductor.rate;

		var nextTick:Int = Math.floor(_time / Conductor.calculateCrotchet(Conductor.bpm)) * -1;
		if (nextTick < _lastTick) {
			beat(nextTick);
			_lastTick = nextTick;
		}
	}

	public function beat(curTick:Int) {
		if (curTick > ticks) return;

		onTick(curTick);
		alpha = 1;

		if (curTick <= 0) {
			finished = true;
			active = false;
			alpha = 0;
			onFinish();
		}
	}

	public function stop():Void {
		active = false;
	}
}