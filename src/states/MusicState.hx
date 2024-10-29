package states;

import flixel.FlxState;
import backend.PsychCamera;

class MusicState extends FlxState {
	var curStep:Int = 0;
	var curBeat:Int = 0;
	var curMeasure:Int = 0;

	var _psychCameraInitialized:Bool = false;

	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;

	override function create() {
		Conductor.reset();
		#if MODS_ALLOWED Mods.updatedOnState = false; #end
		Paths.clearUnusedMemory();

		if (!_psychCameraInitialized) initPsychCamera();

		if (!skipNextTransOut) openSubState(new Transition(0.5, true));
		skipNextTransOut = false;

		Conductor.onStep = stepHit;
		Conductor.onBeat = beatHit;
		Conductor.onMeasure = measureHit;
		Conductor.self.active = false;
	}

	public function initPsychCamera():PsychCamera {
		var camera:PsychCamera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		return camera;
	}

	override function update(elapsed:Float) {
		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		super.update(elapsed);
	}

	public static function switchState(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state) {
			resetState();
			return;
		}

		if (skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		skipNextTransIn = false;
	}

	public static function resetState() {
		if (skipNextTransIn) FlxG.resetState();
		else startTransition();
		skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(?nextState:FlxState) {
		if (nextState == null) nextState = FlxG.state;

		FlxG.state.openSubState(new Transition(0.5, false));
		Transition.finishCallback = function() {
			if (nextState == FlxG.state) FlxG.resetState();
			else FlxG.switchState(nextState);
		}
	}

	public static function getState():MusicState {
		return cast (FlxG.state, MusicState);
	}

	public function stepHit(step:Int):Void {
		curStep = step;
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = step;
			stage.stepHit(step);
		});
	}

	public var stages:Array<BaseStage> = [];
	public function beatHit(beat:Int):Void {
		curBeat = beat;
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = beat;
			stage.beatHit(beat);
		});
	}

	public function measureHit(measure:Int):Void {
		curMeasure = measure;
		stagesFunc(function(stage:BaseStage) {
			stage.curMeasure = measure;
			stage.measureHit(measure);
		});
	}

	function stagesFunc(func:BaseStage -> Void) {
		for (stage in stages) {
			if (stage == null || !stage.exists || !stage.active) continue;
			func(stage);
		}
	}
}
