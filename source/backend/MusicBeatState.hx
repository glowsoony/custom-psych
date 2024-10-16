package backend;

import flixel.FlxState;
import backend.PsychCamera;

class MusicBeatState extends FlxState {
	var curStep:Int = 0;
	var curBeat:Int = 0;
	var curMeasure:Int = 0;

	public var controls(get, never):Controls;
	private function get_controls() {
		return Controls.instance;
	}

	var _psychCameraInitialized:Bool = false;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static function getVariables()
		return getState().variables;

	override function create() {
		Conductor.reset();
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if(!_psychCameraInitialized) initPsychCamera();

		super.create();

		if (!skip) {
			openSubState(new CustomFadeTransition(0.5, true));
		}
		FlxTransitionableState.skipNextTransOut = false;

		Conductor.onStep = stepHit;
		Conductor.onBeat = beatHit;
		Conductor.onMeasure = measureHit;
		Conductor.self.active = false;
	}

	public function initPsychCamera():PsychCamera {
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		//trace('initialized psych camera ' + Sys.cpuTime());
		return camera;
	}

	override function update(elapsed:Float) {
		if (FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;
		
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

		if (FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		if (FlxTransitionableState.skipNextTransIn) FlxG.resetState();
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if(nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.5, false));
		if(nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState {
		return cast (FlxG.state, MusicBeatState);
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

	function stagesFunc(func:BaseStage -> Void)
	{
		for (stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}
}
