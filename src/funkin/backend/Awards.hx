package funkin.backend;

#if AWARDS_ALLOWED
import objects.AchievementPopup;
import haxe.Exception;
import haxe.Json;
import flixel.util.FlxSave;

typedef Award = {
	var name:String;
	var description:String;
	var ?hidden:Bool;
	var ?maxScore:Float;
	var ?maxDecimals:Int;

	//handled automatically, ignore these two
	var ?mod:String;
	var ?ID:Int; 
}

enum abstract AchievementOp(String) {
	var GET = 'get';
	var SET = 'set';
	var ADD = 'add';
}

class Awards {
	public static function init() {
		createAchievement('friday_night_play',		{name: "Freaky on a Friday Night", description: "Play on a Friday... Night.", hidden: true});
		createAchievement('week1_nomiss',			{name: "She Calls Me Daddy Too", description: "Beat Week 1 on Hard with no Misses."});
		createAchievement('week2_nomiss',			{name: "No More Tricks", description: "Beat Week 2 on Hard with no Misses."});
		createAchievement('week3_nomiss',			{name: "Call Me The Hitman", description: "Beat Week 3 on Hard with no Misses."});
		createAchievement('week4_nomiss',			{name: "Lady Killer", description: "Beat Week 4 on Hard with no Misses."});
		createAchievement('week5_nomiss',			{name: "Missless Christmas", description: "Beat Week 5 on Hard with no Misses."});
		createAchievement('week6_nomiss',			{name: "Highscore!!", description: "Beat Week 6 on Hard with no Misses."});
		createAchievement('week7_nomiss',			{name: "God Effing Damn It!", description: "Beat Week 7 on Hard with no Misses."});
		createAchievement('weekend1_nomiss',		{name: "Just a Friendly Sparring", description: "Beat Weekend 1 on Hard with no Misses."});
		createAchievement('ur_bad',					{name: "What a Funkin' Disaster!", description: "Complete a Song with a rating lower than 20%."});
		createAchievement('ur_good',				{name: "Perfectionist", description: "Complete a Song with a rating of 100%."});
		createAchievement('roadkill_enthusiast',	{name: "Roadkill Enthusiast", description: "Watch the Henchmen die 50 times.", maxScore: 50, maxDecimals: 0});
		createAchievement('oversinging', 			{name: "Oversinging Much...?", description: "Sing for 10 seconds without going back to Idle."});
		createAchievement('hype',					{name: "Hyperactive", description: "Finish a Song without going back to Idle."});
		createAchievement('two_keys',				{name: "Just the Two of Us", description: "Finish a Song pressing only two keys."});
		createAchievement('toastie',				{name: "Toaster Gamer", description: "Have you tried to run the game on a toaster?"});
		createAchievement('debugger',				{name: "Debugger", description: "Beat the \"Test\" Stage from the Chart Editor.", hidden: true});
		createAchievement('pessy_easter_egg',		{name: "Engine Gal Pal", description: "Teehee, you found me~!", hidden: true});
		
		//dont delete this thing below
		_originalLength = _sortID + 1;
	}

	public static function get(name:String):Award return list[name];
	public static function exists(name:String):Bool return list.exists(name);

	public static var list:Map<String, Award> = [];
	public static var variables:Map<String, Float> = [];
	public static var unlocked:Array<String> = [];

	static var _firstLoad:Bool = true;
	static var _save:FlxSave;

	public static function load():Void {
		if (!_firstLoad) return;

		if (_originalLength < 0) init();

		_save = new FlxSave();
		_save.bind('awards', Util.getSavePath());

		if (_save.data == null) return;

		if (_save.data.unlocked != null)
			unlocked = _save.data.unlocked;

		var savedMap:Map<String, Float> = _save.data.variables;
		if (savedMap != null) {
			for (key => value in savedMap) {
				variables.set(key, value);
			}
		}
		_firstLoad = false;
	}

	public static function save():Void {
		_save.data.unlocked = unlocked;
		_save.data.variables = variables;
	}
	
	public static function getScore(name:String):Float
		return _scoreFunc(name, GET);

	public static function setScore(name:String, value:Float, ?saveIfNotUnlocked:Bool = true):Float
		return _scoreFunc(name, SET, value, saveIfNotUnlocked);

	public static function addScore(name:String, ?value:Float = 1, ?saveIfNotUnlocked:Bool = true):Float
		return _scoreFunc(name, ADD, value, saveIfNotUnlocked);

	static function _scoreFunc(name:String, mode:AchievementOp, ?addOrSet:Float = 1, ?saveIfNotUnlocked:Bool = true):Float {
		if (!variables.exists(name)) variables.set(name, 0);

		if (list.exists(name)) {
			var achievement:Award = list[name];
			if (achievement.maxScore < 1) {
				Sys.println('Achievement has score disabled or is incorrectly configured: $name');
				return 0.0;
			}

			if (unlocked.contains(name)) return achievement.maxScore;

			var val = addOrSet;
			switch mode {
				case GET: return variables[name]; //get
				case ADD: val += variables[name]; //add
				default:
			}

			if (val >= achievement.maxScore) {
				unlock(name);
				val = achievement.maxScore;
			}
			variables.set(name, val);

			save();
			if (saveIfNotUnlocked || val >= achievement.maxScore) _save.flush();
			return val;
		}
		return -1;
	}

	static var _lastUnlock:Int = -999;
	public static function unlock(name:String, autoStartPopup:Bool = true):String {
		if (!list.exists(name)) {
			Sys.println('Achievement "$name" does not exist!');
			return null;
		}

		if (isUnlocked(name)) return null;

		trace('Completed achievement "$name"');
		unlocked.push(name);

		// earrape prevention
		var time:Int = openfl.Lib.getTimer();
		if (Math.abs(time - _lastUnlock) >= 100) { // If last unlocked happened in less than 100 ms (0.1s) ago, then don't play sound
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
			_lastUnlock = time;
		}

		save();
		_save.flush();

		if (autoStartPopup) startPopup(name);
		return name;
	}

	public static function isUnlocked(name:String)
		return unlocked.contains(name);

	@:allow(objects.AchievementPopup)
	private static var _popups:Array<AchievementPopup> = [];

	public static var showingPopups(get, never):Bool;
	public static function get_showingPopups()
		return _popups.length > 0;

	public static function startPopup(achieve:String, endFunc:Void->Void = null) {
		for (popup in _popups) {
			if (popup == null) continue;
			popup.intendedY += 150;
		}

		_popups.push(new AchievementPopup(achieve, endFunc));
	}

	// Map sorting cuz haxe is physically incapable of doing that by itself
	static var _sortID = 0;
	static var _originalLength = -1;
	public static function createAchievement(name:String, data:Award, ?mod:String = null) {
		data.ID = _sortID;
		data.mod = mod;
		list.set(name, data);
		_sortID++;
	}
}
#end