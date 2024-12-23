package objects;

import backend.animation.PsychAnimationController;
import backend.Judgement;
import objects.Strumline.StrumNote;
import flixel.math.FlxRect;

typedef NoteData = {
	var time:Float;
	var length:Float;
	var type:String;
	var lane:Int;
	var player:Bool;
	var speed:Float;
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSprite {
	// This is needed for the hardcoded note types to appear on the Chart Editor,
	// It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultTypes:Array<String> = [
		'', // Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public var extraData:Map<String, Dynamic> = [];

	public var time(get, never):Float;
	function get_time():Float return rawTime + Settings.data.noteOffset;

	public var rawTime:Float = 0;

	public var lane:Int = 0;
	public var speed:Float = 1.0;
	public var player:Bool = false;
	public var spawned:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var hitTime(get, never):Float;
	function get_hitTime():Float return time - Conductor.rawTime;

	public var canHit:Bool = true;
	public var inHitRange(get, never):Bool;
	function get_inHitRange():Bool {
		return time < (Conductor.rawTime + (Judgement.maxHitWindow * earlyHitMult)) && 
		time > (Conductor.rawTime - (Judgement.maxHitWindow * lateHitMult));
	}

	public var tooLate(get, never):Bool;
	function get_tooLate():Bool {
		return hitTime < -((Judgement.maxHitWindow + 25));
	}

	public var hittable(get, never):Bool;
	function get_hittable():Bool {
		if (animation == null || animation.curAnim == null) return false;

		final notEnd:Bool = animation.curAnim.name != 'holdend';
		final notDestroyed:Bool = exists && alive;
		return notDestroyed && notEnd && inHitRange && canHit && !missed;
	}

	public var lateHitMult:Float = 1;
	public var earlyHitMult:Float = 1;

	// sustain stuff
	public var pieces:Array<Note> = []; 
	public var parent:Note;
	public var distance:Float = 2000;
	public var correctionOffset:FlxPoint = FlxPoint.get(0, 0); // don't touch this one specifically
	public var sustainLength:Float = 0;
	public var isSustain:Bool = false;
	public var missed:Bool = false;
	public var wasHit:Bool = false;

	public var breakOnHit:Bool = false;
	public var ignore:Bool = false;

	public var texture(default, set):String;
	function set_texture(value:String):String {
		reload(value);
		return texture = value;
	}

	public var type(default, set):String;
	function set_type(value:String):String {
		switch (value) {
			case 'Hurt Note':
				texture = 'hurtNote';
				ignore = true;
				breakOnHit = true;
				earlyHitMult = 0.8;
				lateHitMult = 0.8;

			default:
				texture = '';
		}

		return type = value;
	}

	public static var colours:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var directions:Array<String> = ['left', 'down', 'up', 'right'];
	public var multSpeed(default, set):Float = 1;
	public var multAlpha:Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		return multSpeed = value;
	}

	public function resizeByRatio(ratio:Float) { // haha funny twitter shit
		if (!isSustain || animation.curAnim == null || animation.curAnim.name == 'holdend') return;

		scale.y *= ratio;
		updateHitbox();
	}

	public function new(data:NoteData, ?sustainNote:Bool = false, ?prevNote:Note) {
		super();

		animation = new PsychAnimationController(this);
		antialiasing = Settings.data.antialiasing;

		prevNote ??= this;

		this.prevNote = prevNote;
		isSustain = sustainNote;
		this.moves = false;

		this.rawTime = data.time;
		this.lane = data.lane;
		this.player = data.player;
		this.speed = data.speed;
		this.type = data.type;
		this.sustainLength = data.length;

		if (!isSustain && lane < colours.length) { // Doing this 'if' check to fix the warnings on Senpai songs
			animation.play('default');
		}

		if (isSustain) {
			multAlpha = 0.6;
			flipY = Settings.data.scrollDirection == 'Down';

			correctionOffset.x += width * 0.5;
			animation.play('holdend');
			updateHitbox();
			correctionOffset.x -= width * 0.5;

			if (prevNote.isSustain) {
				prevNote.animation.play('hold');

				prevNote.scale.y *= Conductor.stepCrotchet * 0.01 * 1.05;
				prevNote.updateHitbox();
			}
		}

		prevNote.nextNote = this;
	}

	public function reload(?path:String) {
		path ??= '';

		if (path.length == 0) {
			path = PlayState.song != null ? PlayState.song.arrowSkin : '';
		}

		if (!Paths.exists('images/$path.png')) path = Strumline.default_skin;

		var lastScaleY:Float = scale.y;
		
		frames = Paths.sparrowAtlas(path);
		loadAnims();
		if (!isSustain) {
			centerOffsets();
			centerOrigin();
		} else scale.y = lastScaleY;

		updateHitbox();
	}

	public function followStrum(strum:StrumNote, scrollSpeed:Float) {
		distance = (hitTime * 0.45 * ((scrollSpeed * multSpeed) / Conductor.rate));
		distance *= Settings.data.downscroll ? -1 : 1;

		if (copyAngle) angle = strum.angle;
		if (copyAlpha) alpha = strum.alpha * multAlpha;

		if (copyX) x = strum.x + correctionOffset.x;
		if (copyY) {
			y = strum.y + correctionOffset.y + distance;
			if (Settings.data.downscroll && isSustain) {
				y -= height - ((frameWidth * Strumline.size) * 0.5);
			}
		}
	}

	// for clipping sustains
	public function clipToStrum(strum:StrumNote) {
		if (!exists || !alive) return;

		// why would you wanna cliprect normal notes lmao
		if (!isSustain || !canHit) return;
		
		final downscroll:Bool = Settings.data.scrollDirection == 'Down';
		var swagRect:FlxRect = clipRect ?? FlxRect.get(0, 0, frameWidth, frameHeight);
		var center:Float = strum.y + (strum.height * 0.5);
		if (downscroll) {
			if (y + height >= center) {
				swagRect.height = (center - y) / scale.y;
				swagRect.y = frameHeight - swagRect.height;
			}
		} else if (y <= center) {
			swagRect.y = (center - y) / scale.y;
			swagRect.height = frameHeight - swagRect.y;
		}
		clipRect = swagRect;
	}

	function loadAnims() {
		final colour:String = colours[lane];
		if (colour == null) return;

		if (isSustain) {
			animation.addByPrefix('hold', '$colour hold piece');
			animation.addByPrefix('holdend', '$colour hold end');
		} else animation.addByPrefix('default', '${colour}0');

		setGraphicSize(Std.int(width * Strumline.size));
		updateHitbox();
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect {
		clipRect = rect;
		if (frames != null) frame = frames.frames[animation.frameIndex];
		return rect;
	}
}