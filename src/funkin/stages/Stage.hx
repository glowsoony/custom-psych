package funkin.stages;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.media.Sound;
import funkin.backend.EventHandler.Event;

typedef StageFile = {
	var ?directory:String;
	var ?zoom:Float;
	var ?cameraSpeed:Float;
	var ?isSpectatorVisible:Bool;

	var ?playerPos:Array<Float>;
	var ?spectatorPos:Array<Float>;
	var ?opponentPos:Array<Float>;

	var ?playerCameraOffset:Array<Float>;
	var ?spectatorCameraOffset:Array<Float>;
	var ?opponentCameraOffset:Array<Float>;
}

// this is meant to be used in playstate
// so trying to use this anywhere else might break it
class Stage {
	var _file:StageFile;
	var game:PlayState = PlayState.self;

	public var player:FlxPoint = FlxPoint.get(0, 0);
	public var spectator:FlxPoint = FlxPoint.get(0, 0);
	public var opponent:FlxPoint = FlxPoint.get(0, 0);

	public var playerCamOffset:FlxPoint = FlxPoint.get(0, 0);
	public var spectatorCamOffset:FlxPoint = FlxPoint.get(0, 0);
	public var opponentCamOffset:FlxPoint = FlxPoint.get(0, 0);

	public var directory:String = '';
	public var zoom:Float = 1;
	public var cameraSpeed:Float = 1;
	public var isSpectatorVisible:Bool = true;

	public function new(name:String) {
		_file = getFile('stages/$name.json');

		player.set(_file.playerPos[0], _file.playerPos[1]);
		spectator.set(_file.spectatorPos[0], _file.spectatorPos[1]);
		opponent.set(_file.opponentPos[0], _file.opponentPos[1]);

		playerCamOffset.set(_file.playerCameraOffset[0], _file.playerCameraOffset[1]);
		spectatorCamOffset.set(_file.spectatorCameraOffset[0], _file.spectatorCameraOffset[1]);
		opponentCamOffset.set(_file.opponentCameraOffset[0], _file.opponentCameraOffset[1]);

		directory = _file.directory;
		zoom = _file.zoom;
		cameraSpeed = _file.cameraSpeed;
		isSpectatorVisible = _file.isSpectatorVisible;
	}

	public function add(obj:FlxBasic):FlxBasic {
		if (game == null) {
			warn('PlayState is not initiated.');
			return null;
		}

		game.add(obj);
		return obj;
	}

	public function remove(obj:FlxBasic):FlxBasic {
		if (game == null) {
			warn('PlayState is not initiated.');
			return null;
		}

		game.remove(obj);
		return obj;
	}

	public function insert(obj:FlxBasic, ?position:Int = -1):FlxBasic {
		if (game == null) {
			warn('PlayState is not initiated.');
			return null;
		}

		if (position == -1) position = game.members.length;
		game.insert(position, obj);
		return obj;
	}

	function addBehindObject(obj:FlxBasic, target:FlxBasic) {
		if (game == null) {
			warn('PlayState is not initiated.');
			return null;
		}

		return insert(obj, game.members.indexOf(target));
	}

	// functions copy pasted from Paths.hx
	// to support stage directories
	// like `assets/week2/...` `assets/week4/...` etc
	final function image(key:String, ?subFolder:String = 'images'):FlxGraphic {
		subFolder = redirectSubFolder(subFolder);
		return Paths.image(key, subFolder);
	}

	final function audio(key:String, ?subFolder:String, ?beepIfNull:Bool = true):Sound {
		subFolder = redirectSubFolder(subFolder);
		return Paths.audio(key, subFolder, beepIfNull);
	}

	final function music(key:String, ?subFolder:String = 'music', ?beepIfNull:Bool = true) {
		return audio(key, subFolder, beepIfNull);
	}

	final function sound(key:String, ?subFolder:String = 'sounds', ?beepIfNull:Bool = true) {
		return audio(key, subFolder, beepIfNull);
	}

	final function sparrowAtlas(path:String, ?subFolder:String = 'images'):FlxFramesCollection {
		subFolder = redirectSubFolder(subFolder);

		final dataFile:String = Paths.get('$path.xml', subFolder);
		if (!FileSystem.exists(dataFile)) return null;

		return FlxAtlasFrames.fromSparrow(Paths.image(path, subFolder), File.getContent(dataFile));
	}

	final function packerAtlas(path:String, ?subFolder:String = 'images'):FlxFramesCollection {
		subFolder = redirectSubFolder(subFolder);

		final dataFile:String = Paths.get('$path.txt', subFolder);
		if (!FileSystem.exists(dataFile)) return null;

		return FlxAtlasFrames.fromSpriteSheetPacker(Paths.image(path, subFolder), File.getContent(dataFile));
	}

	final function asepriteAtlas(path:String, ?subFolder:String = 'images'):FlxFramesCollection {
		subFolder = redirectSubFolder(subFolder);

		final dataFile:String = Paths.get('$path.json', subFolder);
		if (!FileSystem.exists(dataFile)) return null;

		return FlxAtlasFrames.fromTexturePackerJson(Paths.image(path, subFolder), File.getContent(dataFile));
	}

	final function redirectSubFolder(subFolder:String):String {
		if (directory == null && directory.length == 0) return subFolder;
		if (subFolder == null || subFolder.length == 0) return directory;
		
		return '$directory/$subFolder';
	}

	public function create():Void {}
	public function update(elapsed:Float):Void {}
	public function destroy():Void {}

	public function stepHit(step:Int):Void {}
	public function beatHit(beat:Int):Void {}
	public function measureHit(measure:Int):Void {}

	public function eventPushed(event:Event):Void {}
	public function eventPushedUnique(event:Event):Void {}
	public function eventTriggered(event:Event):Void {}

	public static function getFile(path:String):StageFile {
		var file:StageFile = createDummyFile();
		if (!Paths.exists(path)) return file;
		
		var data = Json5.parse(Paths.getFileContent(path));
		for (property in Reflect.fields(data)) {
			if (!Reflect.hasField(file, property)) continue;
			Reflect.setField(file, property, Reflect.field(data, property));
		}

		return file;
	}

	public static function createDummyFile():StageFile {
		return {
			directory: '',
			zoom: 1,
			cameraSpeed: 1,
			isSpectatorVisible: true,

			playerPos: [900, 100],
			spectatorPos: [530, -50],
			opponentPos: [200, 100],

			playerCameraOffset: [0, 0],
			spectatorCameraOffset: [0, 0],
			opponentCameraOffset: [0, 0]
		}
	}
}