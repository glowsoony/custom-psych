package funkin.backend;

import flixel.util.FlxSave;

@:structInit
class PlayData {
	// song data
	public var songID:String;
	public var difficulty:String;

	// play data
	public var score:Int;
	public var accuracy:Float;

	// modifiers
	public var modifiers:Map<String, Dynamic>;
}

class Scores {
	public static var list:Array<PlayData> = [];
	public static var weekList:Map<String, Int> = [];

	static var _save:FlxSave;

	public static function load():Void {
		_save = new FlxSave();
		_save.bind('scores', Util.getSavePath());

		if (_save.data.list != null) list = _save.data.list.copy();
		if (_save.data.weekList != null) weekList = _save.data.weekList.copy();
	}

	public static function save():Void {
		_save.data.list = list.copy();
		_save.data.weekList = weekList.copy();
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

				modifiers: Settings.default_data.gameplaySettings
			}
		}

		return plays[0];
	}

	public static function set(data:PlayData):Void {
		var filteredList:Array<PlayData> = filter(list, data.songID, data.difficulty);

		info('current modifiers for "${data.songID} - ${data.difficulty}":');
		for (key => value in data.modifiers) Sys.println('$key: $value');
		Sys.println('');

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
			for (m in ['playbackRate', 'noFail', 'randomizedNotes', 'mirroredNotes', 'sustains', 'opponentMode', 'blind']) {
				if (!modifiers.exists(m)) return false;
				if (play.modifiers[m] != modifiers[m]) return false;
			}

			return play.songID == songID && play.difficulty == difficulty;
		});
	}
}