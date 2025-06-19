package funkin.huds;

import funkin.objects.Note;
import funkin.objects.Strumline;

class HUD extends FlxSpriteGroup {
	public var botplay(default, set):Bool = false;
	function set_botplay(v:Bool):Bool {
		return botplay = v;
	}

	public var downscroll(default, set):Bool = false;
	function set_downscroll(v:Bool):Bool {
		// override this if you're setting y positions or something
		return downscroll = v;
	}

	public var playerID(default, set):Int;
	function set_playerID(v:Int):Int{
		// same thing as downscroll
		return playerID = v;
	}

	public var paused(default, set):Bool;
	function set_paused(v:Bool):Bool {
		return paused = v;
	}

	var songName:String;
	var difficulty:String;
	var game:PlayState = PlayState.self;
	public var name:String;

	public function new(songName:String, ?difficulty:String) {
		this.songName = songName;
		this.difficulty = difficulty ?? Difficulty.current;
		this.name = 'Unknown';
	
		super();
		active = false;
	}

	public function noteHit(strumline:Strumline, note:Note, judge:Judgement) {}
	public function noteMiss(strumline:Strumline, note:Note) {}
	public function ghostTap(strumline:Strumline) {}
	public function healthChange(value:Float) {}
	public function songStarted() {}
	public function eventTriggered(event:Event) {}

  	public function updateScoreText():Void {}
  	public function updateHealthBar():Void {}
  	public function setHealthColors(one:FlxColor, ?two:FlxColor):Void {
		two ??= one;
	}
  	public function setTimeBarColors(one:FlxColor, ?two:FlxColor):Void {
		two ??= one;
	}
  	public function stepHit(step:Int) {}
  	public function beatHit(beat:Int) {}
}