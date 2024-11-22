package objects;

import backend.animation.PsychAnimationController;
import backend.NoteTypesConfig;

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
	public static final defaultNoteTypes:Array<String> = [
		'', // Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public var extraData:Map<String, Dynamic> = [];

	public var time:Float = 0;
	public var lane:Int = 0;
	public var speed:Float = 1.0;
	public var player:Bool = false;
	public var spawned:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var hitTime(get, never):Float;
	function get_hitTime():Float {
		return time - Conductor.time;
	}

	// sustain stuff
	public var tail:Array<Note> = []; 
	public var parent:Note;
	public var correctionOffset:FlxPoint = FlxPoint.get(0, 0); // don't touch this one specifically
	public var sustainLength:Float = 0;
	public var isSustain:Bool = false;

	public static var colours:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var directions:Array<String> = ['left', 'down', 'up', 'right'];
	public var multSpeed(default, set):Float = 1;

	public var offsetX:Float = 0.0;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		return multSpeed = value;
	}

	public function resizeByRatio(ratio:Float) { // haha funny twitter shit
		if (!isSustain || animation.curAnim == null || animation.curAnim.name.endsWith('holdend')) return;

		scale.y *= ratio;
		updateHitbox();
	}

	public function new(data:NoteData, ?prevNote:Note, ?sustainNote:Bool = false) {
		super();

		animation = new PsychAnimationController(this);
		antialiasing = Settings.data.antialiasing;

		prevNote ??= this;

		this.prevNote = prevNote;
		isSustain = sustainNote;
		this.moves = false;

		this.time = data.time;
		this.lane = data.lane;
		this.player = data.player;
		this.speed = data.speed;
		this.sustainLength = data.length;

		reload();
		if (!isSustain && lane < colours.length) { // Doing this 'if' check to fix the warnings on Senpai songs
			animation.play('default');
		}

		if (isSustain) {
			alpha = 0.6;

			correctionOffset.x += width * 0.5;
			flipY = Settings.data.scrollDirection == 'Down';
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

	public function reload() {
		var lastScaleY:Float = scale.y;

		frames = Paths.sparrowAtlas('noteSkins/default');
		loadAnims();
		if (!isSustain) {
			centerOffsets();
			centerOrigin();
		}

		if (isSustain) {
			scale.y = lastScaleY;
		}

		updateHitbox();
	}

	public function followStrum(strum:StrumNote, scrollSpeed:Float) {
		var distance:Float = (hitTime * 0.45 * ((scrollSpeed * multSpeed) / Conductor.rate));
		distance *= Settings.data.scrollDirection == 'Down' ? -1 : 1;

		if (copyAngle) angle = strum.angle;
		if (copyAlpha) alpha = strum.alpha;

		if (copyX) x = strum.x + correctionOffset.x;
		if (copyY) {
			y = strum.y + correctionOffset.y + distance;
			if (Settings.data.scrollDirection == 'Down' && isSustain) {
				y -= (frameHeight * scale.y) - ((frameWidth * Strumline.size) * 0.5);
			}
		}
	}

	public function clipToStrum(strum:StrumNote) {
		// function's for cliprecting sustains
		// why would you wanna cliprect normal notes lmao
		if (!isSustain) return;

		final downscroll:Bool = Settings.data.scrollDirection == 'Down';
		var swagRect:FlxRect = clipRect ?? FlxRect.get(0, 0, frameWidth, frameHeight);
		var center:Float = strum.getGraphicMidpoint().y + offset.y; 

		if (downscroll) {
			if (y * scale.y + height >= center) {
				swagRect.y = frameHeight - swagRect.height;
				swagRect.height = (center - y) / scale.y;
			}
		} else if (y - (height * 0.5) <= center) {
			swagRect.y = (center - y) / scale.y;
			swagRect.height = (height / scale.y) - swagRect.y;
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