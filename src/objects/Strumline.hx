package objects;

class Strumline extends FlxTypedSpriteGroup<StrumNote> {
	public static final keyCount:Int = 4;
	public static final size:Float = 0.7;
	public static var skin:String = Settings.default_data.noteSkin;
	public var player:Int = 0;

	public function new(?x:Float, ?y:Float, ?player:Int = 0, ?skin:String) {
		this.player = player;
		super(x, y);
		regenerate();
		//active = true;
	}

	public function regenerate():Strumline {
		// just in case there's anything stored
		while (members.length != 0) members.pop().destroy();

		//var strum:StrumNote = null;
		for (i in 0...keyCount) {
			var strum:StrumNote = new StrumNote(i);
			add(strum);
			strum.scale.set(size, size);
			strum.updateHitbox();
			strum.x += strum.width * i;
		}

		return this;
	}
}

class StrumNote extends FlxSprite {
	public function new(lane:Int) {
		super();

		active = true;

		// modding by length will cause different behaviour here
		// purple, blue, green, red, if it goes beyond that, it loops back, purple blue green red, and so on.
		final anim:String = Note.directions[lane % Note.directions.length];
		final formattedSkin:String = Settings.default_data.noteSkin.trim().toLowerCase().replace(' ', '-');
		frames = Paths.sparrowAtlas('noteSkins/$formattedSkin');
		animation.addByPrefix('default', 'arrow${anim.toUpperCase()}', 24);
		animation.addByPrefix('pressed', '$anim press', 24, false);
		animation.addByPrefix('notePressed', '$anim confirm', 24, true);
		trace('$anim confirm');

		playAnim('default');
	}

	public function playAnim(name:String, ?forced:Bool = false) {
		animation.play(name, forced);
		centerOffsets();
		centerOrigin();
	}
}