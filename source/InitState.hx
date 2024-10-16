class InitState extends flixel.FlxState {
	override function create() {
		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		ClientPrefs.loadPrefs();
		Language.reloadPhrases();

		Highscore.load();

		FlxG.cameras.useBufferLocking = true;

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		FlxG.plugins.add(new backend.Conductor());

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 10;
		FlxG.keys.preventDefaultKeys = [TAB];

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		FlxG.switchState(Type.createInstance(Main.game.initialState, []));
	}
}