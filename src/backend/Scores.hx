package backend;

import flixel.util.FlxSave;

@:structInit
class PlayData {
	// song data
	public var songID:String;
	public var difficulty:String;

	// play data
	public var score:Int;
	public var accuracy:Float;
	public var clearType:String;

	// modifiers
	public var playbackRate:Float;
	public var noFail:Bool;
	public var randomizedNotes:Bool;
	public var mirroredNotes:Bool;
	public var sustains:Bool;
}

class Scores {
	public static var list:Array<PlayData> = [];

	static var _save:FlxSave;

	public static function load():Void {
		_save = new FlxSave();
		_save.bind('scores', Util.getSavePath());

		if (_save.data.list != null) list = _save.data.list;
	}

	public static function save():Void {
		_save.data.list = list;
		_save.flush();
	}

	public static function get(songID:String, ?difficulty:String):PlayData {
		difficulty ??= Difficulty.current;

		var plays:Array<PlayData> = filter(list, songID, difficulty);
		if (plays.length == 0) {
			return {
				songID: songID,
				difficulty: difficulty,
				score: 0,
				accuracy: 0.0,
				clearType: 'N/A',

				playbackRate: 1.0,
				noFail: false,
				randomizedNotes: false,
				mirroredNotes: false,
				sustains: true
			}
		}

		return plays[0];
	}

	public static function set(data:PlayData):Void {
		var filteredList:Array<PlayData> = filter(list, data.songID, data.difficulty);

		if (filteredList.length == 0) {
			list.push(data);
			return;
		}

		var oldPlay:PlayData = list[list.indexOf(filteredList[0])];

		if (oldPlay.accuracy < data.accuracy) {
			oldPlay.accuracy = data.accuracy;
		}

		if (oldPlay.score < data.score) {
			oldPlay.score = data.score;
		}
	}

	public static function filter(plays:Array<PlayData>, songID:String, difficulty:String):Array<PlayData> {
		var modifiers:Map<String, Dynamic> = Settings.data.gameplaySettings;

		return plays.filter(function(play:PlayData) {
			for (m in ['playbackRate', 'noFail', 'randomizedNotes', 'mirroredNotes', 'sustains']) {
				if (!modifiers.exists(m)) return false;
				if (Reflect.field(play, m) != modifiers[m]) return false;
			}

			return play.songID == songID && play.difficulty == difficulty;
		});
	}
}