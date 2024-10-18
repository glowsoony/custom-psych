package backend;

import flixel.sound.FlxSoundGroup;
import objects.Note;
import backend.Song;

typedef BPMChange = {
	var beat:Int;
	var time:Float;
	var bpm:Float;
}

class Conductor extends flixel.FlxBasic {
	public static var bpm(default, set):Float = 102.0;
	public static var crotchet:Float = (60 / bpm) * 1000;
	public static var stepCrotchet:Float = crotchet * 0.25;
	public static var offset:Float = 0.0;

	public static var safeZoneOffset:Float = 0.0;

	public static var rate(default, set):Float = 1.0;
	public static var volume(default, set):Float = 1.0;

	public static var time:Float = 0.0;
	public static var lastTime:Float = 0.0;

	public static var bpmChanges:Array<BPMChange> = [];

	public static var self:Conductor;

	public static var inst(default, set):FlxSound;
	
	@:isVar public static var mainVocals(get, set):FlxSound;
	@:isVar public static var opponentVocals(get, set):FlxSound;
	public static var vocals:FlxSoundGroup;

	public static final vocalResyncDiff:Float = 5;

	public static var step:Int = 0;
	public static var beat:Int = 0;
	public static var measure:Int = 0;

	public static dynamic function onStep(value:Int) {}
	public static dynamic function onBeat(value:Int) {}
	public static dynamic function onMeasure(value:Int) {}

	public function new() {
		super();
		vocals = new FlxSoundGroup(2);
		self = this;
		visible = false;
	}

	public static function reset() {
		time = 0.0;
		step = 0;
		beat = 0;
		measure = 0;
		bpmChanges = [];
	}

	public static function judgeNote(arr:Array<Rating>, diff:Float=0):Rating // die
	{
		var data:Array<Rating> = arr;
		for(i in 0...data.length-1) //skips last window (Shit)
			if (diff <= data[i].hitWindow)
				return data[i];

		return data[data.length - 1];
	}

	var _resyncTimer:Float = 0.0;
	override function update(elapsed:Float) {
		var oldStep:Int = step;
		var oldBeat:Int = beat;
		var oldMeasure:Int = measure;

		final addition:Float = (elapsed * 1000) * rate;
		if (inst != null && inst.playing) {
			if (inst.time == lastTime) _resyncTimer += addition;
			else _resyncTimer = 0;

			time = (inst.time + _resyncTimer) + offset;
			lastTime = inst.time;
			resyncVocals();
		} else time += addition;

		var bpmChange:BPMChange = getBPMChangeFromMS(time);
		if (bpmChange.bpm != bpm) bpm = bpmChange.bpm;

		var curBeat:Int = bpmChange.beat + Math.floor((time - bpmChange.time) / crotchet);
		var curStep:Int = Math.floor(curBeat * 4);
		var curMeasure:Int = Math.floor(curBeat * 0.25);

		if (oldStep != curStep) onStep(step = curStep);
		if (oldBeat != curBeat) onBeat(beat = curBeat);
		if (oldMeasure != curMeasure) onMeasure(measure = curMeasure);
	}

	public static function resyncVocals() {
		final instTime:Float = inst.time;

		for (vocal in vocals.members) {
			if (vocal == null || !vocal.playing) continue;

			final vocalDT:Float = Math.abs(vocal.time - instTime);
			vocal.time = vocalDT >= vocalResyncDiff ? instTime : vocal.time;
		}
	}

	public static function play() {
		inst.play();
		vocals.play();
		self.active = true;
	}

	public static function stop() {
		inst.stop();
		vocals.stop();
		self.active = false;
	}

	public static function pause() {
		inst.pause();
		vocals.pause();
		self.active = false;
	}

	public static function resume() {
		inst.resume();
		vocals.resume();
		self.active = true;
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
			bpm: bpm,
		};

		if (bpmChanges.length == 0) return lastChange;

		for (i in 0...bpmChanges.length) {
			final change:BPMChange = bpmChanges[i];
			if (time >= change.time) lastChange = change;
			else break;
		}

		return lastChange;
	}

	public static function setBPMChanges(song:SwagSong) {
		bpmChanges = [];

		var curBPM:Float = song.bpm;
		var curBeats:Int = 0;
		var curTime:Float = 0.0;

		for (_ => section in song.notes) {
			if (section.changeBPM && section.bpm != curBPM) {
				curBPM = section.bpm;
				bpmChanges.push({
					beat: curBeats,
					time: curTime,
					bpm: curBPM,
				});
			}

			final sectionBeats:Int = getSectionBeats(section);
			curBeats += sectionBeats;
			curTime += (calculateCrotchet(curBPM)) * sectionBeats;
		}
	}

	inline static function getSectionBeats(section:SwagSection):Int {
		return section?.sectionBeats ?? 4;
	}
}