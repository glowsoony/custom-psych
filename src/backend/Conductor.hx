package backend;

import flixel.sound.FlxSoundGroup;
import backend.Song;

typedef BPMChange = {
	var beat:Int;
	var time:Float;
	var bpm:Float;
}

class Conductor extends flixel.FlxBasic {
	public static var playing:Bool = false;
	public static var length:Float = 0.0;

	public static var bpm(default, set):Float = 120.0;
	public static var crotchet:Float = (60 / bpm) * 1000;
	public static var stepCrotchet:Float = crotchet * 0.25;
	
	public static var songOffset:Float = 0.0;

	public static var rate(default, set):Float = 1.0;
	public static var volume(default, set):Float = 1.0;

	public static var time:Float = 0.0;
	public static var rawTime:Float = 0.0;
	static var _lastTime:Float = 0.0;
	static var _resyncTimer:Float = 0.0;

	public static var bpmChanges:Array<BPMChange> = [];

	public static var inst(default, set):FlxSound;
	
	@:isVar public static var mainVocals(get, set):FlxSound;
	@:isVar public static var opponentVocals(get, set):FlxSound;
	public static var vocals:FlxSoundGroup;

	public static final vocalResyncDiff:Float = 5;

	public static var step:Int = 0;
	public static var beat:Int = 0;
	public static var measure:Int = 0;
	static var _fStep:Float;
	static var _fBeat:Float;
	static var _fMeasure:Float;

	static var _prevStep:Int = -1;
	static var _prevBeat:Int = -1;
	static var _prevMeasure:Int = -1;

	public static dynamic function onStep(value:Int):Void {}
	public static dynamic function onBeat(value:Int):Void {}
	public static dynamic function onMeasure(value:Int):Void {}

	public function new() {
		super();
		vocals = new FlxSoundGroup(2);
		visible = false;
		reset();
	}

	public static function reset() {
		playing = false;
		time = rawTime = 0.0;
		_fStep = step = 0;
		_fBeat = beat = 0;
		_fMeasure = measure = 0;

		songOffset = 0.0;
		bpmChanges = [];
	}

	override function update(elapsed:Float) {
		if (!playing) return;

		_prevStep = step;
		_prevBeat = beat;
		_prevMeasure = measure;

		syncTime(elapsed);
		syncVocals();
		syncBeats();
	}

	public static dynamic function syncTime(delta:Float):Void {
		if (!playing) return;
		
		final addition:Float = delta * 1000;
		if (inst == null || !inst.playing) {
			time = rawTime += addition * rate;
			return;
		}

		rawTime = inst.time - songOffset;

		if (inst.time == _lastTime) _resyncTimer += addition;
		else _resyncTimer = 0;

		time = rawTime + _resyncTimer;
		_lastTime = inst.time;
	}

	public static dynamic function syncVocals() {
		if (!playing || inst == null || !inst.playing) return;

		final instTime:Float = inst.time;

		for (vocal in vocals.members) {
			if (vocal == null || !vocal.playing || vocal.length < instTime) continue;

			final vocalDT:Float = Math.abs(vocal.time - instTime);
			if (vocalDT <= vocalResyncDiff) continue;
			vocal.time = instTime;
		}
	}

	public static dynamic function syncBeats() {
		var bpmChange:BPMChange = getBPMChangeFromMS(rawTime);
		if (bpmChange.bpm != bpm) bpm = bpmChange.bpm;

		_fBeat = bpmChange.beat + ((rawTime - bpmChange.time) / crotchet);
		_fStep = _fBeat * 4;
		_fMeasure = _fBeat / 4;

		var nextStep:Int = Math.floor(_fStep);
		var nextBeat:Int = Math.floor(_fBeat);
		var nextMeasure:Int = Math.floor(_fMeasure);

		if (step != nextStep) onStep(step = nextStep);
		if (beat != nextBeat) onBeat(beat = nextBeat);
		if (measure != nextMeasure) onMeasure(measure = nextMeasure);
	}

	public static function stop() {
		playing = false;
		inst.stop();
		vocals.stop();
	}

	public static function play() {
		playing = true;
		inst.play();
		vocals.play();
	}

	public static function pause() {
		playing = false;
		inst.pause();
		vocals.pause();
	}

	public static function resume() {
		playing = true;
		inst.resume();
		vocals.resume();
	}

	public static function set_bpm(value:Float):Float {
		crotchet = calculateCrotchet(value);
		stepCrotchet = crotchet * 0.25;

		return bpm = value;
	}

	static function set_inst(value:FlxSound):FlxSound {
		if (inst != null) {
			inst.stop();
			inst.destroy();
			FlxG.sound.list.remove(inst);
			if (value == null) return inst = null;
		}

		value.persist = true;
		value.pitch = rate;
		length = value.length;
		return inst = value;
	}

	static function get_mainVocals():FlxSound {
		return vocals.members[0];
	}

	static function get_opponentVocals():FlxSound {
		return vocals.members[1];
	}

	static function set_mainVocals(value:FlxSound):FlxSound {
		value.pitch = rate;
		return vocals.members[0] = value;
	}

	static function set_opponentVocals(value:FlxSound):FlxSound {
		value.pitch = rate;
		return vocals.members[1] = value;
	}

	static function set_rate(value:Float):Float {
		#if FLX_PITCH
		inst.pitch = value;
		vocals.pitch = value;

		return rate = value;
		#else
		return 1.0;
		#end
	}

	static function set_volume(value:Float):Float {
		inst.volume = value;
		vocals.volume = value;

		return volume = value;
	}

	// helper functions that im just gonna
	// throw at the bottom of here lmao
	inline public static function calculateCrotchet(bpm:Float) {
		return (60 / bpm) * 1000;
	}

	public static function getBPMChangeFromMS(time:Float):BPMChange {
		var lastChange:BPMChange = {
			beat: 0,
			time: 0,
			bpm: bpm
		};

		if (bpmChanges.length == 0) return lastChange;

		for (i in 0...bpmChanges.length) {
			final change:BPMChange = bpmChanges[i];
			if (time >= change.time) lastChange = change;
			else break;
		}

		return lastChange;
	}

	public static function setBPMChanges(song:Chart) {
		bpmChanges = [];

		var curBPM:Float = song.bpm;
		var curBeats:Int = 0;
		var curTime:Float = 0.0;

		for (section in song.notes) {
			if (section.changeBPM && section.bpm != curBPM) {
				curBPM = section.bpm;
				bpmChanges.push({
					beat: curBeats,
					time: curTime,
					bpm: curBPM
				});
			}

			final sectionBeats:Int = getSectionBeats(section);
			curBeats += sectionBeats;
			curTime += calculateCrotchet(curBPM) * sectionBeats;
		}
	}

	inline static function getSectionBeats(section:Section):Int return section?.sectionBeats ?? 4;
}