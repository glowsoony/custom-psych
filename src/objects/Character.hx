package objects;

typedef CharacterFile = {
	var antialiasing:Bool;
	var flipX:Bool;
	var icon:String;
	var scale:Array<Float>;
	var singDuration:Float;
	var healthColor:Int;
	var sheets:String;
	var cameraOffset:Array<Float>;

	var animations:Array<CharacterAnim>;
}

typedef CharacterAnim = {
	var name:String;
	var id:String;
	var indices:Array<Int>;
	var framerate:Int;
	var looped:Bool;
	var offsets:Array<Float>;
}

class Character extends FunkinSprite {
	public static final default_name:String = 'bf';
	public var name:String = default_name;
	public var singDuration:Float = 4;
	public var healthColor:Int = 0xFFA1A1A1;
	public var sheets:String;
	public var icon:String = '';
	public var cameraOffset:FlxPoint = FlxPoint.get(0, 0);

	var _file:CharacterFile;

	public function new(?x:Float, ?y:Float, ?name:String, ?player:Bool = true) {
		name ??= default_name;
		super(x, y);

		var path:String = Paths.get('characters/$name.json');
		if (!FileSystem.exists(path)) name = default_name;
		path = Paths.get('characters/$name.json');

		_file = getFile(path);

		this.name = name;
		this.singDuration = _file.singDuration;
		this.healthColor = _file.healthColor;
		this.sheets = _file.sheets;
		this.icon = _file.icon;
		this.cameraOffset.set(_file.cameraOffset[0], _file.cameraOffset[1]);
		flipX = (_file.flipX != player);

		scale.set(_file.scale[0], _file.scale[1]);
		updateHitbox();

		frames = Paths.sparrowAtlas(sheets);
		for (anim in _file.animations) {
			if (anim.indices.length == 0) {
				animation.addByPrefix(anim.name, anim.id, anim.framerate, anim.looped);
			} else {
				animation.addByIndices(anim.name, anim.id, anim.indices, '', anim.framerate, anim.looped);
			}

			offsetMap.set(anim.name, anim.offsets);
		}

		if (animation.exists('danceLeft') || animation.exists('danceRight')) {
			danceList = ['danceLeft', 'danceRight'];
		}

		dance(true);
	}

	public var dancing(get, never):Bool;
	function get_dancing():Bool {
		return animation.curAnim != null && animation.curAnim.name == danceList[animIndex];
	}

	var _idleTimer:Float = 0.0;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if (animation.curAnim == null) return;
		if (!dancing) {
			_idleTimer -= elapsed * (singDuration * (Conductor.stepCrotchet * 0.25));
			if (_idleTimer <= 0.0) dance(true);
		}
	}

	var animIndex:Int = 0;
	var danceList:Array<String> = ['idle'];
	public function dance(?forced:Bool = false) {
		if (!forced && (animation.curAnim == null || !animation.curAnim.finished)) return;

		playAnim(danceList[animIndex]);
		animIndex = FlxMath.wrap(animIndex + 1, 0, danceList.length - 1);
	}

	override function playAnim(name:String, ?forced:Bool = true) {
		super.playAnim(name, forced);
		if (name.startsWith('sing') || name.startsWith('miss')) {
			_idleTimer = singDuration * (Conductor.stepCrotchet * 0.15);
		}
	}

	static function createDummyFile():CharacterFile {
		return {
			antialiasing: true,
			flipX: false,
			icon: 'face',
			scale: [1, 1],
			singDuration: 4,
			healthColor: 0xFFA1A1A1,
			sheets: 'characters/bf',
			cameraOffset: [0, 0],

			animations: [{
				name: 'idle',
				id: 'anim',
				indices: [],
				framerate: 24,
				looped: false,
				offsets: [0, 0]
			}],
		}
	}

	static function getFile(path:String):CharacterFile {
		var file:CharacterFile = createDummyFile();
		if (!FileSystem.exists(path)) return file;
		
		var data = Json5.parse(File.getContent(path));
		for (property in Reflect.fields(data)) {
			if (!Reflect.hasField(file, property)) continue;
			Reflect.setField(file, property, Reflect.field(data, property));
		}

		return file;
	}
}