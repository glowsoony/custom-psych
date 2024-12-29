package scripting;

#if (SCRIPTING_ALLOWED && LUA_ALLOWED)
class LuaScript extends LuaBackend implements IScript {
	public function new(dir:String) {
		super(dir, false);
	}
}
#else
class LuaScript {

}
#end