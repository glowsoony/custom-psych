package backend;

import backend.WeekData.WeekFile;

class Difficulty {
	public static final default_list:Array<String> = ['Easy', 'Normal', 'Hard'];
	public static final default_current:String = 'Normal';

	public static var list:Array<String> = default_list;
	public static var current:String = default_current;

	inline public static function format(?name:String):String {
		name ??= current;
		return name.trim().toLowerCase().replace(' ', '-');
	}

	public static function loadFromWeek(week:WeekFile):Array<String> {
		var diffs:Array<String> = week.difficulties;
		if (diffs == null || diffs.length == 0) return default_list;

		var i:Int = diffs.length - 1;
		while (i > 0) {
			var diff:String = diffs[i];
			if (diff == null) {
				--i;
				continue;
			}

			diff = diff.trim();
			if (diff.length < 1) diffs.remove(diff);
			--i;
		}

		if (diffs.length > 0 && diffs[0].length > 0) return diffs;
		return default_list;
	}

	inline public static function reset() {
		list = default_list.copy();
		current = default_current;
	}

	inline public static function copyFrom(diffs:Array<String>) {
		list = diffs.copy();
	}
}