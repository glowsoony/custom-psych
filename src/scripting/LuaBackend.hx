package scripting;

import llua.Lua.Lua_helper;
import llua.LuaL;
import llua.State;
import llua.Convert;
import llua.Lua;

import Type.ValueType;

using StringTools;

class LuaBackend {
	public var file(default, null):State;
	public var active:Bool = true;
	public var disposed:Bool = false;
	public var path:String;

	public var executed(default, null):Bool = false;

	public function new(dir:String, ?startExecute:Bool = true) {
		this.path = dir;
		this.file = LuaL.newstate();
		LuaL.openlibs(this.file);
		Lua.init_callbacks(this.file);

		if (startExecute) execute();
	}

	public function execute() {
		executed = true;

		var result:Dynamic = LuaL.dofile(file, path);

		var resultStr:String = Lua.tostring(file, result);
		if (resultStr != null && result != 0) {
			Sys.println('Lua parsing error: $resultStr');
			close();
			return;
		}
	}

	public function set(_name:String, value:Dynamic, ?overrideSet:Bool = true):Dynamic {
		if (disposed || !active || this.file == null) return null;

		if (Type.typeof(value) != TFunction) {
			Convert.toLua(file, value);
			Lua.setglobal(file, _name);
		} else Lua_helper.add_callback(file, _name, value);

		return value;
	}

	public function get(variable:String):Dynamic {
		if (!active || file == null) return null;

		Lua.getglobal(file, variable);
		var result:Dynamic = Convert.fromLua(file, -1);
		Lua.pop(file, 1);

		if (result == 'true' || result == 'false') return result == 'true';
		return result;
	}

	public function call(_name:String, ?args:Array<Dynamic>):Dynamic {
		if (!active || file == null) return null;

		args ??= [];

		if (!executed) execute();

		try {
			Lua.getglobal(file, _name);
			var type:Int = Lua.type(file, -1);

			if (type != Lua.LUA_TFUNCTION) {
				if (type > Lua.LUA_TNIL) Sys.println('Lua error ($_name): attempt to call a $type value');

				Lua.pop(file, 1);
				return null;
			}

			for (arg in args) Convert.toLua(file, arg);
			var status:Int = Lua.pcall(file, args.length, 1, 0);

			// Checks if it's not successful, then show a error.
			if (status != Lua.LUA_OK) {
				var error:String = getErrorMessage(status);
				Sys.println('Lua error ($_name): $error');
				return null;
			}

			// If successful, pass and then return the result.
			var result:Dynamic = cast Convert.fromLua(file, -1);

			Lua.pop(file, 1);
			if (!active) close();
			return result;
		} catch (e:Dynamic) Sys.println('Lua error: $e');

		return null;
	}

	public function getErrorMessage(status:Int):String {
		if (!active) return null;

		var v:String = Lua.tostring(file, -1);
		Lua.pop(file, 1);

		if (v != null) v = v.trim();
		if (v == null || v == "") {
			return switch (status) {
				case Lua.LUA_ERRRUN: 'Runtime Error';
				case Lua.LUA_ERRMEM: 'Memory Allocation Error';
				case Lua.LUA_ERRERR: 'Critical Error';
				case _: 'Unknown Error';
			}
		}

		return v;
	}

	public function close() {
		Lua.close(file);
		file = null;
		disposed = true;
	}
}