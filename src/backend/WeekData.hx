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
	var ?folder:String;
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
			difficulties: Difficulty.default_list
		}
	}

	public static function reload() {
		list.resize(0);

		final directories:Array<String> = ['assets'];
		final originalLength:Int = directories.length;
		for (mod in Mods.getActive()) directories.push('mods/${mod.id}');

		for (i => path in directories) {
			if (!FileSystem.exists(path)) continue;
			for (week in FileSystem.readDirectory('$path/weeks')) {
				if (FileSystem.isDirectory(week)) continue;

				var file:WeekFile = getFile('$path/weeks/$week');
				file.fileName = week.replace('.json', '');
				if (i >= originalLength) file.folder = path;

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
