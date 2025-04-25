package objects;

import objects.Strumline;

class NoteSplash extends FunkinSprite {
	public var skin(default, set):String;
	public var lane:Int = 0;
	function set_skin(value:String):String {
		reload(value);
		return skin = value;
	}

	public function new(lane:Int, ?skin:String) {
		super();
		this.lane = lane;
		reload(skin);
		alpha = 0.6;

		animation.finishCallback = function(_) {
			visible = false;
		}
	}

	public function reload(?path:String) {
		if (path.length == 0) {
			path = 'noteSplashes/${Util.format(Settings.data.noteSplashSkin)}';
		}

		if (!Paths.exists('images/$path.png')) path = Settings.default_data.noteSplashSkin;

		frames = Paths.sparrowAtlas(path);

		var colour:String = Note.colours[lane];
		animation.addByPrefix('hit1', 'note splash $colour 1', 24, false);
		animation.addByPrefix('hit2', 'note splash $colour 2', 24, false);
		animation.play('hit1');
	
		scale.set(0.7, 0.7);
		updateHitbox();
		offset.set(10, 10);

		visible = false;
	}

	public function hit(strum:StrumNote) {
		visible = true;
		playAnim('hit${FlxG.random.int(1, 2)}');
		updateHitbox();
		setPosition(strum.x + (strum.width - width) * 0.5, strum.y + (strum.height - height) * 0.5);

		animation.curAnim.frameRate = FlxG.random.int(22, 26);
	}
}