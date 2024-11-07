package backend;

import flixel.util.FlxSave;

class Scores {
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, Float> = new Map<String, Float>();

	static var _save:FlxSave;

	public static function resetSong(song:String, ?diff:Int = 0):Void {
		var daSong:String = formatSong(song, diff);
		setScore(daSong, 0);
		setRating(daSong, 0);
	}

	public static function resetWeek(week:String, ?diff:Int = 0):Void {
		var daWeek:String = formatSong(week, diff);
		setWeekScore(daWeek, 0);
	}

	public static function saveScore(song:String, ?score:Int = 0, ?diff:Int = 0, ?rating:Float = -1):Void {
		if (song == null) return;
		var daSong:String = formatSong(song, diff);

		if (songScores.exists(daSong)) {
			if (songScores.get(daSong) < score)	{
				setScore(daSong, score);
				if (rating >= 0) setRating(daSong, rating);
			}
		} else {
			setScore(daSong, score);
			if (rating >= 0) setRating(daSong, rating);
		}
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void {
		var daWeek:String = formatSong(week, diff);

		if (weekScores.exists(daWeek)) {
			if (weekScores.get(daWeek) < score)
				setWeekScore(daWeek, score);
		} else setWeekScore(daWeek, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void {
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	static function setWeekScore(week:String, score:Int):Void {
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setRating(song:String, rating:Float):Void {
		songRating.set(song, rating);
		FlxG.save.data.songRating = songRating;
		FlxG.save.flush();
	}

	public static function formatSong(song:String, diff:Int):String {
		return '';
	}

	public static function getScore(song:String, diff:Int):Int {
		var daSong:String = formatSong(song, diff);
		if (!songScores.exists(daSong))
			setScore(daSong, 0);

		return songScores.get(daSong);
	}

	public static function getRating(song:String, diff:Int):Float {
		var daSong:String = formatSong(song, diff);
		if (!songRating.exists(daSong))
			setRating(daSong, 0);

		return songRating.get(daSong);
	}

	public static function getWeekScore(week:String, diff:Int):Int {
		var daWeek:String = formatSong(week, diff);
		if (!weekScores.exists(daWeek))
			setWeekScore(daWeek, 0);

		return weekScores.get(daWeek);
	}

	public static function load():Void {
		_save = new FlxSave();
		_save.bind('scores', Util.getSavePath());

		if (_save.data.weekScores != null) weekScores = _save.data.weekScores;
		if (_save.data.songScores != null) songScores = _save.data.songScores;
		if (_save.data.songRating != null) songRating = _save.data.songRating;
	}

	public static function save():Void {
		_save.data.weekScores = weekScores;
		_save.data.songScores = songScores;
		_save.data.songRating = songRating;

		_save.flush();
	}
}