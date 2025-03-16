package backend;

@:structInit
class MetaFile {
	public var songName:String = 'Unknown';
	public var composer:String = 'Unknown';
	public var charter:Map<String, String> = [];
	public var timingPoints:Array<Conductor.TimingPoint> = [];
	public var offset:Float = 0.0;
	public var hasVocals:Bool = true;

	public var player:String = 'bf';
	public var spectator:String = 'bf';
	public var enemy:String = 'bf';
	public var stage:String = 'stage';
}

typedef MetaTimingPoint = {
	var time:Float;
	var ?bpm:Float;
	var ?beatsPerMeasure:Int;
}

class Meta {
	public static function load(song:String):MetaFile {
		var path:String = Paths.get('songs/$song/meta.json');
		var file:MetaFile = {};

		if (!FileSystem.exists(path)) return file;
		var data = Json.parse(File.getContent(path));

		for (property in Reflect.fields(data)) {
			if (!Reflect.hasField(file, property)) continue;
			if (property == 'charter' || property == 'timingPoints') continue;

			Reflect.setField(file, property, Reflect.field(data, property));
		}

		for (diff in Reflect.fields(data.charter)) file.charter.set(diff, Reflect.field(data.charter, diff));

		// have to do it this way
		// otherwise haxe shits itself and starts printing insane numbers
		// and that's no good /ref
		var timingPoints:Array<MetaTimingPoint> = data.timingPoints;
		for (point in timingPoints) {
			file.timingPoints.push({
				time: point.time,
				bpm: point.bpm,
				beatsPerMeasure: point.beatsPerMeasure
			});
		}

		return file;
	}
}