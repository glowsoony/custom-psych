package objects;

class Strumline extends FlxTypedSpriteGroup<StrumNote> {
	public static final keyCount:Int = 4;
	public static var size:Float = Settings.data.strumlineSize;
	public var skin(default, set):String;
	public static inline var default_skin:String = 'noteSkins/funkin';
	function set_skin(value:String):String {
		skin = value;
		regenerate();
		return value;
	}
	public var player:Bool;

	public function new(?x:Float, ?y:Float, ?player:Bool = false, ?skin:String) {
		this.moves = false;
		this.player = player;
		super(x, y);
		this.skin = skin ?? Settings.data.noteSkin;

		// center the strumline on the x position we gave it
		// instead of basing the x position on the left side of the x axis
		this.x = x - (width * 0.5);
	}

	public function regenerate() {
		// just in case there's anything stored
		while (members.length != 0) members.pop().destroy();

		var strum:StrumNote = null;
		for (i in 0...keyCount) {
			add(strum = new StrumNote(this, i));
			strum.scale.set(size, size);
			strum.updateHitbox();
			strum.x += strum.width * i;
		}
	}
}

class StrumNote extends FunkinSprite {
	var parent:Strumline;
	public function new(parent:Strumline, lane:Int) {
		super();

		this.parent = parent;

		animation.finishCallback = _ -> {
			active = false;
			
			if (parent.player || animation.curAnim.name != 'notePressed') return;
			playAnim('default');
		}


		// modding by length will cause different behaviour here
		// purple, blue, green, red, if it goes beyond that, it loops back, purple blue green red, and so on.
		final anim:String = Note.directions[lane % Note.directions.length];
		final formattedSkin:String = parent.skin.trim().toLowerCase().replace(' ', '-');
		frames = Paths.sparrowAtlas('noteSkins/$formattedSkin');
		animation.addByPrefix('default', 'arrow${anim.toUpperCase()}', 24);
		animation.addByPrefix('pressed', '$anim press', 48, false);
		animation.addByPrefix('notePressed', '$anim confirm', 48, false);

		playAnim('default');
	}

	override function playAnim(name:String, ?forced:Bool = true) {
		super.playAnim(name, forced);
		centerOffsets();
		centerOrigin();
	}
}