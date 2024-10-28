package objects;

import haxe.Json;
import flixel.math.FlxPoint;
import openfl.utils.Assets;

enum abstract AlphabetAlignment(String) from String to String {
    var LEFT = 'left';
    var CENTER = 'center';
    var RIGHT = 'right';
}

enum abstract AlphabetGlyphType(String) from String to String {
	var BOLD = 'bold';
	var NORMAL = 'normal';
}

// literally just swordcube's alphabet
// but the base is psych's alphabet
// because i need alot of shit from psych's alphabet
// lmfao
class Alphabet extends FlxTypedSpriteGroup<AlphabetRow> {
	public var text(default, set):String;

	public var type:AlphabetGlyphType;

	public var isMenuItem:Bool = false;
	public var targetY:Int = 0;
	public var changeX:Bool = true;
	public var changeY:Bool = true;

	public var scaleX(default, set):Float = 1.0;
	public var scaleY(default, set):Float = 1.0;

	public var alignment(default, set):AlphabetAlignment = LEFT;

	public var letters(get, never):Array<AlphabetGlyph>;

	public var distancePerItem:FlxPoint = new FlxPoint(20, 120);
	public var spawnPos:FlxPoint = new FlxPoint(0, 0);

	public function new(x:Float, y:Float, text:String = "", ?type:AlphabetGlyphType = BOLD, ?alignment:AlphabetAlignment = LEFT) {
		super(x, y);

		this.spawnPos.set(x, y);
		@:bypassAccessor this.alignment = alignment;
		this.type = type;
		this.text = text;
	}

	function set_alignment(align:AlphabetAlignment) {
		updateAlignment(align);
		return alignment = align;
	}

	function get_letters():Array<AlphabetGlyph> {
		var retValue:Array<AlphabetGlyph> = [];
		for (i in 0...members.length) retValue.concat(members[i].members);
		return retValue;
	}

	public static function loadData(?request:String = 'alphabet') {
		var path:String = Paths.getPath('images/$request.json');
		if (!FileSystem.exists(path)) path = Paths.getPath('images/alphabet.json');

		AlphabetGlyph.allGlyphs = new Map<String, Glyph>();
		try {
			var data:Dynamic = Json.parse(File.getContent(path));

			if (data.allowed != null && data.allowed.length > 0) {
				for (i in 0...data.allowed.length) {
					var glyph:String = data.allowed.charAt(i);
					if (glyph == ' ') continue;
					
					// default values for the letters that don't have offsets
					AlphabetGlyph.allGlyphs.set(glyph.toLowerCase(), {
						anim: glyph.toLowerCase(),
						offsets: [0.0, 0.0], 
						offsetsBold: [0.0, 0.0]
					});
				}
			}

			if (data.characters != null) {
				for (char in Reflect.fields(data.characters)) {
					var glyphData = Reflect.field(data.characters, char);
					var glyph:String = char.toLowerCase().substr(0, 1);

					if (AlphabetGlyph.allGlyphs.exists(glyph)) {
						AlphabetGlyph.allGlyphs.set(glyph, {
							anim: glyphData.animation ?? glyph, 
							offsets: glyphData.normal ?? [0.0, 0.0], 
							offsetsBold: glyphData.bold ?? [0.0, 0.0]
						});
					}
				}
			}
			trace('Reloaded members successfully ($path)!');
		} catch(e:Dynamic) trace('Error on loading alphabet data: $e');

		if (!AlphabetGlyph.allGlyphs.exists('?')) {
			AlphabetGlyph.allGlyphs.set('?', {
				anim: 'question',
				offsets: [0.0, 0.0], 
				offsetsBold: [0.0, 0.0]
			});
		}
	}

	// genuinely losing my fucking mind like 
	// why the fuck does center and right alignment not work
	function updateAlignment(align:AlphabetAlignment) {
		final totalWidth:Float = width;

		for (row in members) {
			row.x = switch (align) {
                case LEFT: x;
                case CENTER: x; // ????????????
                case RIGHT: x; // ????????????
			}
		}
	}

	function set_text(newText:String) {
		newText = newText.replace('\\n', '\n');
		updateText(newText);
		updateAlignment(alignment);
		return text = newText;
	}

	public function clearLetters() {
		for (row in members) row.destroy();
		clear();
	}

	public function setScale(newX:Float, ?newY:Float = 0.0) {
		if (newY == 0.0) newY = newX;
		scale.x = newX;
		scale.y = newY;
		@:bypassAccessor scaleX = newX;
		@:bypassAccessor scaleY = newY;

		for (row in members) {
            for (glyph in row) {
                glyph.scale.set(newX, newY);
                glyph.updateHitbox();
                glyph.setPosition(row.x + (glyph.spawnPos.x * newX), row.y + (glyph.spawnPos.y * newY));
            }
        }

        updateAlignment(alignment);
	}

	function set_scaleX(value:Float):Float {
		setScale(value, scaleY);
		return scaleX = value;
	}

	function set_scaleY(value:Float):Float {
		setScale(scaleX, value);
		return scaleY = value;
	}

	override function update(elapsed:Float) {
		if (!isMenuItem) {
			super.update(elapsed);
			return;
		}

		var lerpVal:Float = Math.exp(-elapsed * 9.6);
		if (changeX) x = FlxMath.lerp((targetY * distancePerItem.x) + spawnPos.x, x, lerpVal);
		if (changeY) y = FlxMath.lerp((targetY * 1.3 * distancePerItem.y) + spawnPos.y, y, lerpVal);

		super.update(elapsed);
	}

	public function snapToPosition() {
		if (!isMenuItem) return;

		if (changeX) x = (targetY * distancePerItem.x) + spawnPos.x;
		if (changeY) y = (targetY * 1.3 * distancePerItem.y) + spawnPos.y;
	}

	static var Y_PER_ROW:Float = 60;

	function updateText(newText:String) {
		if (newText == null || text == newText) return;

        clearLetters();

		final glyphPos:FlxPoint = FlxPoint.get();
		var row:AlphabetRow = new AlphabetRow();
		var rows:Int = 0;

		for (i in 0...newText.length) {
			final char:String = newText.charAt(i);

			if (char == '\n') {
				glyphPos.set(0, ++rows * Y_PER_ROW);
                add(row);
                row = new AlphabetRow();
                continue;
			}

            if (char == ' ') {
                glyphPos.x += 28;
                continue;
            }

            if (!AlphabetGlyph.allGlyphs.exists(char.toLowerCase())) continue;

            final glyph:AlphabetGlyph = new AlphabetGlyph().setup(glyphPos.x, glyphPos.y, char, type);
            glyph.row = rows;
            glyph.color = color;
            glyph.spawnPos.copyFrom(glyphPos);
            row.add(glyph);

            glyphPos.x += glyph.width;
		}

        if (members.indexOf(row) == -1) add(row);

		glyphPos.put();
	}

    @:noCompletion
    override function set_color(value:Int):Int {
        for (row in members) row.color = value;
        return super.set_color(value);
    }
}

private class AlphabetRow extends FlxTypedSpriteGroup<AlphabetGlyph> {
    @:noCompletion
    override function set_color(value:Int):Int {
        for (letter in members) letter.color = value;
        return super.set_color(value);
    }
}

///////////////////////////////////////////
// ALPHABET LETTERS, SYMBOLS AND NUMBERS //
///////////////////////////////////////////

typedef Glyph = {
	var anim:Null<String>;
	var offsets:Array<Float>;
	var offsetsBold:Array<Float>;
}

class AlphabetGlyph extends FlxSprite {
	public var image(default, set):String;
	public static var allGlyphs:Map<String, Glyph>;

	var parent:Alphabet;
	public var spawnPos:FlxPoint = FlxPoint.get();
	public var letterOffset:Array<Float> = [0, 0];

	public var row:Int = 0;
	public var character:String = '?';
	public function new() {
		super();
		image = 'alphabet';
		antialiasing = Settings.data.antialiasing;
	}
	
	public var curGlyph:Glyph = null;
	public function setup(x:Float, y:Float, ?character:String, ?type:AlphabetGlyphType):AlphabetGlyph {
		setPosition(x, y);

		if (parent != null) {
			if (type == null) type = parent.type;
			scale.set(parent.scaleX, parent.scaleY);
		}
		
		if (character != null) {
			this.character = character;

			var converted:String = character.toLowerCase();
			final isLowerCase:Bool = converted == character;
			var suffix:String = ' ';

			curGlyph = allGlyphs.get(allGlyphs.exists(converted) ? converted : '?');

			if (type == NORMAL) {
				if (isLetter(converted)) suffix += isLowerCase ? 'lowercase' : 'uppercase';
				else suffix += 'normal';
			} else suffix += 'bold';

			converted = '${curGlyph.anim}$suffix';
			animation.addByPrefix(converted, converted, 24);
			animation.play(converted);
		}
		updateHitbox();

		return this;
	}

	public static function isLetter(c:String) { // thanks kade
		var ascii:Int = StringTools.fastCodeAt(c, 0);
		return (ascii >= 65 && ascii <= 90)
			|| (ascii >= 97 && ascii <= 122)
			|| (ascii >= 192 && ascii <= 214)
			|| (ascii >= 216 && ascii <= 246)
			|| (ascii >= 248 && ascii <= 255);
	}

	function set_image(name:String) {
		if (frames == null) {
			image = name;
			frames = Paths.getSparrowAtlas(name);
			return name;
		}

		var lastAnim:String = null;
		if (animation != null) lastAnim = animation.name;

		frames = Paths.getSparrowAtlas(image = name);
		scale.set(parent.scaleX, parent.scaleY);
		
		if (lastAnim != null) {
			animation.addByPrefix(lastAnim, lastAnim, 24);
			animation.play(lastAnim, true);
			
			updateHitbox();
		}
		return name;
	}

	public function updateLetterOffset() {
		if (animation.curAnim == null) return;

		var add:Float = 110;
		if (animation.curAnim.name.endsWith('bold')) {
			if (curGlyph.offsetsBold != null) letterOffset = curGlyph.offsetsBold;
			add = 70;
		} else if (curGlyph.offsets != null) {
			letterOffset = curGlyph.offsets;
		}

		add *= scale.y;
		offset.x += letterOffset[0] * scale.x;
		offset.y += letterOffset[1] * scale.y - (add - height);
	}

	override public function updateHitbox() {
		super.updateHitbox();
		updateLetterOffset();
	}
}