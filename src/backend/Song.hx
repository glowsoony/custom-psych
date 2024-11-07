package backend;

import haxe.Json;
import lime.utils.Assets;

typedef Chart = {
	var song:String;
	var notes:Array<Section>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;
	@:optional var offset:Float;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
}

typedef Section = {
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Null<Float>;
	var changeBPM:Null<Bool>;
	var altAnim:Bool;
}

class Song {
	public var song:String;
	public var notes:Array<Section>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	static function convert(songJson:Dynamic):Chart { // Convert old charts to newest format
		if (songJson.gfVersion == null) {
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if (songJson.events == null) {
			songJson.events = [];
			for (secNum in 0...songJson.notes.length) {
				var sec:Section = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while (i < len) {
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0) {
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					} else i++;
				}
			}
		}

		return songJson;
	}

	public function new(song:Chart) {
		for (field in Reflect.fields(song)) {
			if (!Reflect.hasField(this, field)) continue;
			Reflect.setField(this, field, Reflect.field(song, field));
		}
	}

	public static function load(path:String):Chart {
		var rawJson:String = Paths.getFileContent(path).trim();
		while (!rawJson.endsWith("}")) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var songJson:Chart = cast Json.parse(rawJson).song;
		return convert(songJson);
	}
}