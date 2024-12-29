package scripting;

class LuaScript extends LuaBackend implements IScript {
	public function new(dir:String) {
		super(dir, false);
	}
}