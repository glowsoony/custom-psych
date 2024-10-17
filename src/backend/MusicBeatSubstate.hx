package backend;

import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState {
	public function new() super();
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.instance;
}
