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
			
			trace('$directory/$dir');
			for (file in FileSystem.readDirectory('$directory/$dir')) {
				final absPath:String = '$dir/$file';
				trace(absPath);
				trace('$directory/$absPath');
				if (FileSystem.isDirectory('$directory/$absPath') && subFolders) {
					loadFromDir('$directory/$absPath', subFolders);
					continue;
				}

				loadFile(absPath);
			}

			trace('');
		}
	}

	public static function loadFile(dir:String):HScript {
		dir = Util.addFileExtension(Paths.get(dir), 'hx');

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
			if (script == null) continue;

			if (script.disposed) {
				if (list.contains(script)) list.remove(script);
				continue;
			}
			script.call(func, args);
		}
	}

	public static function set(variable:String, value:Dynamic):Void {
		for (i in 0...list.length) {
			var script:HScript = list[i];
			if (script == null) continue;

			if (script.disposed) {
				if (list.contains(script)) list.remove(script);
				continue;
			}
			script.set(variable, value);
		}
	}

	public static function clear() {
		while (list.length > 0) list.pop().close();
	}
}