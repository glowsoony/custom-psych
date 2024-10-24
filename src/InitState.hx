class InitState extends flixel.FlxState {
	override function create() {
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		Controls.load();
		Highscore.load();
		
		Language.reloadPhrases();

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		FlxG.plugins.add(new backend.Conductor());

		FlxG.fullscreen = Settings.data.fullscreen;
		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 10;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.cameras.useBufferLocking = true;

		if (Settings.data.flashingLights) {
			FlxG.switchState(new states.FlashingState());
			return;
		}
		
		FlxG.switchState(Type.createInstance(Main.initState, []));
	}
}