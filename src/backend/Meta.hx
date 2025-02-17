package backend;

// credits to neo for helping me cuz i had timing point issues
// he also made the macro :thumbs:
@:build(backend.macros.ClassJson.build())
class MetaFile {
	public var songName:String = 'Unknown';
	public var composer:String = 'Unknown';
	public var charter:Map<String, String> = [];
	@:dyn public var timingPoints:Array<Conductor.TimingPoint> = [];
	public var offset:Float = 0.0;
	public var hasVocals:Bool = true;

	public var player:String = 'bf';
	public var spectator:String = 'bf';
	public var enemy:String = 'bf';
	public var stage:String = 'stage';

	function new() {}

	public static function createDummy():MetaFile {
		return new MetaFile();
	}
}

class Meta {
	public static function load(song:String):MetaFile {
		var path:String = Paths.get('songs/$song/meta.json');

		if (!FileSystem.exists(path)) return MetaFile.createDummy();

		var dyn = Json.parse(File.getContent(path));
		var file:MetaFile = MetaFile.fromJson(dyn);

/*		trace("Time points: " + file.timingPoints.length);
		for (i=>point in file.timingPoints) {
			trace(i);
			trace(" - Time: " + point.time);
			trace(" - BPM: " + point.bpm);
			trace(" - beats per measure: " + point.beatsPerMeasure);
		}*/

		return file;
	}
}