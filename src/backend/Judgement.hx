package backend;

import flixel.math.FlxPoint;

@:structInit
class Judgement {
	public static var list:Array<Judgement> = [
		{name: 'sick', timing: Settings.data.sickHitWindow, accuracy: 100, health: 2.5},
		{name: 'good', timing: Settings.data.goodHitWindow, accuracy: 85, health: 1},
		{name: 'bad', timing: Settings.data.badHitWindow, accuracy: 60, health: -2.5},
		{name: 'shit', timing: Settings.data.shitHitWindow, accuracy: 40, health: -4, breakCombo: true}
	];

	public static var maxHitWindow(get, never):Float;
	static function get_maxHitWindow():Float return list[list.length - 1].timing;

	public static var minHitWindow(get, never):Float;
	static function get_minHitWindow():Float return list[0].timing;

	public var name:String;
	public var timing:Float;
	public var accuracy:Float = 0.0;
	public var health:Float = 0.0;
	public var breakCombo:Bool = false;

	public var hits:Int = 0;

	public static function getFromName(name:String):Judgement {
		var value:Judgement = null;
		for (i in 0...list.length) {
			if (list[i].name == name) {
				value = list[i];
				break;
			}
		}

		return value;
	}

	public static function getIDFromName(name:String):Int {
		var value:Int = -1;
		for (i in 0...list.length) {
			if (list[i].name == name) {
				value = i;
				break;
			}
		}

		return value;
	}

	inline public static function resetHits():Void {
		for (judge in list) judge.hits = 0;
	}
}