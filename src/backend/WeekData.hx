package backend;

import haxe.Json;
import hxjson5.Json5;

typedef WeekFile = {
	var songs:Array<Track>;
	var characters:Array<String>;
	var background:String;
	var weekBefore:String;
	var name:String;
	var unlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:Array<String>;

	var ?fileName:String;
}

// synonym for "Song" because Song.hx already exists lmao
typedef Track = {
	var name:String;
	var icon:String;
	var color:Int;
	var ?difficulties:Array<String>;
}

class WeekData {
	public static var list:Array<WeekFile> = [];

	public static function createDummyFile():WeekFile {
		return {
			songs: [{
				name: 'Tutorial', 
				icon: 'face', 
				color: 0xFF9271FD
			}],

			characters: ['bf', 'gf', 'bf'],
			background: 'stage',
			weekBefore: 'tutorial',
			name: 'New Week',
			unlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: Difficulty.default_list,

			fileName: ''
		}
	}

	public static function reload() {
		list.resize(0);

		// making it an array for mods later
		final directories:Array<String> = [Paths.get('weeks')];
		for (path in directories) {
			for (week in FileSystem.readDirectory(path)) {
				if (FileSystem.isDirectory(week)) continue;

				var file:WeekFile = getFile('$path/$week');
				file.fileName = week.replace('.json', '');

				list.push(file);
			}
		}
	}

	public static function getFile(path:String):WeekFile {
		var file:WeekFile = createDummyFile();
		if (!FileSystem.exists(path)) return file;
		
		var data = Json5.parse(File.getContent(path));
		for (property in Reflect.fields(data)) {
			if (!Reflect.hasField(file, property)) continue;
			Reflect.setField(file, property, Reflect.field(data, property));
		}

		return file;
	}
}
