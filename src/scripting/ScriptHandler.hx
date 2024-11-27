package scripting;

#if SCRIPTING_ALLOWED
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;

class ScriptHandler {
	public static var list:Array<Script> = [];

	public static function loadFromDir(dir:String, ?subFolders:Bool = false):Void {
		for (file in FileSystem.readDirectory(dir)) {
			final absPath:String = '$dir/$file';
			if (FileSystem.isDirectory(absPath) && subFolders) loadFromDir(absPath, subFolders);
			
			if (!file.endsWith('.hx')) continue;
			loadFile(absPath);
		}
	}

	public static function loadFile(dir:String):Script {
		var script:Script = new Script(dir);

		list.push(script);
		script.execute();
		return script;
	}

	public static function call(func:String, ?args:Array<Dynamic>):Void {
		for (i in 0...list.length) {
			final script:Script = list[i];

			if (script.disposed) {
				if (list.exists(script)) list.remove(script);
				continue;
			}

			script.call(func, args);
		}
	}

	public static function set(variable:String, value:Dynamic):Dynamic {
		for (i in 0...list.length) {
			final script:Script = list[i];

			if (script.disposed) {
				if (list.exists(script)) list.remove(script);
				continue;
			}

			script.set(variable, value);
		}

		return value;
	}

	public static function clear() {
		while (list.length > 0) list.pop().destroy();
	}
}


class Script extends Iris {
	public var disposed:Bool;
	override function destroy():Void {
		super.destroy();
		disposed = true;
	}

	override function call(func:String, ?args:Array<Dynamic>):IrisCall {
		if (!interp.variables.exists(func)) return {funName: func, signature: null, returnValue: null};
		return super.call(func, args ?? []);
	}

	public function new(dir:String) {
		disposed = false;
		super(File.getContent(dir), {name: dir, autoRun: false, autoPreset: true});

		set('closeFile', function() {
			destroy();
			if (!ScriptHandler.list.contains(this)) return;
			ScriptHandler.list.remove(this);
		});

		set('Settings', Settings);
		set('FlxG', FlxG);
		set('Controls', Controls);
		set('Util', Util);
		set('Paths', Paths);
		set('ScriptHandler', ScriptHandler);
	}
}
#else
class ScriptHandler {
	public static var list:Array<Script> = [];

	public static function loadFromDir(_, ?_):Void {}
	public static function loadFile(_):Script return null;

	public static function call(_, ?_):Array<Dynamic> return [];
	public static function set(_, _):Dynamic return null;
	public static function clear():Void {}
}

class Script {
	public function destroy():Void {}
	public function call(_, ?_):Dynamic return null;
	public function new(_) {}
}
#end