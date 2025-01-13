package scripting;

#if LUA_ALLOWED
class LuaScript extends LuaBackend implements IScript {
	public function new(dir:String) {
		super(dir, false);
	}
}
#else
class LuaScript extends LuaBackend {

}
#end