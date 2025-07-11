package funkin.backend;

import sys.thread.Thread;
import lime.app.Application;
import flixel.util.FlxStringUtil;

#if DISCORD_ALLOWED
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

class DiscordClient {
	public static var isInitialized:Bool = false;
	inline static final _defaultID:String = "863222024192262205";
	public static var clientID(default, set):String = _defaultID;
	static var presence:DiscordPresence = new DiscordPresence();
	// hides this field from scripts and reflection in general
	@:unreflective static var __thread:Thread;

	public static function check() {
		if (Settings.data.discordRPC) initialize();
		else if (isInitialized) shutdown();
	}
	
	public static function prepare() {
		if (!isInitialized && Settings.data.discordRPC)
			initialize();

		Application.current.window.onClose.add(function() {
			if (isInitialized) shutdown();
		});
	}

	public dynamic static function shutdown() {
		isInitialized = false;
		Discord.Shutdown();
	}
	
	static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		final user:String = cast (request[0].username, String);
		final discriminator:String = cast (request[0].discriminator, String);

		info('Connected to User $user');
		changePresence();
	}

	static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		error('Error ($errorCode: ${cast(message, String)})');
	}

	static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		info('Disconnected ($errorCode: ${cast(message, String)})');
	}

	public static function initialize() {
		var discordHandlers:DiscordEventHandlers = DiscordEventHandlers.create();
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), 1, null);

		if (!isInitialized) info("Client initialized");

		if (__thread == null) {
			__thread = Thread.create(() -> {
				while (true) {
					if (isInitialized) {
						#if DISCORD_DISABLE_IO_THREAD
						Discord.UpdateConnection();
						#end
						Discord.RunCallbacks();
					}

					// Wait 2 seconds until the next loop...
					Sys.sleep(2.0);
				}
			});
		}
		isInitialized = true;
	}

	public static function changePresence(details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float, largeImageKey:String = 'icon') {
		var startTimestamp:Float = hasStartTimestamp ? Date.now().getTime() : 0;
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.state = state;
		presence.details = details;
		presence.smallImageKey = smallImageKey;
		presence.largeImageKey = largeImageKey;
		presence.largeImageText = 'Version: ${Main.psychEngineVersion}';
		// obtained times are in milliseconds
		// we convert them into seconds so that discord can show them properly
		presence.startTimestamp = Std.int(startTimestamp * 0.001);
		presence.endTimestamp = Std.int(endTimestamp * 0.001);
		updatePresence();
	}

	public static function updatePresence() {
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence.__presence));
	}
	
	inline public static function resetClientID() {
		clientID = _defaultID;
	}

	static function set_clientID(newID:String):String {
		var change:Bool = clientID != newID;
		clientID = newID;

		if (change && isInitialized) {
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
	}
}

@:allow(funkin.backend.DiscordClient)
private final class DiscordPresence {
	public var state(get, set):String;
	public var details(get, set):String;
	public var smallImageKey(get, set):String;
	public var largeImageKey(get, set):String;
	public var largeImageText(get, set):String;
	public var startTimestamp(get, set):Int;
	public var endTimestamp(get, set):Int;

	@:noCompletion private var __presence:DiscordRichPresence;

	function new()
	{
		__presence = DiscordRichPresence.create();
	}

	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("state", state),
			LabelValuePair.weak("details", details),
			LabelValuePair.weak("smallImageKey", smallImageKey),
			LabelValuePair.weak("largeImageKey", largeImageKey),
			LabelValuePair.weak("largeImageText", largeImageText),
			LabelValuePair.weak("startTimestamp", startTimestamp),
			LabelValuePair.weak("endTimestamp", endTimestamp)
		]);
	}

	@:noCompletion inline function get_state():String
	{
		return __presence.state;
	}

	@:noCompletion inline function set_state(value:String):String
	{
		return __presence.state = value;
	}

	@:noCompletion inline function get_details():String
	{
		return __presence.details;
	}

	@:noCompletion inline function set_details(value:String):String
	{
		return __presence.details = value;
	}

	@:noCompletion inline function get_smallImageKey():String
	{
		return __presence.smallImageKey;
	}

	@:noCompletion inline function set_smallImageKey(value:String):String
	{
		return __presence.smallImageKey = value;
	}

	@:noCompletion inline function get_largeImageKey():String
	{
		return __presence.largeImageKey;
	}
	
	@:noCompletion inline function set_largeImageKey(value:String):String
	{
		return __presence.largeImageKey = value;
	}

	@:noCompletion inline function get_largeImageText():String
	{
		return __presence.largeImageText;
	}

	@:noCompletion inline function set_largeImageText(value:String):String
	{
		return __presence.largeImageText = value;
	}

	@:noCompletion inline function get_startTimestamp():Int
	{
		return __presence.startTimestamp;
	}

	@:noCompletion inline function set_startTimestamp(value:Int):Int
	{
		return __presence.startTimestamp = value;
	}

	@:noCompletion inline function get_endTimestamp():Int
	{
		return __presence.endTimestamp;
	}

	@:noCompletion inline function set_endTimestamp(value:Int):Int
	{
		return __presence.endTimestamp = value;
	}
}
#else
class DiscordClient {
	public static var isInitialized:Bool = false;
	inline static final _defaultID:String = "863222024192262205";

	public static var clientID:String = _defaultID;

	static var presence:DiscordPresence = new DiscordPresence();

	public static function check() {}
	public static function prepare() {}
	public dynamic static function shutdown() {}
	public static function initialize() {}
	public static function changePresence(?_, ?_, ?_, ?_, ?_, ?_) {}
	public static function updatePresence() {}
	public static function resetClientID() {}
}

private final class DiscordPresence {
	public var state:String = '';
	public var details:String = '';
	public var smallImageKey:String = '';
	public var largeImageKey:String = '';
	public var largeImageText:String = '';
	public var startTimestamp:Int = 0;
	public var endTimestamp:Int = 0;

	@:noCompletion var __presence:Dynamic;

	public function new() {}
}
#end