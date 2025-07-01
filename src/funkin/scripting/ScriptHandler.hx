package funkin.scripting;

class ScriptHandler {
	public static var list:Array<HScript> = [];

	public static function loadFromDir(dir:String, ?subFolders:Bool = false):Void {
		if (!Paths.exists(dir)) return;

		final directories:Array<String> = ['assets'];
		final originalLength:Int = directories.length;
		for (mod in Mods.getActive()) directories.push('mods/${mod.id}');

		for (i => directory in directories) {
			if (!FileSystem.exists(directory) || !FileSystem.exists('$directory/$dir')) continue;
			
			var folder:Array<String> = FileSystem.readDirectory('$directory/$dir') ?? [];
			for (file in folder) {
				final absPath:String = '$directory/$dir/$file';
				if (FileSystem.isDirectory(absPath) && subFolders) {
					loadFromDir(absPath, subFolders);
					continue;
				}

				loadFile(absPath);
			}
		}
	}

	public static function loadFile(dir:String):HScript {
		dir = Util.addFileExtension(dir, 'hx');

		if (!FileSystem.exists(dir) || !dir.endsWith('hx')) return null;
		var script:HScript = new HScript(dir);

		list.push(script);
		script.execute();

		return script;
	}

	public static function call(func:String, ?args:Array<Dynamic>):Void {
		args ??= [];
		for (i in 0...list.length) {
			var script:HScript = list[i];
			if (script == null || !script.active) continue;
	
			script.call(func, args);
		}
	}

	public static function set(variable:String, value:Dynamic):Void {
		for (i in 0...list.length) {
			var script:HScript = list[i];
			if (script == null || !script.active) continue;

			script.set(variable, value);
		}
	}

	public static function clear() {
		while (list.length > 0) list.pop().close();
	}
}