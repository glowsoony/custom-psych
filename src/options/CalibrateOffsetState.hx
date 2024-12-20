package options;

import lime.ui.KeyCode;
import lime.app.Application;

class CalibrateOffsetState extends MusicState {
	var changingOffset(default, set):Bool = false;
	function set_changingOffset(value:Bool):Bool {
		if (!value) {
			presses.resize(0);
			_lastTime = 0.0;
		}

		return changingOffset = value;
	}

	var presses:Array<Float> = [];
	var isPressed:Bool = false;

	var _lastTime:Float = 0.0;

	var result:FlxText;

	var avgDeviation:Float = 0.0;

	override function create():Void {
		super.create();

		Conductor.inst = FlxG.sound.load(Paths.music('Psync'), 1, true);
		Conductor.bpm = 128;
		Conductor.play();

		add(result = new FlxText(0, 0, 0, '0 ms', 50));
		result.screenCenter();

		Application.current.window.onKeyDown.add(keyPressed);
		Application.current.window.onKeyUp.add(keyReleased);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (Controls.justPressed('back')) {
			MusicState.switchState(new options.OptionsState());
			Conductor.audioOffset = Settings.data.audioOffset = avgDeviation;
			Conductor.inst = FlxG.sound.load(Paths.music('freakyMenu'));
			Conductor.bpm = 102;
			Conductor.inst.play();
		}

		if (FlxG.keys.justPressed.ENTER) changingOffset = !changingOffset;
	}

	override function destroy():Void {
		Application.current.window.onKeyDown.remove(keyPressed);
		Application.current.window.onKeyUp.remove(keyReleased);
	}

	function keyPressed(key:KeyCode, ?_):Void {
		if (!changingOffset || isPressed) return;
		isPressed = true;

		//trace(Conductor.time - (Conductor.time / Conductor.crotchet));

		var offset:Float = Conductor.time % Conductor.crotchet;

		var deviation:Float = Math.min(offset, Conductor.crotchet - offset); // ?

		presses.push(deviation);
		avgDeviation = Util.mean(presses);

		result.text = '$avgDeviation ms';
	}

	function keyReleased(_, ?_):Void {
		if (!changingOffset) return;

		isPressed = false;
	}
}